`include "constant.v"

module pc (
    input clk,input rst,input rdy,

    // For Fetcher
    input in_fetcher_idle,input [`DATA_WIDTH] in_last_instr,output reg [`DATA_WIDTH] out_pc
);
    reg [`ZERO_DATA] now_pc;

    always @(posedge clk) begin
        if(rst == `TRUE) begin
            now_pc <= `ZERO_DATA;
            out_pc <= `ZERO_DATA;
        end else if(rdy == `TRUE && in_fetcher_idle == `TRUE) begin
            out_pc <= now_pc;
            // todo : jump and branch operation
            now_pc <= now_pc + 4;
        end
    end

    
endmodule