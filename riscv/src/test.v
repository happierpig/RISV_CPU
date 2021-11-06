`timescale 1ns/1ps
`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/test_my.v"
module test;
    reg clk;
    reg rst;
    integer i;
    wire [5:0] ans;
    my_test zyl(
        .clk(clk),.rst(rst),.ans(ans)
    );
    always #10 begin 
        clk <= ~clk;
    end
    initial begin
        #0 begin
            clk = 1'b0;
            rst = 1'b1;
        end
        #20 begin 
            rst = 1'b0;
        end
        #0 begin
            for(i = 0;i < 100;i=i+1) begin
                #1 begin
                    $display($time,"  ",ans[5:0]);
                end
            end
        end
        $finish;
    end
endmodule