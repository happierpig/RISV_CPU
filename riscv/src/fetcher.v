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
    output reg out_jump_ce,

    // RS/LSB/ROB's status
    input in_rs_idle,
    input in_lsb_idle,
    input in_rob_idle,

    // enable rs/lsb/rob to store entry 
    output reg out_store_ce,

    // from rob to denote that misbranch
    input in_rob_misbranch,
    input [`DATA_WIDTH] in_rob_newpc,

    // to and from BranchPredictor
    output [`BP_TAG_WIDTH] out_bp_tag,
    input in_bp_jump_ce
);
    // Control Units
    localparam IDLE = 2'b0,WAIT_MEM = 2'b01,WAIT_IDLE = 2'b10;
    reg [2:0] status; // True for idle and false denotes waiting for memory response.
    reg [`DATA_WIDTH] pc;
    wire next_idle = in_rs_idle && in_lsb_idle && in_rob_idle;

    // 0.5KB i-cache  Size can be modifier by changing parameter
    reg [24:0] icache_tag [(`ICACHE_SIZE-1):0];
    reg [`DATA_WIDTH] icache_instr [(`ICACHE_SIZE-1):0];
    reg icache_valid [(`ICACHE_SIZE-1):0];

    // Combinatorial logic for BP
    assign out_bp_tag = pc[`BP_HASH_WIDTH];

    integer i;
    always@(posedge clk) begin
        if(rst == `TRUE) begin 
            status <= IDLE;
            pc <= `ZERO_DATA;
            out_mem_ce <= `FALSE;
            out_instr <= `ZERO_DATA;
            out_store_ce <= `FALSE;
            for(i=0;i < `ICACHE_SIZE;i=i+1) begin
                icache_valid[i] <= `FALSE;
            end 
        end else if(rdy == `TRUE) begin 
            out_mem_ce <= `FALSE;
            out_store_ce <= `FALSE;
            if(in_rob_misbranch == `TRUE) begin 
                status <= IDLE;
                pc <= in_rob_newpc;
            end else begin
                if(status == IDLE) begin
                    // cache hit
                    if(icache_valid[pc[`ICACHE_INDEX_WIDTH]] == `TRUE && icache_tag[pc[`ICACHE_INDEX_WIDTH]] == pc[`ICACHE_TAG_WIDTH]) begin 
                        out_instr <= icache_instr[pc[`ICACHE_INDEX_WIDTH]];
                        out_pc <= pc;
                        if(next_idle == `TRUE) begin 
                            out_store_ce <= `TRUE;
                            status <= IDLE;
                            if(icache_instr[pc[`ICACHE_INDEX_WIDTH]][`OPCODE_WIDTH] == 7'b1101111) begin //JAL
                                pc <= pc + {{12{icache_instr[pc[`ICACHE_INDEX_WIDTH]][31]}}, icache_instr[pc[`ICACHE_INDEX_WIDTH]][19:12], icache_instr[pc[`ICACHE_INDEX_WIDTH]][20], icache_instr[pc[`ICACHE_INDEX_WIDTH]][30:25], icache_instr[pc[`ICACHE_INDEX_WIDTH]][24:21], 1'b0};
                            end else if(icache_instr[pc[`ICACHE_INDEX_WIDTH]][`OPCODE_WIDTH] == 7'b1100011) begin 
                                if(in_bp_jump_ce == `TRUE) begin 
                                    out_jump_ce <= `TRUE; 
                                    pc <= pc + {{20{icache_instr[pc[`ICACHE_INDEX_WIDTH]][31]}}, icache_instr[pc[`ICACHE_INDEX_WIDTH]][7], icache_instr[pc[`ICACHE_INDEX_WIDTH]][30:25], icache_instr[pc[`ICACHE_INDEX_WIDTH]][11:8], 1'b0};
                                end else begin 
                                    out_jump_ce <= `FALSE;
                                    pc <= pc + 4;
                                end
                            end else begin pc <= pc + 4; end;
                        end else begin status <= WAIT_IDLE; end
                    end else begin  // cache miss
                        status <= WAIT_MEM;
                        out_mem_ce <= `TRUE;
                        out_mem_pc <= pc;
                    end
                end else if(status == WAIT_MEM) begin 
                    if(in_mem_ce == `TRUE) begin 
                        out_instr <= in_mem_instr;
                        out_pc <= pc;
                        // change i-cache entry
                        icache_valid[pc[`ICACHE_INDEX_WIDTH]] <= `TRUE;
                        icache_tag[pc[`ICACHE_INDEX_WIDTH]] <= pc[`ICACHE_TAG_WIDTH];
                        icache_instr[pc[`ICACHE_INDEX_WIDTH]] <= in_mem_instr;
                        if(next_idle == `TRUE) begin 
                            out_store_ce <= `TRUE;
                            status <= IDLE;
                            if(in_mem_instr[`OPCODE_WIDTH] == 7'b1101111) begin 
                                pc <= pc + {{12{in_mem_instr[31]}}, in_mem_instr[19:12], in_mem_instr[20], in_mem_instr[30:25], in_mem_instr[24:21], 1'b0};
                            end else if(in_mem_instr[`OPCODE_WIDTH] == 7'b1100011) begin 
                                if(in_bp_jump_ce == `TRUE) begin 
                                    out_jump_ce <= `TRUE;
                                    pc <= pc + {{20{in_mem_instr[31]}}, in_mem_instr[7], in_mem_instr[30:25], in_mem_instr[11:8], 1'b0};
                                end else begin 
                                    out_jump_ce <= `FALSE;
                                    pc <= pc + 4;
                                end
                            end else begin pc <= pc + 4; end
                        end else begin status <= WAIT_IDLE; end
                    end
                end else if(status == WAIT_IDLE && next_idle == `TRUE) begin 
                    out_store_ce <= `TRUE;
                    status <= IDLE;
                    if(out_instr[`OPCODE_WIDTH] == 7'b1101111) begin
                        pc <= pc + {{12{out_instr[31]}}, out_instr[19:12], out_instr[20], out_instr[30:25], out_instr[24:21], 1'b0};
                    end else if(out_instr[`OPCODE_WIDTH] == 7'b1100011) begin 
                        if(in_bp_jump_ce == `TRUE) begin 
                            out_jump_ce <= `TRUE;
                            pc <= pc + {{20{out_instr[31]}}, out_instr[7], out_instr[30:25], out_instr[11:8], 1'b0};
                        end else begin 
                            out_jump_ce <= `FALSE;
                            pc <= pc + 4;
                        end
                    end else begin pc <= pc + 4; end
                end
            end
        end
    end
    
endmodule