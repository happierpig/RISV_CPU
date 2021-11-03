`include "constant.v"

module fetcher (
    input clk,input rst,input rdy,

    // For PC
    input [`DATA_WIDTH] in_pc_addr,output out_pc_idle,
    
    //For Memory
    input in_mem_rdy,input [`DATA_WIDTH] in_mem_instr,output reg[`DATA_WIDTH] out_mem_addr,output reg out_mem_rdy,

    output reg [`DATA_WIDTH] out_instr,
    input in_rs_idle,input in_lsb_idle,input in_rob_idle
);
    reg idle;
    assign out_pc_idle = idle && in_rs_idle && in_lsb_idle && in_rob_idle;

    always@(posedge clk) begin
        out_mem_rdy <= `FALSE; // Tell Memory Module here is new data to transport. 
        if(rst == `TRUE) begin
            idle <= `TRUE;
            out_instr <= `ZERO_DATA;
        end else if(rdy == `TRUE) begin
            if(idle == `TRUE) begin
                idle <= `FALSE;
                out_mem_addr <= in_pc_addr;
                out_mem_rdy <= `TRUE;
            end else if(in_mem_rdy == `TRUE) begin
                out_instr <= in_mem_instr;
                idle <= `TRUE;
            end
        end
    end
    
endmodule