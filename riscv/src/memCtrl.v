`include "/Users/dreamer/Desktop/Programm/大二 上/计算机系统/CPU/riscv/src/constant.v"

module memCtrl(
    input clk,input rst,input rdy,
    
    // check uart is full
    input in_uart_full, // 1 if uart buffer is full

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

    // from rob to load io 
    input in_rob_load_ce,

    //to rob to make read enable
    output reg out_rob_ce,

    // output data bus 
    output reg [`DATA_WIDTH] out_data,

    // interface with ram  
    output reg out_ram_rw,      // 0 for read  ; 1 for write;
    output reg [`DATA_WIDTH] out_ram_address,
    output reg [7:0] out_ram_data,
    input [7:0] in_ram_data,

    // from rob to denote misbranch 
    input in_rob_misbranch
);
    localparam IDLE = 0,FETCHER_READ = 1,LSB_READ = 2,ROB_WRITE = 3,IO_READ = 4;
    // Control units 
    reg fetcher_flag;
    reg lsb_flag;
    reg rob_flag;
    reg io_flag;
    reg [5:0] stages;
    reg [2:0] status;
    wire [2:0] buffered_status; // 0 for idle ; 1 for fetcher; 2 for lsb; 3 for rob write; 4 for rob read
    wire [7:0] buffered_write_data;
    wire disable_to_write;
    reg [1:0] wait_uart; // wait 2 cycle for uart_full signal

    // Write Buffer Control
    wire wb_is_empty;
    wire wb_is_full;
    reg [`WB_TAG_WIDTH] head;
    reg [`WB_TAG_WIDTH] tail;
    reg [`DATA_WIDTH] wb_data [(`WB_SIZE-1):0];
    reg [`DATA_WIDTH] wb_addr [(`WB_SIZE-1):0];
    reg [5:0] wb_size [(`WB_SIZE-1):0];
    wire [`WB_TAG_WIDTH] nextPtr = (tail + 1) % (`WB_SIZE);
    wire [`WB_TAG_WIDTH] nowPtr = (head + 1) % (`WB_SIZE);
    assign wb_is_empty = (head == tail) ? `TRUE : `FALSE;
    assign wb_is_full = (nextPtr == head) ? `TRUE : `FALSE;
    assign disable_to_write = (in_uart_full == `TRUE || wait_uart != 0 ) && (wb_addr[nowPtr][17:16] == 2'b11);

    // Combinatorial logic
    assign buffered_status = (io_flag == `TRUE) ? IO_READ :
                                (wb_is_empty == `FALSE) ? ROB_WRITE : 
                                    (lsb_flag == `TRUE) ? LSB_READ : 
                                        (fetcher_flag == `TRUE) ? FETCHER_READ : IDLE;

    assign buffered_write_data = (stages == 0) ? 0 :
                                    (stages == 1) ? wb_data[nowPtr][7:0] :
                                        (stages == 2) ? wb_data[nowPtr][15:8] : 
                                            (stages == 3) ? wb_data[nowPtr][23:16] : wb_data[nowPtr][31:24];
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
            status <= IDLE;
            stages <= 1;
            out_ram_rw <= 0;
            out_ram_address <= `ZERO_DATA;
            head <= 0;
            tail <= 0;
            wait_uart <= 0;
            io_flag <= `FALSE;
        end else if(rdy == `TRUE && (in_rob_misbranch == `FALSE || status == ROB_WRITE)) begin 
            if(in_rob_misbranch == `TRUE) begin 
                fetcher_flag <= `FALSE;
                out_fetcher_ce <= `FALSE;
                lsb_flag <= `FALSE;
                out_lsb_ce <= `FALSE;
                out_rob_ce <= `FALSE;
                out_data <= `ZERO_DATA;
                io_flag <= `FALSE;
            end
            // update buffer
            wait_uart <= wait_uart - ((wait_uart == 0) ? 0 : 1);
            out_ram_rw <= 0; // avoid repeatedly writing
            out_rob_ce <= `FALSE;
            out_lsb_ce <= `FALSE;
            out_fetcher_ce <= `FALSE;
            out_ram_data <= 0;
            if(in_rob_load_ce == `TRUE) begin io_flag <= `TRUE; end
            if(in_fetcher_ce == `TRUE) begin fetcher_flag <= `TRUE;end
            if(in_lsb_ce == `TRUE) begin lsb_flag <= `TRUE; end 
            if(in_rob_ce == `TRUE || rob_flag == `TRUE) begin 
                if(wb_is_full == `FALSE) begin 
                    rob_flag <= `FALSE;
                    out_rob_ce <= `TRUE;
                    wb_addr[nextPtr] <= in_rob_addr;
                    wb_data[nextPtr] <= in_rob_data;
                    wb_size[nextPtr] <= in_rob_size;
                    tail <= nextPtr;
                end else begin 
                    rob_flag <= `TRUE; 
                end
            end
            out_ram_address <= out_ram_address + 1;
            stages <= stages + 1;
            case(status)
                IO_READ:begin 
                    case(stages) 
                        1:begin out_ram_address <= `ZERO_DATA; end
                        2:begin
                            out_data <= in_ram_data;
                            stages <= 1;
                            io_flag <= `FALSE;
                            out_rob_ce <= `TRUE;
                            status <= IDLE;
                        end
                    endcase
                end
                ROB_WRITE:begin 
                    if(disable_to_write == `TRUE) begin
                        out_ram_address <= `ZERO_DATA;
                        out_ram_data <= 1;
                        stages <= 1;
                    end else begin 
                        out_ram_rw <= 1;
                        if(stages == 1) begin out_ram_address <= wb_addr[nowPtr]; end
                        out_ram_data <= buffered_write_data;
                        if(stages == wb_size[nowPtr]) begin
                            head <= nowPtr;
                            stages <= 1;
                            if(nowPtr == tail) begin status <= IDLE; end  
                            else begin 
                                status <= ROB_WRITE;
                                if(wb_addr[nowPtr] == `IO_ADDRESS) wait_uart <= 2;
                            end
                        end
                    end
                end
                LSB_READ:begin 
                    case(in_lsb_size)
                        1: begin 
                            case(stages) 
                                // 1:begin out_ram_address <= in_lsb_addr; end
                                2:begin
                                    if(in_lsb_signed == 1) begin out_data <= $signed(in_ram_data);end
                                    else begin out_data <= in_ram_data; end
                                    stages <= 1 ;
                                    lsb_flag <= `FALSE;
                                    out_lsb_ce <= `TRUE;
                                    if(wb_is_empty == `FALSE) begin
                                        status <= ROB_WRITE; 
                                        out_ram_address <= `ZERO_DATA;
                                    end else if(fetcher_flag == `TRUE) begin
                                        status <= FETCHER_READ;
                                        out_ram_address <= in_fetcher_addr;
                                    end else begin status <= IDLE; end
                                end
                            endcase
                        end
                        2: begin 
                            case(stages) 
                                // 1: begin out_ram_address <= in_lsb_addr;end 
                                2: begin out_data[7:0] <= in_ram_data; end
                                3: begin 
                                    if(in_lsb_signed) begin out_data <= $signed({in_ram_data,out_data[7:0]}); end
                                    else begin out_data <= {in_ram_data,out_data[7:0]}; end
                                    stages <= 1;
                                    lsb_flag <= `FALSE;
                                    out_lsb_ce <= `TRUE;
                                    if(wb_is_empty == `FALSE) begin
                                        status <= ROB_WRITE; 
                                        out_ram_address <= `ZERO_DATA;
                                    end else if(fetcher_flag == `TRUE) begin
                                        status <= FETCHER_READ;
                                        out_ram_address <= in_fetcher_addr;
                                    end else begin status <= IDLE; end
                                end
                            endcase
                        end
                        4: begin 
                            case(stages) 
                                // 1: begin out_ram_address <= in_lsb_addr; end 
                                2: begin out_data[7:0] <= in_ram_data; end
                                3: begin out_data[15:8] <= in_ram_data; end
                                4: begin out_data[23:16] <= in_ram_data; end 
                                5: begin 
                                    out_data[31:24] <= in_ram_data;
                                    stages <= 1;
                                    lsb_flag <= `FALSE;
                                    out_lsb_ce <= `TRUE;
                                    if(wb_is_empty == `FALSE) begin
                                        status <= ROB_WRITE; 
                                        out_ram_address <= `ZERO_DATA;
                                    end else if(fetcher_flag == `TRUE) begin
                                        status <= FETCHER_READ;
                                        out_ram_address <= in_fetcher_addr;
                                    end else begin status <= IDLE; end
                                end 
                            endcase
                        end
                    endcase
                end
                FETCHER_READ:begin
                    case(stages) 
                        // 1: begin out_ram_address <= in_fetcher_addr; end
                        2: begin out_data[7:0] <= in_ram_data; end
                        3: begin out_data[15:8] <= in_ram_data; end
                        4: begin out_data[23:16] <= in_ram_data; end 
                        5: begin 
                            out_data[31:24] <= in_ram_data;
                            stages <= 1;
                            fetcher_flag <= `FALSE;
                            out_fetcher_ce <= `TRUE;
                            if(wb_is_empty == `FALSE) begin 
                                status <= ROB_WRITE;
                                out_ram_address <= `ZERO_DATA;
                            end else if(lsb_flag == `TRUE) begin 
                                status <= LSB_READ;
                                out_ram_address <= in_lsb_addr; 
                            end else begin status <= IDLE; end
                        end   
                    endcase
                end
                IDLE: begin 
                    stages <= 1;
                    status <= buffered_status;
                    out_ram_address <=  (buffered_status == IO_READ) ? `IO_ADDRESS :
                                            (buffered_status == ROB_WRITE) ? `ZERO_DATA : 
                                                (buffered_status == LSB_READ) ? in_lsb_addr :
                                                    (buffered_status == FETCHER_READ) ? in_fetcher_addr : `ZERO_DATA;
                end
            endcase
        end else if(rdy == `TRUE && in_rob_misbranch == `TRUE) begin 
            fetcher_flag <= `FALSE;
            out_fetcher_ce <= `FALSE;
            lsb_flag <= `FALSE;
            out_lsb_ce <= `FALSE;
            out_rob_ce <= `FALSE;
            out_data <= `ZERO_DATA;
            status <= IDLE;
            stages <= 1;
            out_ram_rw <= 0;
            out_ram_address <= `ZERO_DATA;
            if(wb_is_empty == `FALSE) begin status <= ROB_WRITE; end
        end
    end

endmodule