`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module rob(
    input clk,input rst,input rdy,

    // asked by decode about idle tag
    output out_decode_idle_tag,

    // asked by decode to store entry
    input [`DATA_WIDTH] in_decode_destination, // distinguish register index with memory address
    input [`INSIDE_OPCODE_WIDTH] in_decode_op,

    // asked by decode for register value
    input [`ROB_TAG_WIDTH] in_decode_fetch_tag1,
    output [`DATA_WIDTH] out_decode_fetch_value1,
    output out_decode_fetch_ready1,
    input [`ROB_TAG_WIDTH] in_decode_fetch_tag2,
    output [`DATA_WIDTH] out_decode_fetch_value2,
    output out_decode_fetch_ready2,

    //for fetcher to decide whether to fetch new instruction
    output out_fetcher_isidle,

    // from fetcher to decide whether to store the entry
    input in_fetcher_ce,

    // from alu_cdb
    input [`DATA_WIDTH] in_alu_cdb_value,
    input [`DATA_WIDTH] in_alu_cdb_newpc,
    input [`ROB_TAG_WIDTH] in_alu_cdb_tag, // `ZERO_TAG_ROB means no data comes in

    // from lsb_cdb
    input [`DATA_WIDTH] in_lsb_cdb_tag,
    input [`DATA_WIDTH] in_lsb_cdb_value,
    input [`DATA_WIDTH] in_lsb_cdb_destination,

    // asked by lsb whether exists address collision
    input [`DATA_WIDTH] in_lsb_now_addr,
    output out_lsb_check,

    // commit : to register
    output reg[`REG_TAG_WIDTH] out_reg_index, // zero means there is no data
    output reg[`ROB_TAG_WIDTH] out_reg_rob_tag,
    output reg[`DATA_WIDTH] out_reg_value,

    // commit : to memory 
    output reg out_mem_ce,
    output reg [5:0] out_mem_size,
    output reg [`DATA_WIDTH] out_mem_address,
    output reg [`DATA_WIDTH] out_mem_data,
    input in_mem_ce
);
    // information storage
    reg [`DATA_WIDTH] value [(`ROB_SIZE-1):0];
    reg [`DATA_WIDTH] destination [(`ROB_SIZE-1):0]; // Registers index is low bits of that
    reg ready [(`ROB_SIZE-1):0];
    reg [`INSIDE_OPCODE_WIDTH] op [(`ROB_SIZE-1):0];
    reg [`DATA_WIDTH] newpc [(`ROB_SIZE-1):0];
    reg isStore[(`ROB_SIZE-1):0]; // When committed,this tag is canceled. 

    // Data Structure; 1-15 and 0 is symbol for non
    reg [`ROB_TAG_WIDTH] head;
    reg [`ROB_TAG_WIDTH] tail;
    wire [`ROB_TAG_WIDTH] nextPtr;
    wire [`ROB_TAG_WIDTH] nowPtr;
    reg status; // 0 means idle and 1 means waiting for memory.

    // Combinatorial logic
    assign nextPtr = tail % (`ROB_SIZE-1)+1;
    assign nowPtr = head % (`ROB_SIZE-1)+1;
    assign out_decode_idle_tag = (nextPtr == head) ? `ZERO_TAG_ROB : nextPtr;
    assign out_fetcher_isidle = (nextPtr != head); 
    assign out_decode_fetch_value1 = value[in_decode_fetch_tag1];
    assign out_decode_fetch_ready1 = ready[in_decode_fetch_tag1];
    assign out_decode_fetch_value2 = value[in_decode_fetch_tag2];
    assign out_decode_fetch_ready2 = ready[in_decode_fetch_tag2];
    assign out_lsb_check = (isStore[1] && in_lsb_now_addr == destination[1])
                            || (isStore[2] && in_lsb_now_addr == destination[2])
                                || (isStore[3] && in_lsb_now_addr == destination[3])
                                    || (isStore[4] && in_lsb_now_addr == destination[4])
                                        || (isStore[5] && in_lsb_now_addr == destination[5])
                                            || (isStore[6] && in_lsb_now_addr == destination[6])
                                                || (isStore[7] && in_lsb_now_addr == destination[7])
                                                    || (isStore[8] && in_lsb_now_addr == destination[8])
                                                        || (isStore[9] && in_lsb_now_addr == destination[9])
                                                            || (isStore[10] && in_lsb_now_addr == destination[10])
                                                                || (isStore[11] && in_lsb_now_addr == destination[11])
                                                                    || (isStore[12] && in_lsb_now_addr == destination[12])
                                                                        || (isStore[13] && in_lsb_now_addr == destination[13])
                                                                            || (isStore[14] && in_lsb_now_addr == destination[14])
                                                                                || (isStore[15] && in_lsb_now_addr == destination[15]);

    // Temporal logic
    integer i;
    always @(posedge clk) begin
        if(rst == `TRUE) begin 
            head <= 1; tail <= 1;
            out_reg_index <= `ZERO_TAG_REG;
            out_mem_ce <= `FALSE;
            for(i = 0;i < `ROB_SIZE;i=i+1) begin 
                ready[i] <= `FALSE;
                value[i] <= `ZERO_DATA;
                op[i] <= `NOP;
                isStore[i] <= `FALSE;
            end
        end else if(rdy == `TRUE) begin
            out_reg_index <= `ZERO_TAG_REG;
            out_mem_ce <= `FALSE;
            // store entry from decoder
            if(in_fetcher_ce == `TRUE) begin    
                destination[nextPtr] <= in_decode_destination;
                op[nextPtr] <= in_decode_op;
                case(in_decode_op) 
                    `SB,`SH,`SW:begin isStore[nextPtr] <= `TRUE; end
                    default:begin isStore[nextPtr] <= `FALSE; end
                endcase
                ready[nextPtr] <= `FALSE;
                tail <= nextPtr;
            end
            // monitor alu cdb
            if(in_alu_cdb_tag != `ZERO_TAG_ROB) begin
                value[in_alu_cdb_tag] <= in_alu_cdb_value;
                newpc[in_alu_cdb_tag] <= in_alu_cdb_newpc;
                ready[in_alu_cdb_tag] <= `TRUE;
            end
            // monitor lsb cdb  
            if(in_lsb_cdb_tag != `ZERO_TAG_ROB) begin
                ready[in_lsb_cdb_tag] <= `TRUE;
                value[in_lsb_cdb_tag] <= in_lsb_cdb_value;
                if(isStore[in_lsb_cdb_tag]) begin 
                    destination[in_lsb_cdb_tag] <= in_lsb_cdb_destination;
                end
            end
            // try to commit head entry
            if(ready[nowPtr] == `TRUE) begin
                if(status == 0) begin 
                    case(op[nowPtr])
                        `NOP: begin end
                        `JAL: begin end
                        `JALR: begin end
                        `BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU: begin end
                        `SB: begin 
                            status <= 1;
                            out_mem_size <= 1;
                            out_mem_address <= destination[nowPtr];
                            out_mem_data <= value[nowPtr];
                        end
                        `SH: begin 
                            status <= 1;
                            out_mem_size <= 2;
                            out_mem_address <= destination[nowPtr];
                            out_mem_data <= value[nowPtr];
                        end
                        `SW: begin 
                            status <= 1;
                            out_mem_size <= 4;
                            out_mem_address <= destination[nowPtr];
                            out_mem_data <= value[nowPtr];
                        end
                        default:begin 
                            status <= 0;
                            out_reg_index <= destination[nowPtr][`REG_TAG_WIDTH];
                            out_reg_rob_tag <= nowPtr;
                            out_reg_value <= value[nowPtr];
                            isStore[nowPtr] <= `FALSE;
                            head <= nowPtr;
                        end
                    endcase
                end else if(status == 1) begin 
                    if(in_mem_ce == `TRUE) begin 
                        status <= 0;
                        isStore[nowPtr] <= `FALSE;
                        head <= nowPtr;
                    end
                end
            end
        end
    end
endmodule