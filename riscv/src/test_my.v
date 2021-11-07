module my_test(
    input clk,input rst,output reg [5:0]ans
);
    always @(posedge clk) begin
        if(rst == 1'b1) begin 
            ans <= 6'b0;
        end else begin
            ans <= ans + 1;
            ans <= 1;
        end
    end
endmodule