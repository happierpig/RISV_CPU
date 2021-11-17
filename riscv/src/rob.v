`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"
module rob(
    input clk,input rst,input rdy,

    // asked by decode about idle tag
    output [`ROB_TAG_WIDTH] out_decode_idle_tag,

    // asked by decode to store entry
    input [`DATA_WIDTH] in_decode_destination, // distinguish register index with memory address
    input [`INSIDE_OPCODE_WIDTH] in_decode_op,
    input [`DATA_WIDTH] in_decode_pc,
    input in_decode_jump_ce,

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
    input [`ROB_TAG_WIDTH] in_lsb_cdb_tag,
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
    input in_mem_ce,

    // output denote misbranch  
    output reg out_misbranch,
    output reg [`DATA_WIDTH] out_newpc,

    //output to BP to modify
    output reg out_bp_ce,
    output reg [`BP_TAG_WIDTH] out_bp_tag,
    output reg out_bp_jump_ce
);
    // information storage
    reg [`DATA_WIDTH] value [(`ROB_SIZE-1):0];
    reg [`DATA_WIDTH] destination [(`ROB_SIZE-1):0]; // Registers index is low bits of that
    reg ready [(`ROB_SIZE-1):0];
    reg [`INSIDE_OPCODE_WIDTH] op [(`ROB_SIZE-1):0];
    reg [`DATA_WIDTH] newpc [(`ROB_SIZE-1):0];
    reg isStore[(`ROB_SIZE-1):0]; // When committed,this tag is canceled. 

    // BP 
    reg [`DATA_WIDTH] pcs [(`ROB_SIZE-1):0];
    reg predictions [(`ROB_SIZE-1):0];

    // Data Structure; 1-15 and 0 is symbol for non
    reg [`ROB_TAG_WIDTH] head;
    reg [`ROB_TAG_WIDTH] tail;
    wire [`ROB_TAG_WIDTH] nextPtr;
    wire [`ROB_TAG_WIDTH] nowPtr;
    reg status; // 0 means idle and 1 means waiting for memory.
    localparam IDLE = 0,WAIT_MEM = 1;

    // Combinatorial logic
    assign nextPtr = tail % (`ROB_SIZE-1)+1;
    assign nowPtr = head % (`ROB_SIZE-1)+1;
    assign out_decode_idle_tag = (nextPtr == head) ? `ZERO_TAG_ROB : nextPtr;
    assign out_fetcher_isidle = (nextPtr != head) && ((nextPtr % (`ROB_SIZE-1)+1) != head); 
    // assign out_fetcher_isidle = (nextPtr != head);
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
            status <= IDLE;
            out_misbranch <= `FALSE;
            out_newpc <= `ZERO_DATA;
            out_bp_ce <= `FALSE;
            for(i = 0;i < `ROB_SIZE;i=i+1) begin 
                ready[i] <= `FALSE;
                value[i] <= `ZERO_DATA;
                op[i] <= `NOP;
                isStore[i] <= `FALSE;
            end
        end else if(rdy == `TRUE && out_misbranch == `FALSE) begin
            out_reg_index <= `ZERO_TAG_REG;
            out_mem_ce <= `FALSE;
            out_bp_ce <= `FALSE;
            // store entry from decoder
            if(in_fetcher_ce == `TRUE && in_decode_op != `NOP) begin    
                `ifdef debug
                    $display($time," [ROB]New entry into rob ,tag: ",nextPtr," opcode: ",in_decode_op );
                `endif
                pcs[nextPtr] <= in_decode_pc;
                predictions[nextPtr] <= in_decode_jump_ce;
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
            if(ready[nowPtr] == `TRUE && head != tail) begin
                if(status == IDLE) begin 
                    `ifdef debug   
                        $display($time," [ROB]Start commiting instruction tag: ",nowPtr," opcode: %b",op[nowPtr]," PC : %h",pcs[nowPtr]);
                    `endif
                    case(op[nowPtr])
                        `NOP: begin end
                        `JALR: begin 
                            `ifdef debug
                                $display($time," [ROB] JALR,rob_tag: ",nowPtr," opcode: %b",op[nowPtr], " newpc: %h",newpc[nowPtr]);
                            `endif
                            out_reg_index <= destination[nowPtr][`REG_TAG_WIDTH];
                            out_reg_rob_tag <= nowPtr;
                            out_reg_value <= value[nowPtr];
                            out_misbranch <= `TRUE;
                            out_newpc <= newpc[nowPtr];
                        end
                        `BEQ,`BNE,`BLT,`BGE,`BLTU,`BGEU: begin 
                            out_bp_ce <= `TRUE; 
                            out_bp_jump_ce <= (value[nowPtr] == `JUMP_ENABLE) ? `TRUE : `FALSE;
                            out_bp_tag <= pcs[nowPtr][`BP_HASH_WIDTH];
                            status <= IDLE;
                            isStore[nowPtr] <= `FALSE;
                            head <= nowPtr;
                            if(value[nowPtr] == `JUMP_ENABLE && predictions[nowPtr] == `FALSE) begin 
                                `ifdef debug
                                   $display($time," [ROB] Misbranch should Jump,rob_tag: ",nowPtr," opcode: %b",op[nowPtr], " newpc: %h",newpc[nowPtr]);
                                `endif
                                out_misbranch <= `TRUE;
                                out_newpc <= newpc[nowPtr];
                            end
                            if(value[nowPtr] == `JUMP_DISABLE && predictions[nowPtr] == `TRUE) begin 
                                `ifdef debug
                                   $display($time," [ROB] Misbranch rob_tag: ",nowPtr," opcode: %b",op[nowPtr], " newpc: %h",newpc[nowPtr]);
                                `endif
                                out_misbranch <= `TRUE;
                                out_newpc <= pcs[nowPtr] + 4;
                            end
                        end
                        `SB: begin
                            status <= WAIT_MEM;
                            out_mem_size <= 1;
                            out_mem_address <= destination[nowPtr];
                            out_mem_data <= value[nowPtr];
                            out_mem_ce <= `TRUE;
                        end
                        `SH: begin 
                            status <= WAIT_MEM;
                            out_mem_size <= 2;
                            out_mem_address <= destination[nowPtr];
                            out_mem_data <= value[nowPtr];
                            out_mem_ce <= `TRUE;
                        end
                        `SW: begin 
                            status <= WAIT_MEM;
                            out_mem_size <= 4;
                            out_mem_address <= destination[nowPtr];
                            out_mem_data <= value[nowPtr];
                            out_mem_ce <= `TRUE;
                        end

                        //registers operation | load | JAL
                        default:begin 
                            status <= IDLE;
                            out_reg_index <= destination[nowPtr][`REG_TAG_WIDTH];
                            out_reg_rob_tag <= nowPtr;
                            out_reg_value <= value[nowPtr];
                            isStore[nowPtr] <= `FALSE;
                            head <= nowPtr;
                        end
                    endcase
                end else if(status == WAIT_MEM) begin 
                    if(in_mem_ce == `TRUE) begin
                        status <= IDLE;
                        isStore[nowPtr] <= `FALSE;
                        head <= nowPtr;
                        `ifdef debug
                            $display($time," [ROB] Finish storing memory, rob tag is ",nowPtr," and the value is ",value[nowPtr]);
                        `endif
                    end
                end
            end
        end else if(rdy == `TRUE && out_misbranch == `TRUE) begin 
            out_misbranch <= `FALSE;
            head <= 1;tail <= 1;
            out_reg_index <= `ZERO_TAG_REG;
            out_mem_ce <= `FALSE;
            status <= IDLE;
            for(i = 0;i < `ROB_SIZE;i=i+1) begin 
                ready[i] <= `FALSE;
                value[i] <= `ZERO_DATA;
                isStore[i] <= `FALSE;
            end
        end
    end
endmodule