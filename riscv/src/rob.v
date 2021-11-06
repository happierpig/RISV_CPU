`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module rob(
    input clk,input rst,input rdy,

    // asked by decode about idle tag
    output out_decode_idle_tag,

    // asked by decode to store entry
    input [`DATA_WIDTH] in_decode_destination, // distinguish register index with memory address
    input [`INSIDE_OPCODE_WIDTH] in_decode_op,
    input in_decode_ready,
    input [`DATA_WIDTH] in_decode_value,

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

    // from cdb
    input [`DATA_WIDTH] in_alu_cdb_value,
    input [`ROB_TAG_WIDTH] in_alu_cdb_tag, // `ZERO_TAG_ROB means no data comes in

    // commit : to register / to memory
    output reg[`REG_TAG_WIDTH] out_reg_index,
    output reg[`ROB_TAG_WIDTH] out_reg_rob_tag,
    output reg[`DATA_WIDTH] out_reg_value
);
    // information storage
    reg [`DATA_WIDTH] value [(`ROB_SIZE-1):0];
    reg [`DATA_WIDTH] destination [(`ROB_SIZE-1):0]; // Registers index is low bits of that
    reg ready [(`ROB_SIZE-1):0];
    reg [`INSIDE_OPCODE_WIDTH] op [(`ROB_SIZE-1):0];

    // Data Structure; 1-15 and 0 is symbol for non
    reg [`ROB_TAG_WIDTH] head;
    reg [`ROB_TAG_WIDTH] tail;
    wire [`ROB_TAG_WIDTH] nextPtr;

    // Combinatorial logic
    assign nextPtr = tail % (`ROB_SIZE-1)+1;
    assign out_decode_idle_tag = (nextPtr == head) ? `ZERO_TAG_ROB : nextPtr;
    assign out_fetcher_isidle = (nextPtr != head); 
    assign out_decode_fetch_value1 = value[in_decode_fetch_tag1];
    assign out_decode_fetch_ready1 = ready[in_decode_fetch_tag1];
    assign out_decode_fetch_value2 = value[in_decode_fetch_tag2];
    assign out_decode_fetch_ready2 = ready[in_decode_fetch_tag2];

    // Temporal logic
    integer i;
    always @(posedge clk) begin
        if(rst == `TRUE) begin 
            head <= 1;
            tail <= 1;
            for(i = 0;i < `ROB_SIZE;i=i+1) begin 
                ready[i] <= `FALSE;
                value[i] <= `ZERO_DATA;
                op[i] <= `NOP;
            end
        end else if(rdy == `TRUE) begin 
            // store entry from decoder
            if(in_fetcher_ce == `TRUE) begin    
                destination[nextPtr] <= in_decode_destination;
                op[nextPtr] <= in_decode_op;
                ready[nextPtr] <= in_decode_ready;
                value[nextPtr] <= in_decode_value;
                tail <= nextPtr;
            end
            // monitor alu cdb
            if(in_alu_cdb_tag != `ZERO_TAG_ROB) begin
                value[in_alu_cdb_tag] <= in_alu_cdb_value;
                ready[in_alu_cdb_tag] <= `TRUE;
            end
            if(ready[head] == `TRUE) begin 
                //todo :for register/memory/store
            end
        end
    end
endmodule