`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module ALU (
    input clk,input rst,input rdy,
    // input from rs 
    input [`INSIDE_OPCODE_WIDTH] in_op, // `NOP to do not calculate
    input [`DATA_WIDTH] in_value1,
    input [`DATA_WIDTH] in_value2,
    input [`DATA_WIDTH] in_imm,
    input [`ROB_TAG_WIDTH] in_rob_tag,
    // output to rs/lsb/rob
    output reg [`ROB_TAG_WIDTH] out_rob_tag, // `ZERO_TAG_ROB means receivers do not treat this data.
    output reg [`DATA_WIDTH] out_value
);
    // Combinatorial logic
    always@(*) begin 
        out_rob_tag = `ZERO_TAG_ROB;
        out_value = `ZERO_DATA;
        if(in_op != `NOP) begin 
            out_rob_tag = in_rob_tag;
            case(in_op)

            endcase
        end 
    end
endmodule

// ATTENTION:
// LUI : immediate -> x[rd]
// AUIPC: pc+immediate->x[rd]
// JAL:   jump and pc+4->x[rd]
// 