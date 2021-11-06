`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module fetcher (
    input clk,input rst,input rdy,
    
    // Ask memory control to get instruction
    output reg out_mem_ce,
    output reg[`DATA_WIDTH] out_mem_pc,

    // Get Instruction from memory
    input in_mem_ce,
    input [`DATA_WIDTH] in_mem_instr,

    // pass to decoder
    output reg [`DATA_WIDTH] out_instr,

    // RS/LSB/ROB's status
    input in_rs_idle,
    input in_lsb_idle,
    input in_rob_idle,

    // enable rs/lsb/rob to store entry 
    output reg out_store_ce
);
    // Control Units
    reg idle; // True for idle and false denotes waiting for memory response.
    reg [`DATA_WIDTH] pc;
    wire isIdle;
    assign isIdle = idle && in_rs_idle && in_lsb_idle && in_rob_idle;

    always@(posedge clk) begin
        if(rst == `TRUE) begin 
            idle <= `TRUE;
            pc <= `ZERO_DATA;
            out_mem_ce <= `FALSE;
            out_mem_pc <= `ZERO_DATA;
            out_instr <= `ZERO_DATA;
            out_store_ce <= `FALSE;
        end else if(rdy == `TRUE) begin 
            out_mem_ce <= `FALSE;
            out_store_ce <= `FALSE;
            if(isIdle == `TRUE) begin 
                idle <= `FALSE;
                out_mem_ce <= `TRUE;
                out_mem_pc <= pc;
            end else if(idle == `FALSE) begin 
                if(in_mem_ce == `TRUE) begin 
                    out_instr <= in_mem_instr;
                    out_store_ce <= `TRUE;
                    idle <= `TRUE;
                    // todo : branch instruction and pc value pass
                    pc <= pc + 4;
                end
            end
        end
    end
    
endmodule