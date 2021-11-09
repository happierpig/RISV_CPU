`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"
`define debug
module lsb(
    input clk,input rst,input rdy,

    // From fetcher to decide whether to fetch new instruction
    input in_fetcher_ce, 

    // for fetcher to decide whether to fetch new instructions
    output out_fetcher_isidle,

    // from decode to store entry ,use rob_tag == `ZERO_TAG_ROB to decide whether store it in
    input [`ROB_TAG_WIDTH] in_decode_rob_tag,
    input [`INSIDE_OPCODE_WIDTH] in_decode_op,
    input [`DATA_WIDTH] in_decode_value1,
    input [`DATA_WIDTH] in_decode_value2,
    input [`DATA_WIDTH] in_decode_imm,
    input [`ROB_TAG_WIDTH] in_decode_tag1, 
    input [`ROB_TAG_WIDTH] in_decode_tag2,

    //output to ROB to check whether it can be issue to memory
    output [`DATA_WIDTH] out_rob_now_addr,
    input in_rob_check, // true for existence of memory address collison and false for none

    //from alu_cdb to update source value 
    input [`ROB_TAG_WIDTH] in_alu_cdb_tag,
    input [`DATA_WIDTH] in_alu_cdb_value,

    // to memory control 
    output reg out_mem_ce,
    output reg [5:0] out_mem_size,
    output reg out_mem_signed,  // 0 for unsigned;1 for signed
    output reg [`DATA_WIDTH] out_mem_address,

    // from memory control 
    input in_mem_ce,
    input [`DATA_WIDTH] in_mem_data,

    // CDB to ROB/RS
    output reg [`ROB_TAG_WIDTH] out_rob_tag, // Zero means Not to do anything
    output reg [`DATA_WIDTH] out_destination, // for store 
    output reg [`DATA_WIDTH] out_value,

    // from ROB to denote that misbranch
    input in_rob_misbranch
);
    // Load  寄存器目的地已知，缺地址(x[rs1] + imm) 和 value(from memory)
    // Store 缺目的地(Memory_address: x[rs1] + imm) 和 value(x[rs2])

    // Data structure 
    localparam IDLE = 1'b0,WAIT_MEM = 1'b1;
    reg status; // 0 means idle ; 1 means waiting for memory
    reg busy[(`LSB_SIZE-1):0];
    reg [`LSB_TAG_WIDTH] head;
    reg [`LSB_TAG_WIDTH] tail;
    reg [`ROB_TAG_WIDTH] tags [(`LSB_SIZE-1):0];
    reg [`INSIDE_OPCODE_WIDTH] op [(`LSB_SIZE-1):0];
    reg [`DATA_WIDTH] address [(`LSB_SIZE-1):0];
    reg  address_ready [(`LSB_SIZE-1):0];
    reg [`DATA_WIDTH] imms [(`LSB_SIZE-1):0];
    reg [`DATA_WIDTH] value1 [(`LSB_SIZE-1):0];
    reg [`DATA_WIDTH] value2 [(`LSB_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] value1_tag [(`LSB_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] value2_tag [(`LSB_SIZE-1):0];
    wire ready_to_calculate_addr [(`LSB_SIZE-1):0];
    wire [`LSB_TAG_WIDTH] calculate_tag;
    wire ready_to_issue [(`LSB_SIZE-1):0];
    wire [`LSB_TAG_WIDTH] nextPtr;
    wire [`LSB_TAG_WIDTH] nowPtr;

    // Combinatorial logic
    assign nextPtr = tail % (`LSB_SIZE-1) + 1; // 1 - 15 
    assign nowPtr = head % (`LSB_SIZE-1) + 1;
    assign out_fetcher_isidle = (nextPtr != head);
    assign out_rob_now_addr = address[nowPtr];

    genvar i;
    generate
        for(i = 1;i < `LSB_SIZE;i=i+1) begin :BlockA
            assign ready_to_issue[i] = (busy[i] == `TRUE) && (value2_tag[i] == `ZERO_TAG_ROB) && (address_ready[i] == `TRUE);
            assign ready_to_calculate_addr[i] = (busy[i] == `TRUE) && (value1_tag[i] == `ZERO_TAG_ROB) && (address_ready[i] == `FALSE);
        end
    endgenerate

    assign calculate_tag = ready_to_calculate_addr[1] ? 1 : 
                        ready_to_calculate_addr[2] ? 2 : 
                            ready_to_calculate_addr[3] ? 3 :
                                ready_to_calculate_addr[4] ? 4 :
                                    ready_to_calculate_addr[5] ? 5 :
                                        ready_to_calculate_addr[6] ? 6 :
                                            ready_to_calculate_addr[7] ? 7 : 
                                                ready_to_calculate_addr[8] ? 8 : 
                                                    ready_to_calculate_addr[9] ? 9 :
                                                        ready_to_calculate_addr[10] ? 10 :
                                                            ready_to_calculate_addr[11] ? 11 :
                                                                ready_to_calculate_addr[12] ? 12 :
                                                                    ready_to_calculate_addr[13] ? 13 :
                                                                        ready_to_calculate_addr[14] ? 14 :
                                                                            ready_to_calculate_addr[15] ? 15 : `ZERO_TAG_LSB;

    // Temporal logic
    integer j;
    always @(posedge clk) begin 
        if(rst == `TRUE) begin 
            status <= IDLE; 
            head <= 1; tail <= 1;
            out_rob_tag <= `ZERO_TAG_ROB;
            out_mem_ce <= `FALSE;
            for(j = 0;j < `LSB_SIZE;j=j+1) begin 
                busy[j] <= `FALSE;
                address_ready[j] <= `FALSE;
                value1_tag[j] <= `ZERO_TAG_ROB;
                value2_tag[j] <= `ZERO_TAG_ROB;
                address[j] <= `ZERO_DATA;
            end
        end else if(rdy == `TRUE && in_rob_misbranch == `FALSE) begin
            // Try to issue S/L instruction to ROB:
            out_rob_tag <= `ZERO_TAG_ROB;
            out_mem_ce <= `FALSE;
            if(ready_to_issue[nowPtr] == `TRUE) begin 
                if(status == IDLE) begin 
                    case(op[nowPtr])
                        `SB,`SH,`SW: begin
                            status <= IDLE;
                            out_destination <= address[nowPtr];
                            out_value <= value2[nowPtr];
                            out_rob_tag <= tags[nowPtr];
                            busy[nowPtr] <= `FALSE;
                            address_ready[nowPtr] <= `FALSE;
                            head <= nowPtr;
                        end
                        `LB,`LBU: begin
                            if(in_rob_check == `FALSE) begin
                                status <= WAIT_MEM;
                                out_mem_signed <= (op[nowPtr] == `LB) ? 1 : 0; 
                                out_mem_ce <= `TRUE;
                                out_mem_size <= 1;
                                out_mem_address <= address[nowPtr];
                            end
                        end
                        `LH,`LHU: begin 
                            if(in_rob_check == `FALSE) begin
                                status <= WAIT_MEM;
                                out_mem_signed <= (op[nowPtr] == `LH) ? 1 : 0;
                                out_mem_ce <= `TRUE;
                                out_mem_size <= 2;
                                out_mem_address <= address[nowPtr];
                            end
                        end
                        `LW: begin
                            if(in_rob_check == `FALSE) begin
                                status <= WAIT_MEM;
                                out_mem_ce <= `TRUE;
                                out_mem_size <= 4;
                                out_mem_address <= address[nowPtr];
                            end
                        end
                    endcase
                end else if(status == WAIT_MEM) begin
                    if(in_mem_ce == `TRUE) begin 
                        // CDB to rs/rob
                        out_rob_tag <= tags[nowPtr];
                        out_value <= in_mem_data;
                        // Broadcast to itself
                        for(j = 0;j < `LSB_SIZE;j=j+1) begin
                            if(busy[j] == `TRUE) begin 
                                if(value1_tag[j] == tags[nowPtr]) begin 
                                    value1[j] <= in_mem_data;
                                    value1_tag[j] <= `ZERO_TAG_ROB;
                                end 
                                if(value2_tag[j] == tags[nowPtr]) begin 
                                    value2[j] <= in_mem_data;
                                    value2_tag[j] <= `ZERO_TAG_ROB;
                                end
                            end
                        end
                        // cancle it in lsb
                        status <= IDLE;
                        busy[nowPtr] <= `FALSE;
                        address_ready[nowPtr] <= `FALSE;
                        head <= nowPtr;
                    end
                end
            end 
            // Calculate effective address per cycle
            if(calculate_tag != `ZERO_TAG_LSB) begin 
                address[calculate_tag] <= value1[calculate_tag] + imms[calculate_tag];
                address_ready[calculate_tag] <= `TRUE;
            end
            // Store new entry into LSB
            if(in_fetcher_ce == `TRUE && in_decode_rob_tag != `ZERO_TAG_ROB) begin
                `ifdef debug 
                    $display($time," [LSB] New Entry ,rob_tag : ",in_decode_rob_tag," opcode: ",in_decode_op);
                `endif
                busy[nextPtr] <= `TRUE;
                tail <= nextPtr;
                tags[nextPtr] <= in_decode_rob_tag;
                op[nextPtr] <= in_decode_op;
                address_ready[nextPtr] <= `FALSE;
                imms[nextPtr] <= in_decode_imm;
                value1[nextPtr] <= in_decode_value1;
                value2[nextPtr] <= in_decode_value2;
                value1_tag[nextPtr] <= in_decode_tag1;
                value2_tag[nextPtr] <= in_decode_tag2;
            end 
            // Monitor ALU CDB
            if(in_alu_cdb_tag != `ZERO_TAG_ROB) begin 
                for(j = 1;j < `LSB_SIZE;j=j+1) begin 
                    if(busy[j] == `TRUE) begin 
                        if(value1_tag[j] == in_alu_cdb_tag) begin 
                            value1[j] <= in_alu_cdb_value;
                            value1_tag[j] <= `ZERO_TAG_ROB;
                        end 
                        if(value2_tag[j] == in_alu_cdb_tag) begin 
                            value2[j] <= in_alu_cdb_value;
                            value2_tag[j] <= `ZERO_TAG_ROB;
                        end
                    end
                end
            end
        end else if(rdy == `TRUE && in_rob_misbranch == `TRUE) begin 
            out_rob_tag <= `ZERO_TAG_ROB;
            out_mem_ce <= `FALSE;
            status <= IDLE;
            head <= 1;tail <=1;
            for(j = 1;j < `LSB_SIZE;j=j+1) begin 
                busy[j] <= `FALSE;
                tags[j] <= `ZERO_TAG_ROB;
                address_ready[j] <= `FALSE;
            end
        end
    end
endmodule