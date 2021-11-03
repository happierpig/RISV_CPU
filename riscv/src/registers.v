`include "constant.v"

module registers (
    input clk,input rst,input rdy,

    // Decoder asks for Value/ROB-Tag/Busy of two operands. ps: read-only
    input [`REG_TAG_WIDTH] in_decode_reg_tag1,output [`DATA_WIDTH] out_decode_value1,output [`ROB_TAG_WIDTH] out_decode_rob_tag1,output out_decode_busy1,
    input [`REG_TAG_WIDTH] in_decode_reg_tag2,output [`DATA_WIDTH] out_decode_value2,output [`ROB_TAG_WIDTH] out_decode_rob_tag2,output out_decode_busy2,
    // Decoder sets destination register's rob-tag. ps:write
    input [`REG_TAG_WIDTH] in_decode_destination_reg,input [`ROB_TAG_WIDTH] in_decode_destination_rob,
    // ROB commit modify registers. ps:write
    input [`REG_TAG_WIDTH] in_rob_commit_reg,input [`ROB_TAG_WIDTH] in_rob_commit_rob,input [`DATA_WIDTH] in_rob_commit_value
);
    reg [`DATA_WIDTH] values [(`REG_SIZE-1):0];
    reg [`ROB_TAG_WIDTH] tags [(`REG_SIZE-1):0];
    reg busy [(`REG_SIZE-1):0];
    // Combinatorial logic
    assign out_decode_value1 = values[in_decode_reg_tag1];assign out_decode_rob_tag1 = tags[in_decode_reg_tag1];assign out_decode_busy1 = busy[in_decode_reg_tag1];
    assign out_decode_value2 = values[in_decode_reg_tag2];assign out_decode_rob_tag2 = tags[in_decode_reg_tag2];assign out_decode_busy2 = busy[in_decode_reg_tag2];
    
    genvar i;
    generate
        for(i=0;i<`REG_SIZE;i=i+1) begin:initReg
            always @(posedge clk) begin
                if(rst == `TRUE) begin
                    values[i] <= `ZERO_DATA;
                    busy[i] <= `FALSE;
                end
            end
        end
    endgenerate

    genvar j;
    generate
        for(j=1;j<`REG_SIZE;j=j+1) begin:decodeWriteReg // make sure that Reg[0] will not be modified.
            always @(*) begin
                if(rst == `FALSE && rdy == `TRUE) begin
                    if(in_decode_destination_reg == j) begin
                        tags[j] = in_decode_destination_rob;
                        busy[j] = `TRUE;
                    end
                end
            end
        end
    endgenerate

    genvar k;
    generate
        for(k=1;k<`REG_SIZE;k=k+1) begin:ROBWriteReg // make sure that Reg[0] will not be modified.
            always @(*) begin
                if(rst == `FALSE && rdy == `TRUE) begin
                    if(in_rob_commit_reg == k) begin
                        values[k] = in_rob_commit_value;
                        if(in_rob_commit_rob == tags[k]) begin
                            busy[k] = `FALSE;
                        end
                    end
                end
            end
        end
    endgenerate
endmodule