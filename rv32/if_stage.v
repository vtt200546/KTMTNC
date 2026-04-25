module if_stage #(
    parameter IMEM_DEPTH = 256,
    parameter IMEM_INIT  = ""
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        stallF,
    input  wire        pc_sel,
    input  wire [31:0] pc_target,
    output wire [31:0] pcF,
    output wire [31:0] pc4F,
    output wire [31:0] instrF
);
    pc_unit u_pc (
        .clk      (clk),
        .rst      (rst),
        .stallF   (stallF),
        .pc_sel   (pc_sel),
        .pc_target(pc_target),
        .pcF      (pcF),
        .pc4F     (pc4F)
    );
    imem #(
        .DEPTH(IMEM_DEPTH),
        .INIT_FILE(IMEM_INIT)
    ) u_imem (
        .addr (pcF),
        .instr(instrF)
    );
    
endmodule
