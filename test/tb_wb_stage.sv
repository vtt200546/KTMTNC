`timescale 1ns/1ps
module tb_wb_stage;
    `include "rv32_defs.vh"

    reg [1:0] wb_selW;
    reg [31:0] aluW, memW, pc4W;
    wire [31:0] wb_dataW;

    wb_stage dut (.wb_selW(wb_selW), .aluW(aluW), .memW(memW), .pc4W(pc4W), .wb_dataW(wb_dataW));

    initial begin
        aluW = 32'h1111; memW = 32'h2222; pc4W = 32'h3333;
        wb_selW = WB_ALU; #1; if (wb_dataW !== aluW) begin $display("FAIL WB ALU"); $fatal; end
        wb_selW = WB_MEM; #1; if (wb_dataW !== memW) begin $display("FAIL WB MEM"); $fatal; end
        wb_selW = WB_PC4; #1; if (wb_dataW !== pc4W) begin $display("FAIL WB PC4"); $fatal; end
        $display("tb_wb_stage PASSED");
        $finish;
    end
endmodule
