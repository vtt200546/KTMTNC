module if_stage #(
    parameter IMEM_DEPTH = 256,
    parameter IMEM_INIT  = ""
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        stallF,
    input  wire        pc_sel,
    input  wire [31:0] pc_target,
    output reg  [31:0] pcF,
    output wire [31:0] pc4F,
    output wire [31:0] instrF
);
    imem #(
        .DEPTH(IMEM_DEPTH),
        .INIT_FILE(IMEM_INIT)
    ) u_imem (
        .addr (pcF),
        .instr(instrF)
    );

    assign pc4F = pcF + 32'd4;

    always @(posedge clk or posedge rst) begin
        if (rst)
            pcF <= 32'h0;
        else if (!stallF)
            pcF <= pc_sel ? pc_target : (pcF + 32'd4);
    end
endmodule
