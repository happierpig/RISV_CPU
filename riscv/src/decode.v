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

    // ask registers to update value type
    output reg [`REG_TAG_WIDTH] out_reg_destination,  //use this == zero to check whether it is send to register
    output [`ROB_TAG_WIDTH] out_reg_rob_tag,

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
    output reg [`DATA_WIDTH] out_rob_destination, // need to distinguish register name from memory address
    output reg [`INSIDE_OPCODE_WIDTH] out_rob_op,
    output reg out_rob_isready, // use to LUI/AUIPC/
    output reg [`DATA_WIDTH] out_rob_value,

    // ask rs to store entry
    output reg [`ROB_TAG_WIDTH] out_rs_rob_tag, //use this == zero to check whether it is send to rs
    output reg [`INSIDE_OPCODE_WIDTH] out_rs_op,
    output [`DATA_WIDTH] out_rs_value1,
    output [`DATA_WIDTH] out_rs_value2,
    output [`ROB_TAG_WIDTH] out_rs_tag1,
    output [`ROB_TAG_WIDTH] out_rs_tag2,
    output reg [`DATA_WIDTH] out_rs_imm,

    // ask lsb to store entry
    output reg [`ROB_TAG_WIDTH] out_lsb_rob_tag, //use this == lsb to check whether it is send to lsb
    output reg [`INSIDE_OPCODE_WIDTH] out_lsb_op,
    output [`DATA_WIDTH] out_lsb_value1,
    output [`DATA_WIDTH] out_lsb_value2,
    output [`ROB_TAG_WIDTH] out_lsb_tag1,
    output [`ROB_TAG_WIDTH] out_lsb_tag2,
    output reg [`DATA_WIDTH] out_lsb_imm

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

    // Combinatorial logic
    assign out_reg_tag1 = in_fetcher_instr[19:15];
    assign out_reg_tag2 = in_fetcher_instr[24:20];
    assign out_rob_fetch_tag1 = in_reg_robtag1;
    assign out_rob_fetch_tag2 = in_reg_robtag2;
    assign out_reg_rob_tag = in_rob_freetag;

    wire [`DATA_WIDTH] value1; wire [`DATA_WIDTH] value2; wire[`ROB_TAG_WIDTH] tag1;wire [`ROB_TAG_WIDTH] tag2;
    assign value1 = (in_reg_busy1 == `FALSE) ? in_reg_value1 : (in_rob_fetch_ready1 == `TRUE) ? in_rob_fetch_value1 : `ZERO_DATA;
    assign tag1 = (in_reg_busy1 == `FALSE) ? `ZERO_TAG_ROB : (in_rob_fetch_ready1 == `TRUE) ? `ZERO_TAG_ROB : in_reg_robtag1;
    assign value2 = (in_reg_busy2 == `FALSE) ? in_reg_value2 : (in_rob_fetch_ready2 == `TRUE) ? in_rob_fetch_value2 : `ZERO_DATA;
    assign tag2 = (in_reg_busy2 == `FALSE) ? `ZERO_TAG_ROB : (in_rob_fetch_ready2 == `TRUE) ? `ZERO_TAG_ROB : in_reg_robtag2;
    assign out_rs_value1 = value1;assign out_rs_tag1 = tag1;
    assign out_rs_value2 = value2;assign out_rs_tag2 = tag2;
    assign out_lsb_value1 = value1;assign out_lsb_tag1 = tag1;
    assign out_lsb_value2 = value2;assign out_lsb_tag2 = tag2;

    always @(*) begin
        out_rob_destination = `ZERO_TAG_REG;
        out_rob_op = `NOP;
        out_rob_isready = `FALSE;
        out_rob_value = `ZERO_DATA;
        out_rs_rob_tag = `ZERO_TAG_ROB;
        out_rs_op = `NOP;
        out_rs_imm = `ZERO_DATA;
        out_lsb_op = `NOP;
        out_lsb_imm = `ZERO_DATA;
        out_lsb_rob_tag = `ZERO_TAG_ROB;
        out_reg_destination = `ZERO_TAG_REG;
        
        if(rst == `FALSE && rdy == `TRUE) begin 
            case (opcode)
                LUI:begin
                  out_rob_value = {in_fetcher_instr[31:12],12'b0};
                  out_rob_op = `LUI;
                  out_rob_destination = {27'b0,rd[4:0]};
                  out_rob_isready = `TRUE;
                  out_reg_destination = rd;
                end
                AUIPC:begin  // todo : add pc
                  out_rob_value = {in_fetcher_instr[31:12],12'b0};
                  out_rob_op = `AUIPC;
                  out_rob_destination = {27'b0,rd[4:0]};
                  out_rob_isready = `TRUE;
                  out_reg_destination = rd;
                end
                JAL:begin 
                    
                end
                JALR:begin 

                end
                B_TYPE:begin 
                    
                end
                LI_TYPE:begin 
                    out_rob_destination = {27'b0,rd[4:0]};
                    out_lsb_imm = {{21{in_fetcher_instr[31]}},in_fetcher_instr[30:20]};
                    out_lsb_rob_tag = in_rob_freetag;
                    out_reg_destination = rd;
                    case(funct3) 
                        3'b000:begin    out_lsb_op = `LB;     out_rob_op = `LB; end
                        3'b001:begin    out_lsb_op = `LH;     out_rob_op = `LH; end
                        3'b010:begin    out_lsb_op = `LW;     out_rob_op = `LW; end
                        3'b100:begin    out_lsb_op = `LBU;    out_rob_op = `LBU; end
                        3'b101:begin    out_lsb_op = `LHU;    out_rob_op = `LHU; end
                    endcase
                end
                S_TYPE:begin 
                    out_lsb_rob_tag = in_rob_freetag;
                    out_lsb_imm = {{21{in_fetcher_instr[31]}},in_fetcher_instr[30:25],in_fetcher_instr[11:7]};
                    case(funct3) 
                        3'b000:begin    out_lsb_op = `SB;    out_rob_op = `SB; end
                        3'b001:begin    out_lsb_op = `SH;    out_rob_op = `SH; end
                        3'b010:begin    out_lsb_op = `SW;    out_rob_op = `SW; end
                    endcase
                end
                AI_TYPE:begin 
                    out_rob_destination = {27'b0,rd[4:0]};
                    out_rs_rob_tag = in_rob_freetag;
                    out_rs_imm = {{21{in_fetcher_instr[31]}},in_fetcher_instr[30:20]};
                    out_reg_destination = rd;
                    case(funct3) 
                        3'b000:begin    out_rs_op = `ADDI;    out_rob_op = `ADDI; end
                        3'b010:begin    out_rs_op = `SLTI;    out_rob_op = `SLTI; end
                        3'b011:begin    out_rs_op = `SLTIU;   out_rob_op = `SLTIU; end
                        3'b100:begin    out_rs_op = `XORI;    out_rob_op = `XORI; end
                        3'b110:begin    out_rs_op = `ORI;     out_rob_op = `ORI; end
                        3'b111:begin    out_rs_op = `ANDI;    out_rob_op = `ANDI; end
                        3'b001:begin 
                            out_rs_op = `SLLI;
                            out_rob_op = `SLLI;
                            out_rs_imm = {26'b0,in_fetcher_instr[25:20]};
                        end
                        3'b101:begin 
                            out_rs_imm = {26'b0,in_fetcher_instr[25:20]};
                            case(funct7)
                                7'b0000000:begin out_rs_op = `SRLI; out_rob_op = `SRLI; end
                                7'b0100000:begin out_rs_op = `SRAI; out_rob_op = `SRAI; end
                            endcase
                        end
                    endcase
                end
                R_TYPE:begin 
                    out_rob_destination = {27'b0,rd[4:0]};
                    out_rs_rob_tag = in_rob_freetag;
                    out_reg_destination = rd;
                    case(funct3)
                        3'b000:begin 
                            case(funct7)
                                7'b0000000:begin out_rs_op = `ADD; out_rob_op = `ADD; end
                                7'b0100000:begin out_rs_op = `SUB; out_rob_op = `SUB; end
                            endcase
                        end
                        3'b001:begin out_rs_op = `SLL; out_rob_op = `SLL; end
                        3'b010:begin out_rs_op = `SLT; out_rob_op = `SLT; end
                        3'b011:begin out_rs_op = `SLTU; out_rob_op = `SLTU; end
                        3'b100:begin out_rs_op = `XOR; out_rob_op = `XOR; end
                        3'b101:begin 
                            case(funct7)
                                7'b0000000:begin out_rs_op = `SRL; out_rob_op = `SRL; end
                                7'b0100000:begin out_rs_op = `SRA; out_rob_op = `SRA; end
                            endcase
                        end
                        3'b110:begin out_rs_op = `OR; out_rob_op = `OR; end
                        3'b111:begin out_rs_op = `AND; out_rob_op = `AND; end
                    endcase
                end
            endcase
        end
    end
    endmodule