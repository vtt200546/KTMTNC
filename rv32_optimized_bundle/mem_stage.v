module mem_stage #(
    parameter DMEM_BYTES = 4096,
    parameter DMEM_INIT  = ""
) (
    input  wire        clk,
    input  wire        mem_readM,
    input  wire        mem_writeM,
    input  wire [2:0]  mem_funct3M,
    input  wire [31:0] addrM,
    input  wire [31:0] store_dataM,
    output wire [31:0] load_dataM
);
    dmem #(
        .BYTES(DMEM_BYTES),
        .INIT_FILE(DMEM_INIT)
    ) u_dmem (
        .clk      (clk),
        .mem_read (mem_readM),
        .mem_write(mem_writeM),
        .funct3   (mem_funct3M),
        .addr     (addrM),
        .wdata    (store_dataM),
        .rdata    (load_dataM)
    );
endmodule
