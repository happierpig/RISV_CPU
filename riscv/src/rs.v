`include "constant.v"

module rs (
    input clk,input rst,input rdy,
    // for fetcher
    input in_fetcher_ce,
    output out_fetcher_isidle,
    // from decode
    input [`ROB_TAG_WIDTH] in_decode_rob_tag,
    input [`INSIDE_OPCODE_WIDTH] in_decode_op,
    input [`DATA_WIDTH] in_decode_value1,
    input [`DATA_WIDTH] in_decode_value2,
    input [`ROB_TAG_WIDTH] in_decode_tag1, 
    input [`ROB_TAG_WIDTH] in_decode_tag2,
    // from cdb
    input [`DATA_WIDTH] in_cdb_value,
    input [`ROB_TAG_WIDTH] in_cdb_tag,
    // for alu
    output reg [`INSIDE_OPCODE_WIDTH] out_alu_op,
    output reg [`DATA_WIDTH] out_alu_value1,
    output reg [`DATA_WIDTH] out_alu_value2,
    output reg [`ROB_TAG_WIDTH] out_alu_rob_tag
);
    // Information storage
    reg busy[(`RS_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] tags[(`RS_SIZE-1):0];
    reg [`INSIDE_OPCODE_WIDTH] op[(`RS_SIZE-1):0];
    reg [`DATA_WIDTH] value1[(`RS_SIZE-1):0];
    reg [`DATA_WIDTH] value2[(`RS_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] value1_tag[(`RS_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] value2_tag[(`RS_SIZE-1):0];
    

    // data structure
    wire [`RS_TAG_WIDTH] free_tag;
    wire [`RS_TAG_WIDTH] issue_tag;
    wire ready[(`RS_SIZE-1):0];
    // Combinatorial logic
    assign out_fetcher_isidle = free_tag || `FALSE;
    // priority encoder learned from XOR-op(github.com/XOR-op/TransistorU)
    assign free_tag = ~busy[1] ? 1 :
                        ~busy[2] ? 2 : 
                            ~busy[3] ? 3 :
                                ~busy[4] ? 4 :
                                    ~busy[5] ? 5 : 
                                        ~busy[6] ? 6 :
                                            ~busy[7] ? 7 :
                                                ~busy[8] ? 8 : 
                                                    ~busy[9] ? 9 :
                                                        ~busy[10] ? 10 :
                                                            ~busy[11] ? 11 :
                                                                ~busy[12] ? 12 :
                                                                    ~busy[13] ? 13 :
                                                                        ~busy[14] ? 14 : 
                                                                            ~busy[15] ? 15 : `ZERO_TAG_RS;

    genvar j;
    generate
        for(j = 1;j < `RS_SIZE;j=j+1) begin:issueCheck 
            assign ready[j] = (busy[j]) && (value1_tag[j]==`ZERO_TAG_ROB) && (value2_tag[j]==`ZERO_TAG_ROB);
        end
    endgenerate
    assign issue_tag = ready[1] ? 1 : 
                        ready[2] ? 2 : 
                            ready[3] ? 3 :
                                ready[4] ? 4 :
                                    ready[5] ? 5 :
                                        ready[6] ? 6 :
                                            ready[7] ? 7 : 
                                                ready[8] ? 8 : 
                                                    ready[9] ? 9 :
                                                        ready[10] ? 10 :
                                                            ready[11] ? 11 :
                                                                ready[12] ? 12 :
                                                                    ready[13] ? 13 :
                                                                        ready[14] ? 14 :
                                                                            ready[15] ? 15 : `ZERO_TAG_RS;
    // Temporal logic
    genvar i;
    generate
        for(i = 0;i < `RS_SIZE;i=i+1) begin:reset
            always@(posedge clk) begin
                if(rst == `TRUE) begin    //reset
                    busy[i] <= `FALSE;
                    tags[i] <= `ZERO_TAG_ROB;
                    ready[i] <= `FALSE;
                end else if(rdy == `TRUE) begin 
                    if(busy[i] == `TRUE) begin  // monitor CDB
                        if(value1_tag[i] != `ZERO_TAG_ROB && value1_tag[i] == in_cdb_tag) begin
                            value1_tag[i] <= `ZERO_TAG_ROB;
                            value1[i] <= in_cdb_value;
                        end
                        if(value2_tag[i] != `ZERO_TAG_ROB && value2_tag[i] == in_cdb_tag) begin
                            value2_tag[i] <= `ZERO_TAG_ROB;
                            value2[i] <= in_cdb_value;
                        end
                    end
                end
            end
        end
    endgenerate

    always@(posedge clk) begin
        if(rst == `FALSE && rdy == `TRUE) begin 
            if(in_fetcher_ce == `TRUE) begin // add entry from Decoder
                tags[free_tag] <= in_decode_rob_tag;
                op[free_tag] <= in_decode_op;
                value1[free_tag] <= in_decode_value1;
                value2[free_tag] <= in_decode_value2;
                value1_tag[free_tag] <= in_decode_tag1;
                value2_tag[free_tag] <= in_decode_tag2;
                busy[free_tag] <= `TRUE;
            end
            if(issue_tag != `ZERO_TAG_RS) begin //issue to ALU
                out_alu_op <= op[issue_tag];
                out_alu_rob_tag <= tags[issue_tag];
                out_alu_value1 <= value1[issue_tag];
                out_alu_value2 <= value2[issue_tag];
            end
        end
    end                                                      
endmodule
