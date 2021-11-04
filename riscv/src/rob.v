`include "constant.v"
module rob(
    input clk,input rst,input rdy,
    // for decode
    output out_decode_idle_tag,input [`DATA_WIDTH] in_decode_destination,input [`INSIDE_OPCODE_WIDTH] in_decode_op,
    input [`ROB_TAG_WIDTH] in_decode_fetch_tag1,output [`DATA_WIDTH] out_decode_fetch_value1,output out_decode_fetch_ready1,
    input [`ROB_TAG_WIDTH] in_decode_fetch_tag2,output [`DATA_WIDTH] out_decode_fetch_value2,output out_decode_fetch_ready2,
    //for fetcher
    output out_fetcher_isidle,input in_fetcher_ce,
    // from cdb
    input [`DATA_WIDTH] in_cdb_value,input [`ROB_TAG_WIDTH] in_cdb_tag,
    // commit : to register / to memory
    output reg[`REG_TAG_WIDTH] out_reg_index,output reg[`ROB_TAG_WIDTH] out_reg_robtag,output reg[`DATA_WIDTH] out_reg_value
);
    // information storage
    reg [`DATA_WIDTH] value [(`ROB_SIZE-1):0];
    reg [`DATA_WIDTH] destination [(`ROB_SIZE-1):0]; // Registers index is low bits of that
    reg ready [(`ROB_SIZE-1):0];
    reg [`INSIDE_OPCODE_WIDTH] op [(`ROB_SIZE-1):0];
    // Data Structure; use 4'b1111 as ZERO_TAG_ROB
    reg [`ROB_TAG_WIDTH] head;
    reg [`ROB_TAG_WIDTH] tail;
    wire [`ROB_TAG_WIDTH] nextPtr;

    // Combinatorial logic
    assign nextPtr = (tail+1)%(`ROB_SIZE-1);
    assign out_decode_idle_tag = (nextPtr == head) ? `ZERO_TAG_ROB : nextPtr;
    assign out_fetcher_isidle = (nextPtr != head); 
    assign out_decode_fetch_value1 = value[in_decode_fetch_tag1];assign out_decode_fetch_ready1 = ready[in_decode_fetch_tag1];
    assign out_decode_fetch_value2 = value[in_decode_fetch_tag2];assign out_decode_fetch_ready2 = ready[in_decode_fetch_tag2];

    // Temporal logic
    always @(posedge clk) begin
        if(rst == `FALSE && rdy == `TRUE) begin 
            if(in_fetcher_ce == `TRUE) begin    // place entry from decoder
                destination[nextPtr] <= in_decode_destination;
                op[nextPtr] <= in_decode_op;
                ready[nextPtr] <= `FALSE;
                tail <= nextPtr;
            end
            if(in_cdb_tag != `ZERO_TAG_ROB) begin  // monitor cdb
                value[in_cdb_tag] <= in_cdb_value;
                ready[in_cdb_tag] <= `TRUE;
            end
            if(ready[head] == `TRUE) begin 
                //todo :for register/memory/store
            end
        end
    end
endmodule