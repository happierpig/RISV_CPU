`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module ALU (
    input clk,input rst,input rdy,
    // input from rs 
    input [`INSIDE_OPCODE_WIDTH] in_op, // `NOP to do not calculate
    input [`DATA_WIDTH] in_value1,
    input [`DATA_WIDTH] in_value2,
    input [`DATA_WIDTH] in_imm,
    input [`DATA_WIDTH] in_pc,
    input [`ROB_TAG_WIDTH] in_rob_tag,
    // output to rs/lsb/rob
    output reg [`ROB_TAG_WIDTH] out_rob_tag, // `ZERO_TAG_ROB means receivers do not treat this data.
    output reg [`DATA_WIDTH] out_value,
    output reg [`DATA_WIDTH] out_newpc
);
    // Combinatorial logic
    always@(*) begin 
        out_value = `ZERO_DATA;
        out_newpc = `ZERO_DATA;
        out_rob_tag = `ZERO_TAG_ROB;
        if(in_op != `NOP) begin 
            out_rob_tag = in_rob_tag;
            case(in_op)
                `LUI: begin out_value = in_imm; end
                `AUIPC: begin out_value = in_pc + in_imm; end
                `JAL: begin out_value = in_pc + 4;end 
                
                `JALR: begin 
                    out_value = in_pc + 4;
                    out_newpc = in_value1 + in_imm;
                end
                `BEQ:begin 
                    out_value = (in_value1 == in_value2) ? `JUMP_ENABLE : `JUMP_DISABLE;
                    out_newpc = in_pc + in_imm;
                end
                `BNE:begin 
                    out_value = (in_value1 != in_value2) ? `JUMP_ENABLE : `JUMP_DISABLE;
                    out_newpc = in_pc + in_imm;
                end
                `BLT:begin 
                    out_value = ($signed(in_value1) < $signed(in_value2)) ? `JUMP_ENABLE : `JUMP_DISABLE;
                    out_newpc = in_pc + in_imm;
                end
                `BGE: begin 
                    out_value = ($signed(in_value1) > $signed(in_value2)) ? `JUMP_ENABLE : `JUMP_DISABLE;
                    out_newpc = in_pc + in_imm;
                end
                `BLTU: begin 
                    out_value = (in_value1 < in_value2) ? `JUMP_ENABLE : `JUMP_DISABLE;
                    out_newpc = in_pc + in_imm;
                end
                `BGEU: begin 
                    out_value = (in_value1 > in_value2) ? `JUMP_ENABLE : `JUMP_DISABLE;
                    out_newpc = in_pc + in_imm;
                end

                `ADDI: begin out_value = in_value1 + in_imm; end
                `SLTI: begin out_value = ($signed(in_value1) < $signed(in_imm)) ? 1 : 0; end
                `SLTIU: begin out_value = (in_value1 < in_imm) ? 1 : 0; end
                `XORI: begin out_value = in_value1 ^ in_imm; end
                `ORI: begin out_value =  in_value1 | in_imm; end   
                `ANDI: begin out_value = in_value1 & in_imm; end  
                `SLLI: begin out_value = in_value1 << in_imm; end
                `SRLI: begin out_value = in_value1 >> in_imm; end
                `SRAI: begin out_value = in_value1 >>> in_imm; end 
                `ADD: begin out_value = in_value1 + in_value2; end 
                `SUB: begin out_value = in_value1 - in_value2; end 
                `SLL: begin out_value = in_value1 << in_value2; end 
                `SLT: begin out_value = ($signed(in_value1) < $signed(in_value2)) ? 1 : 0; end 
                `SLTU: begin out_value = (in_value1 < in_value2) ? 1 : 0; end
                `XOR: begin out_value = in_value1 ^ in_value2; end 
                `SRL: begin out_value = in_value1 >> in_value2; end 
                `SRA: begin out_value = in_value1 >>> in_value2; end 
                `OR: begin out_value = in_value1 | in_value2; end 
                `AND: begin out_value = in_value1 & in_value2; end
            endcase
        end 
    end
endmodule