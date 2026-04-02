`timescale 1ns/1ps
module tb_mem_stage;
    reg clk = 0;
    reg mem_readM, mem_writeM;
    reg [2:0] mem_funct3M;
    reg [31:0] addrM, store_dataM;
    wire [31:0] load_dataM;

    mem_stage #(.DMEM_BYTES(64)) dut (
        .clk(clk), .mem_readM(mem_readM), .mem_writeM(mem_writeM), .mem_funct3M(mem_funct3M),
        .addrM(addrM), .store_dataM(store_dataM), .load_dataM(load_dataM)
    );

    always #5 clk = ~clk;

    initial begin
        mem_readM = 0; mem_writeM = 1; mem_funct3M = 3'b010; addrM = 4; store_dataM = 32'hCAFE_BABE;
        #10 mem_writeM = 0;

        mem_readM = 1; mem_funct3M = 3'b010; #1;
        if (load_dataM !== 32'hCAFE_BABE) begin
            $display("FAIL MEM lw");
            $fatal;
        end

        $display("tb_mem_stage PASSED");
        $finish;
    end
endmodule
