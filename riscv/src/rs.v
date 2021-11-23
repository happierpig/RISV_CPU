`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module rs (
    input clk,input rst,input rdy,
    // from fetcher to decide whether to store the input
    input in_fetcher_ce,

    // for fetcher to decide whether to fetch new instruction
    output out_fetcher_isidle,

    // from decode to store entry, use rob_tag == `ZERO_TAG_ROB to decide whether to store
    input [`ROB_TAG_WIDTH] in_decode_rob_tag,
    input [`INSIDE_OPCODE_WIDTH] in_decode_op,
    input [`DATA_WIDTH] in_decode_value1,
    input [`DATA_WIDTH] in_decode_value2,
    input [`DATA_WIDTH] in_decode_imm,
    input [`ROB_TAG_WIDTH] in_decode_tag1, 
    input [`ROB_TAG_WIDTH] in_decode_tag2,
    input [`DATA_WIDTH] in_decode_pc,

    // from alu_cdb to update source value
    input [`DATA_WIDTH] in_alu_cdb_value,
    input [`ROB_TAG_WIDTH] in_alu_cdb_tag, // use this == `ZERO_TAG_ROB to check legality

    // from lsb_cdb to update source value 
    input [`ROB_TAG_WIDTH] in_lsb_cdb_tag, // use this == `ZERO_TAG_ROB to check legality
    input [`DATA_WIDTH] in_lsb_cdb_value,
    input in_lsb_ioin,

    // from rob_cdb to update source value 
    input [`ROB_TAG_WIDTH] in_rob_cdb_tag,
    input [`DATA_WIDTH] in_rob_cdb_value,
 
    // for alu to calculate
    output reg [`INSIDE_OPCODE_WIDTH] out_alu_op, // `NOP means no operations
    output reg [`DATA_WIDTH] out_alu_value1,
    output reg [`DATA_WIDTH] out_alu_value2,
    output reg [`DATA_WIDTH] out_alu_imm,
    output reg [`ROB_TAG_WIDTH] out_alu_rob_tag,
    output reg [`DATA_WIDTH] out_alu_pc,

    // from rob to denote misbranch
    input in_rob_misbranch
);
    // Information storage
    reg busy[(`RS_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] tags[(`RS_SIZE-1):0];
    reg [`INSIDE_OPCODE_WIDTH] op[(`RS_SIZE-1):0];
    reg [`DATA_WIDTH] value1[(`RS_SIZE-1):0];
    reg [`DATA_WIDTH] value2[(`RS_SIZE-1):0];
    reg [`DATA_WIDTH] imms [(`RS_SIZE-1):0];
    reg [`DATA_WIDTH] pcs [(`RS_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] value1_tag[(`RS_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] value2_tag[(`RS_SIZE-1):0];

    // data structure
    wire [`RS_TAG_WIDTH] free_tag;
    wire [`RS_TAG_WIDTH] issue_tag;
    wire ready [(`RS_SIZE-1):0];

    // Combinatorial logic
    assign out_fetcher_isidle = (free_tag != `ZERO_TAG_RS);
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
            assign ready[j] = (busy[j] == `TRUE) && (value1_tag[j]==`ZERO_TAG_ROB) && (value2_tag[j]==`ZERO_TAG_ROB);
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

    integer i;
    always@(posedge clk) begin 
        if(rst == `TRUE) begin 
            out_alu_op <= `NOP;
            for(i = 0;i < `RS_SIZE;i=i+1) begin 
                busy[i] <= `FALSE;
                op[i] <= `NOP;
            end
        end else if(rdy == `TRUE) begin 
            out_alu_op <= `NOP;
            // try to issue entry to ALU
            if(in_rob_misbranch == `TRUE) begin 
                for(i = 1;i < `RS_SIZE;i=i+1) begin 
                    busy[i] <= `FALSE;
                    tags[i] <= `ZERO_TAG_ROB;
                end
            end else begin 
                if(issue_tag != `ZERO_TAG_RS) begin 
                    out_alu_op <= op[issue_tag];
                    out_alu_value1 <= value1[issue_tag];
                    out_alu_value2 <= value2[issue_tag];
                    out_alu_imm <= imms[issue_tag];
                    out_alu_rob_tag <= tags[issue_tag];
                    out_alu_pc <= pcs[issue_tag];
                    busy[issue_tag] <= `FALSE;
                end
                //try to store new entry into rs
                if(in_fetcher_ce == `TRUE && in_decode_rob_tag != `ZERO_TAG_ROB && in_decode_op != `NOP) begin 
                    busy[free_tag] <= `TRUE;
                    tags[free_tag] <= in_decode_rob_tag;
                    op[free_tag] <= in_decode_op;
                    value1[free_tag] <= in_decode_value1;
                    value2[free_tag] <= in_decode_value2;
                    imms[free_tag] <= in_decode_imm;
                    value1_tag[free_tag] <= in_decode_tag1;
                    value2_tag[free_tag] <= in_decode_tag2;
                    pcs[free_tag] <= in_decode_pc;
                    // Store when CDB broadcast
                    if(in_alu_cdb_tag != `ZERO_TAG_ROB) begin 
                        if(in_decode_tag1 == in_alu_cdb_tag) begin 
                            value1[free_tag] <= in_alu_cdb_value;
                            value1_tag[free_tag] <= `ZERO_TAG_ROB;
                        end
                        if(in_decode_tag2 == in_alu_cdb_tag) begin 
                            value2[free_tag] <= in_alu_cdb_value;
                            value2_tag[free_tag] <= `ZERO_TAG_ROB;
                        end
                    end
                    if(in_lsb_cdb_tag != `ZERO_TAG_ROB && in_lsb_ioin == `FALSE) begin 
                        if(in_decode_tag1 == in_lsb_cdb_tag) begin 
                            value1[free_tag] <= in_lsb_cdb_value;
                            value1_tag[free_tag] <= `ZERO_TAG_ROB;
                        end
                        if(in_decode_tag2 == in_lsb_cdb_tag) begin 
                            value2[free_tag] <= in_lsb_cdb_value;
                            value2_tag[free_tag] <= `ZERO_TAG_ROB;
                        end
                    end
                end
                // monitor CDB
                for(i = 1;i < `RS_SIZE;i=i+1) begin 
                    if(busy[i] == `TRUE) begin 
                        if(in_alu_cdb_tag != `ZERO_TAG_ROB) begin  
                            if(value1_tag[i] == in_alu_cdb_tag) begin 
                                value1[i] <= in_alu_cdb_value;
                                value1_tag[i] <= `ZERO_TAG_ROB;
                            end
                            if(value2_tag[i] == in_alu_cdb_tag) begin 
                                value2[i] <= in_alu_cdb_value;
                                value2_tag[i] <= `ZERO_TAG_ROB;
                            end
                        end
                        if(in_rob_cdb_tag != `ZERO_TAG_ROB) begin  
                            if(value1_tag[i] == in_rob_cdb_tag) begin 
                                value1[i] <= in_rob_cdb_value;
                                value1_tag[i] <= `ZERO_TAG_ROB;
                            end
                            if(value2_tag[i] == in_rob_cdb_tag) begin 
                                value2[i] <= in_rob_cdb_value;
                                value2_tag[i] <= `ZERO_TAG_ROB;
                            end
                        end
                        if(in_lsb_cdb_tag != `ZERO_TAG_ROB && in_lsb_ioin == `FALSE) begin 
                            if(value1_tag[i] == in_lsb_cdb_tag) begin 
                                value1[i] <= in_lsb_cdb_value;
                                value1_tag[i] <= `ZERO_TAG_ROB;
                            end
                            if(value2_tag[i] == in_lsb_cdb_tag) begin 
                                value2[i] <= in_lsb_cdb_value;
                                value2_tag[i] <= `ZERO_TAG_ROB;
                            end
                        end
                    end
                end
            end
        end
    end                                
endmodule
