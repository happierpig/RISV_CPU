module my_test(
    input clk,input rst,output [5:0]ans
);
    reg [5:0] x;
    wire [5:0]y;
    assign y = x + 1;
    assign ans = y;
    reg [5:0]z[10:0];
    integer i;
    initial begin 
        for(i = 0;i < 10;i=i+1)
            z[i] = i;
    end
    always @(posedge clk) begin
        if(rst == 1'b1) begin 
            x <= 6'b0;
        end else begin
            x <= y;
            $display($time,"test for z",z[y]);
        end
    end
endmodule