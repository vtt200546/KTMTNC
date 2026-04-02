`timescale 1ns/1ps
module tb_ex_stage;
    `include "rv32_defs.vh"

    reg [31:0] pcX, pc4X, rs1_valX, rs2_valX, immX;
    reg asel_pcX, bsel_immX, branchX, jumpX, jalrX, br_unX;
    reg [4:0] alu_selX;
    reg [2:0] branch_funct3X;
    wire [31:0] alu_outX, pc_targetX, store_dataX, pc4_passX;
    wire take_branchX, br_eqX, br_ltX;

    ex_stage dut (
        .pcX(pcX), .pc4X(pc4X), .rs1_valX(rs1_valX), .rs2_valX(rs2_valX), .immX(immX),
        .asel_pcX(asel_pcX), .bsel_immX(bsel_immX), .alu_selX(alu_selX),
        .branchX(branchX), .jumpX(jumpX), .jalrX(jalrX), .br_unX(br_unX),
        .branch_funct3X(branch_funct3X), .alu_outX(alu_outX), .pc_targetX(pc_targetX),
        .take_branchX(take_branchX), .store_dataX(store_dataX), .pc4_passX(pc4_passX),
        .br_eqX(br_eqX), .br_ltX(br_ltX)
    );

    initial begin
        // ADD
        pcX = 32'h100; pc4X = 32'h104; rs1_valX = 10; rs2_valX = 7; immX = 4;
        asel_pcX = 0; bsel_immX = 0; alu_selX = ALU_ADD; branchX = 0; jumpX = 0; jalrX = 0; br_unX = 0; branch_funct3X = 0;
        #1;
        if (alu_outX !== 17 || store_dataX !== 7 || pc4_passX !== 32'h104) begin
            $display("FAIL EX add");
            $fatal;
        end

        // BEQ taken
        rs1_valX = 55; rs2_valX = 55; immX = 16; branchX = 1; branch_funct3X = 3'b000;
        #1;
        if (!(take_branchX && pc_targetX == 32'h110)) begin
            $display("FAIL EX beq");
            $fatal;
        end

        // JALR
        branchX = 0; jumpX = 1; jalrX = 1; rs1_valX = 32'h201; immX = 8;
        #1;
        if (!(take_branchX && pc_targetX == 32'h208)) begin
            $display("FAIL EX jalr");
            $fatal;
        end

        $display("tb_ex_stage PASSED");
        $finish;
    end
endmodule
