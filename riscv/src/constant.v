
// Data Width
`define DATA_WIDTH 31:0
`define ROB_TAG_WIDTH 3:0
`define REG_TAG_WIDTH 4:0
`define INSIDE_OPCODE_WIDTH 5:0
`define RS_TAG_WIDTH 3:0
`define LSB_TAG_WIDTH 3:0
`define OPCODE_WIDTH 6:0

// Constant
`define TRUE    1'b1
`define FALSE   1'b0
`define ZERO_DATA 32'b0
`define REG_SIZE 32
`define ZERO_TAG_REG 5'b0
`define ZERO_TAG_ROB 4'b0
`define ZERO_TAG_RS  4'b0
`define ZERO_TAG_LSB 4'b0
`define ROB_SIZE 16
`define RS_SIZE 16
`define LSB_SIZE 16
`define JUMP_ENABLE 32'b1
`define JUMP_DISABLE 32'b0


// Instructions
`define NOP 6'b000000

//U-type
`define LUI 6'b000001
`define AUIPC 6'b000010

//J-Type
`define JAL 6'b000011

//I-Type
`define JALR 6'b000100

//B-Type
`define BEQ 6'b000101
`define BNE 6'b000110
`define BLT 6'b000111
`define BGE 6'b001000
`define BLTU 6'b001001
`define BGEU 6'b001010

//I-Type
`define LB 6'b001011
`define LH 6'b001100
`define LW 6'b001101
`define LBU 6'b001110
`define LHU 6'b001111

//S-Type
`define SB 6'b010000
`define SH 6'b010001
`define SW 6'b010010

//I-Type 
`define ADDI 6'b010011
`define SLTI 6'b010100
`define SLTIU 6'b010101
`define XORI 6'b010110
`define ORI 6'b010111
`define ANDI 6'b011000

//I-Type + shamt
`define SLLI 6'b011001
`define SRLI 6'b011010
`define SRAI 6'b011011

//R-Type
`define ADD 6'b011100
`define SUB 6'b011101
`define SLL 6'b011110
`define SLT 6'b011111
`define SLTU 6'b100000
`define XOR 6'b100001
`define SRL 6'b100010
`define SRA 6'b100011
`define OR 6'b100100
`define AND 6'b100101

// ATTENTION:

// LUI : immediate -> x[rd]
// AUIPC: pc+immediate->x[rd]

// JAL:   jump and pc+4->x[rd]
// JALR:  jump to x[rs1]+imm  and pc+4 -> x[rd]
// BEQ:   (x1 == x2) jump to pc + imm;
// BNE:   (x1 != x2) jump to pc + imm;
// BLT:   signed(x1 < x2) jump to pc + imm;
// BGE:   signed(x1 > x2) jump to pc + imm;
// BLTU:  unsigned BLT
// BGEU:  unsigned BGEU

// ADDI: x[rs1] + imm -> x[rd]
// SLTI: (x[rs1] < imm) ? 1 : 0;
// SLTIU: unsigned SLTI
// XORI: x[rs1] ^ imm -> x[rd]