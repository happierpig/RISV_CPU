`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"
`define debug
module registers (
    input clk,input rst,input rdy,

    // from fetcher to decide whether to update the destination's busy tag 
    input in_fetcher_ce,

    // Decoder asks for Value/ROB-Tag/Busy of two operands. ps: read-only
    input [`REG_TAG_WIDTH] in_decode_reg_tag1,
    output [`DATA_WIDTH] out_decode_value1,
    output [`ROB_TAG_WIDTH] out_decode_rob_tag1,
    output out_decode_busy1,
    input [`REG_TAG_WIDTH] in_decode_reg_tag2,
    output [`DATA_WIDTH] out_decode_value2,
    output [`ROB_TAG_WIDTH] out_decode_rob_tag2,
    output out_decode_busy2,

    // Decoder sets destination register's rob-tag. ps:write
    input [`REG_TAG_WIDTH] in_decode_destination_reg,
    input [`ROB_TAG_WIDTH] in_decode_destination_rob,

    // ROB commit modify registers. ps:write
    input [`REG_TAG_WIDTH] in_rob_commit_reg, // zero will not affect anything.
    input [`ROB_TAG_WIDTH] in_rob_commit_rob,
    input [`DATA_WIDTH] in_rob_commit_value,

    // from rob to denote misbranch
    input in_rob_misbranch
);
    // data structure
    reg [`DATA_WIDTH] values [(`REG_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] tags [(`REG_SIZE-1):0];
    reg busy [(`REG_SIZE-1):0];

    // Combinatorial logic
    assign out_decode_value1 = values[in_decode_reg_tag1];
    assign out_decode_rob_tag1 = tags[in_decode_reg_tag1];
    assign out_decode_busy1 = busy[in_decode_reg_tag1];
    assign out_decode_value2 = values[in_decode_reg_tag2];
    assign out_decode_rob_tag2 = tags[in_decode_reg_tag2];
    assign out_decode_busy2 = busy[in_decode_reg_tag2];
    
    // Temporal logic
    genvar i;
    generate
        for(i=0;i<`REG_SIZE;i=i+1) begin:initReg
            always @(posedge clk) begin
                if(rst == `TRUE) begin
                    values[i] <= `ZERO_DATA;
                    busy[i] <= `FALSE;
                    tags[i] <= `ZERO_TAG_ROB;
                end
            end
        end
    endgenerate

    genvar k;
    generate
        for(k=1;k<`REG_SIZE;k=k+1) begin:ROBWriteReg // make sure that Reg[0] will not be modified.
            always @(posedge clk) begin
                if(rst == `FALSE && rdy == `TRUE) begin
                    if(in_rob_commit_reg == k) begin
                        values[k] <= in_rob_commit_value;
                        `ifdef debug
                            $display($time,"Reg ",k," 's value is set to ",in_rob_commit_value," by ",in_rob_commit_rob);
                        `endif
                        if(in_rob_commit_rob == tags[k]) begin
                            `ifdef debug
                                $display($time,"Reg ",k," 's busy tag is false by ",in_rob_commit_rob);
                            `endif
                            busy[k] <= `FALSE;
                        end
                    end
                    if(in_fetcher_ce == `TRUE && in_decode_destination_reg == k) begin
                        `ifdef debug
                            $display($time,"Reg ",k," 's busy tag is true,and destination is ",in_decode_destination_rob);
                        `endif
                        busy[k] <= `TRUE;
                        tags[k] <= in_decode_destination_rob;
                    end
                    if(in_rob_misbranch == `TRUE) begin 
                        busy[k] <= `FALSE;
                        tags[k] <= `ZERO_TAG_ROB;
                    end
                end
            end
        end
    endgenerate
endmodule