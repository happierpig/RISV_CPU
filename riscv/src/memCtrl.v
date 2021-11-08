`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module memCtrl(
    input clk,input rst,input rdy,

    // from fetcher to get instruction
    input in_fetcher_ce,
    input [`DATA_WIDTH] in_fetcher_addr,

    // to fetcher to make read enable 
    output reg out_fetcher_ce,

    // from lsb to read memory 
    input in_lsb_ce,
    input [`DATA_WIDTH] in_lsb_addr,
    input [5:0] in_lsb_size,
    input in_lsb_signed,

    // to lsb to make read enable 
    output reg out_lsb_ce,

    // from rob to write memory 
    input in_rob_ce,
    input [`DATA_WIDTH] in_rob_addr,
    input [5:0] in_rob_size,
    input [`DATA_WIDTH] in_rob_data,

    //to rob to make read enable
    output reg out_rob_ce,

    // output data bus 
    output reg [`DATA_WIDTH] out_data,

    // interface with ram  
    output reg out_ram_rw,      // 1 for read  ; 0 for write;
    output reg out_ram_address,
    output reg [7:0] out_ram_data,
    input [7:0] in_ram_data,

    // from rob to denote misbranch 
    input in_rob_misbranch
);

    // Control units 
    reg fetcher_flag;
    reg lsb_flag;
    reg rob_flag;
    reg [5:0] stages;
    reg [1:0] status;
    wire [1:0] buffered_status; // 0 for idle ; 1 for fetcher; 2 for lsb; 3 for lsb;
    wire [7:0] buffered_write_data;
    // Combinatorial logic
    assign buffered_status = (rob_flag == `TRUE) ? 3 : 
                                (lsb_flag == `TRUE) ? 2 : 
                                    (fetcher_flag == `TRUE) ? 1 : 0;
    assign buffered_write_data = (stages == 0) ? 0 :
                                    (stages == 1) ? in_rob_data[7:0] :
                                        (stages == 2) ? in_rob_data[15:8] : 
                                            (stages == 3) ? in_rob_data[23:16] : in_rob_data[31:24];
    // Temporal logic
    always @(posedge clk) begin 
        if(rst == `TRUE) begin 
            fetcher_flag <= `FALSE;
            out_fetcher_ce <= `FALSE;
            lsb_flag <= `FALSE;
            out_lsb_ce <= `FALSE;
            rob_flag <= `FALSE;
            out_rob_ce <= `FALSE;
            out_data <= `ZERO_DATA;
            status <= 0;
            stages <= 1;
            out_ram_rw <= 1;
            out_ram_address <= `ZERO_DATA;
        end else if(rdy == `TRUE && in_rob_misbranch == `FALSE) begin 
            // update buffer
            out_ram_rw <= 1; // avoid repeatedly writing
            out_rob_ce <= `FALSE;
            out_lsb_ce <= `FALSE;
            out_fetcher_ce <= `FALSE;
            if(in_fetcher_ce == `TRUE) begin fetcher_flag <= `TRUE;end
            if(in_lsb_ce == `TRUE) begin lsb_flag <= `TRUE; end 
            if(in_rob_ce == `TRUE) begin rob_flag <= `TRUE; end
            out_ram_address <= out_ram_address + 1;
            stages <= stages + 1;
            case(status)
                3:begin 
                    out_ram_rw <= 0;
                    if(stages == 1) begin out_ram_address <= in_rob_addr; end
                    out_ram_data <= buffered_write_data;
                    if(stages == in_rob_size) begin 
                        stages <= 1;
                        rob_flag <= `FALSE;
                        out_rob_ce <= `TRUE;
                        status <= 0;
                    end
                end
                2:begin 
                    case(in_lsb_size)
                        1: begin 
                            case(stages) 
                                1:begin out_ram_address <= in_lsb_addr; end
                                2:begin
                                    if(in_lsb_signed == 1) begin out_data <= $signed(in_ram_data);end
                                    else begin out_data <= in_ram_data; end
                                    stages <= 1 ;
                                    lsb_flag <= `FALSE;
                                    out_lsb_ce <= `TRUE;
                                    status <= 0;
                                end
                            endcase
                        end
                        2: begin 
                            case(stages) 
                                1: begin out_ram_address <= in_lsb_addr;end 
                                2: begin out_data[7:0] <= in_ram_data; end
                                3: begin 
                                    if(in_lsb_signed) begin out_data <= $signed({in_ram_data,out_data[7:0]}); end
                                    else begin out_data <= {in_ram_data,out_data[7:0]}; end
                                    stages <= 1;
                                    lsb_flag <= `FALSE;
                                    out_lsb_ce <= `TRUE;
                                    status <= 0;
                                end
                            endcase
                        end
                        4: begin 
                            case(stages) 
                                1: begin out_ram_address <= in_lsb_addr; end 
                                2: begin out_data[7:0] <= in_ram_data; end
                                3: begin out_data[15:8] <= in_ram_data; end
                                4: begin out_data[23:16] <= in_ram_data; end 
                                5: begin 
                                    out_data[31:24] <= in_ram_data;
                                    stages <= 1;
                                    lsb_flag <= `FALSE;
                                    out_lsb_ce <= `TRUE;
                                    status <= 0;
                                end 
                            endcase
                        end
                    endcase
                end
                1:begin
                    case(stages) 
                        1: begin out_ram_address <= in_fetcher_addr; end
                        2: begin out_data[7:0] <= in_ram_data; end
                        3: begin out_data[15:8] <= in_ram_data; end
                        4: begin out_data[23:16] <= in_ram_data; end 
                        5: begin 
                            out_data[31:24] <= in_ram_data;
                            stages <= 1;
                            fetcher_flag <= `FALSE;
                            out_fetcher_ce <= `TRUE;
                            status <= 0;
                        end   
                    endcase
                end
                0: begin 
                    out_ram_address <= `ZERO_DATA;
                    stages <= 1;
                    status <= buffered_status;
                end
            endcase
        end else if(rdy == `TRUE && in_rob_misbranch == `TRUE) begin 
            fetcher_flag <= `FALSE;
            out_fetcher_ce <= `FALSE;
            lsb_flag <= `FALSE;
            out_lsb_ce <= `FALSE;
            rob_flag <= `FALSE;
            out_rob_ce <= `FALSE;
            out_data <= `ZERO_DATA;
            status <= 0;
            stages <= 1;
            out_ram_rw <= 1;
            out_ram_address <= `ZERO_DATA;
        end
    end

endmodule