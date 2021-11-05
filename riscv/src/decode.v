`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module decode (
    input clk,input rst,input rdy,

    // From Fetcher
    input [`DATA_WIDTH] in_fetcher_instr,

    // ask register for source operand status
    output [`REG_TAG_WIDTH] out_reg_tag1,
    input [`DATA_WIDTH] in_reg_value1,
    input [`ROB_TAG_WIDTH] in_reg_robtag1,
    input in_reg_busy1,

    output [`REG_TAG_WIDTH] out_reg_tag2,
    input [`DATA_WIDTH] in_reg_value2,
    input [`ROB_TAG_WIDTH] in_reg_robtag2,
    input in_reg_busy2,

    // Get free rob entry tag
    input [`ROB_TAG_WIDTH] in_rob_freetag,

    // ask rob for source operand value
    output [`ROB_TAG_WIDTH] out_rob_fetch_tag1,
    input [`DATA_WIDTH] in_rob_fetch_value1,
    input in_rob_fetch_ready1,
    output [`ROB_TAG_WIDTH] out_rob_fetch_tag2,
    input [`DATA_WIDTH] in_rob_fetch_value2,
    input in_rob_fetch_ready2,

    // ask rob to store entry
    output reg [`REG_TAG_WIDTH] out_rob_destination,
    output reg [`INSIDE_OPCODE_WIDTH] out_rob_op,

    // ask rs to store entry
    output reg [`ROB_TAG_WIDTH] out_rs_rob_tag,
    output reg [`INSIDE_OPCODE_WIDTH] out_rs_op,
    output reg [`DATA_WIDTH] out_rs_value1,
    output reg [`DATA_WIDTH] out_rs_value2,
    output reg [`ROB_TAG_WIDTH] out_rs_tag1,
    output reg [`ROB_TAG_WIDTH] out_rs_tag2,
    output reg [`DATA_WIDTH] out_rs_imm,

    // ask lsb to store entry
    output reg out_lsb_isStore,
    output reg [`DATA_WIDTH] out_lsb_value1,
    output reg [`DATA_WIDTH] out_lsb_value2,
    output reg [`ROB_TAG_WIDTH] out_lsb_tag1,
    output reg [`ROB_TAG_WIDTH] out_lsb_tag2,
    output reg [`DATA_WIDTH] out_lsb_imm,
    output reg [`ROB_TAG_WIDTH] out_lsb_rob_tag
);
    // control units
    wire [6:0] opcode;
    wire [4:0]  rd;
    wire [2:0] funct3; 
    wire [6:0] funct7;
    parameter LUI = 7'b0110111,AUIPC = 7'b0010111,JAL = 7'b1101111,JALR = 7'b1100111,
    B_TYPE = 7'b1100011,LI_TYPE = 7'b0000011,S_TYPE = 7'b0100011,AI_TYPE = 7'b0010011,R_TYPE = 7'b0110011;
    
    assign opcode = in_fetcher_instr[`OPCODE_WIDTH];
    assign funct3 = in_fetcher_instr[14:12];
    assign funct7 = in_fetcher_instr[31:25];
    assign rd = in_fetcher_instr[11:7];
    assign out_reg_tag1 = in_fetcher_instr[19:15];
    assign out_reg_tag2 = in_fetcher_instr[24:20];
    assign out_rob_fetch_tag1 = in_reg_robtag1;
    assign out_rob_fetch_tag2 = in_reg_robtag2;

    // Combinatorial logic
    function [`DATA_WIDTH] get_imm;
        input [`DATA_WIDTH] instr;
        begin
            get_imm = `ZERO_DATA;
            case (instr[`OPCODE_WIDTH])
                LUI,AUIPC:              get_imm = {instr[31:12],12'b0};
                JAL:                    get_imm = {{12{instr[31]}},instr[19:12],instr[20],instr[30:25],instr[24:21], 1'b0};
                B_TYPE:                 get_imm = {{20{instr[31]}},instr[7],instr[30:25],instr[11:8], 1'b0};
                S_TYPE:                 get_imm = {{21{instr[31]}},instr[30:25],instr[11:7]};
                JALR,LI_TYPE:           get_imm = {{21{instr[31]}},instr[30:20]};
                AI_TYPE:   
                    begin 
                        if(instr[`FUNCT3_WIDTH] == 3'b001 || instr[`FUNCT3_WIDTH] == 3'b101) begin
                            get_imm = {26'b0,instr[25:20]};
                        end else begin
                            get_imm = {{21{instr[31]}},instr[30:20]};
                        end
                    end
                default: get_imm = `ZERO_DATA;
            endcase
        end
    endfunction
    always @(*) begin
        out_rob_destination = `ZERO_TAG_REG;
        out_rob_op = `NOP;
        out_rs_rob_tag = `ZERO_TAG_ROB;
        out_rs_op = `NOP;
        out_rs_value1 = `ZERO_DATA;
        out_rs_value2 = `ZERO_DATA;
        out_rs_tag1 = `ZERO_TAG_ROB;
        out_rs_tag2 = `ZERO_TAG_ROB;
        out_rs_imm = `ZERO_DATA;
        out_lsb_isStore = `FALSE;
        out_lsb_value1 = `ZERO_DATA;
        out_lsb_value2  = `ZERO_DATA;
        out_lsb_tag1 = `ZERO_TAG_ROB;
        out_lsb_tag2 = `ZERO_TAG_ROB;
        out_lsb_imm = `ZERO_DATA;
        out_lsb_rob_tag = `ZERO_TAG_ROB;
        if(rst == `FALSE && rdy == `TRUE) begin 
            case (opcode)
                LUI:begin
                  out_rs_rob_tag = in_rob_freetag;
                  out_rs_op = `LUI;
                  out_rs_imm = {instr[31:12],12'b0};
                  out_rob_op = `LUI;
                  out_rob_destination = rd;
                end
                AUIPC:begin  // todo : add pc
                  out_rs_rob_tag = in_rob_freetag;
                  out_rs_op = `AUIPC;
                  out_rs_imm = {instr[31:12],12'b0};
                  out_rob_op = `AUIPC;
                  out_rob_destination = rd;
                end
            endcase
        end
    end
    endmodule