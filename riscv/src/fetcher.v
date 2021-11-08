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
    output reg [`DATA_WIDTH] out_pc,

    // RS/LSB/ROB's status
    input in_rs_idle,
    input in_lsb_idle,
    input in_rob_idle,

    // enable rs/lsb/rob to store entry 
    output reg out_store_ce
);
    // Control Units
    parameter IDLE = 2'b0,WAIT_MEM = 2'b01,WAIT_IDLE = 2'b10;
    reg [2:0] status; // True for idle and false denotes waiting for memory response.
    reg [`DATA_WIDTH] pc;
    wire next_idle = in_rs_idle && in_lsb_idle && in_rob_idle;
    
    always@(posedge clk) begin
        if(rst == `TRUE) begin 
            status <= IDLE;
            pc <= `ZERO_DATA;
            out_mem_ce <= `FALSE;
            out_mem_pc <= `ZERO_DATA;
            out_instr <= `ZERO_DATA;
            out_pc <= `ZERO_DATA;
            out_store_ce <= `FALSE;
        end else if(rdy == `TRUE) begin 
            out_mem_ce <= `FALSE;
            out_store_ce <= `FALSE;
            if(status == IDLE) begin 
                status <= WAIT_MEM;
                out_mem_ce <= `TRUE;
                out_mem_pc <= pc;
            end else if(status == WAIT_MEM) begin 
                if(in_mem_ce == `TRUE) begin 
                    out_instr <= in_mem_instr;
                    out_pc <= pc;
                    if(next_idle == `TRUE) begin 
                        out_store_ce <= `TRUE;
                        status <= IDLE;
                    end else begin status <= WAIT_IDLE; end

                    // todo : branch instruction
                    pc <= pc + 4;
                end
            end else if(status == WAIT_IDLE) begin 
                out_store_ce <= `TRUE;
                status <= IDLE;
            end
        end
    end
    
endmodule