`include "constant.v"

module decode (
    input clk,input rst,input rdy,

    // For Fetcher
    input [`DATA_WIDTH] in_instr,

    //For Registers. Output should be Reg type.
    output [`REG_TAG_WIDTH] out_reg_tag1,input [`DATA_WIDTH] in_reg_value1,input [`ROB_TAG_WIDTH] in_reg_robtag1,input in_reg_busy1,
    output [`REG_TAG_WIDTH] out_reg_tag2,input [`DATA_WIDTH] in_reg_value2,input [`ROB_TAG_WIDTH] in_reg_robtag2,input in_reg_busy2,

    //For LSB

    //For RS

    //For ROB
);

    
endmodule