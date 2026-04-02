`timescale 1ns/1ps
module tb_id_stage;
    `include "rv32_defs.vh"

    reg [31:0] instrD, pcD, pc4D, rs1_dataD, rs2_dataD;
    wire [4:0] rs1_addrD, rs2_addrD, rd_addrD;
    wire [31:0] immD, d1D, d2D, pc_outD, pc4_outD;
    wire reg_writeD, mem_readD, mem_writeD, asel_pcD, bsel_immD, branchD, jumpD, jalrD, br_unD, use_rs1D, use_rs2D, validD;
    wire [1:0] wb_selD;
    wire [4:0] alu_selD;
    wire [2:0] imm_selD, branch_funct3D, mem_funct3D;

    id_stage dut (
        .instrD(instrD), .pcD(pcD), .pc4D(pc4D), .rs1_dataD(rs1_dataD), .rs2_dataD(rs2_dataD),
        .rs1_addrD(rs1_addrD), .rs2_addrD(rs2_addrD), .rd_addrD(rd_addrD),
        .immD(immD), .d1D(d1D), .d2D(d2D), .pc_outD(pc_outD), .pc4_outD(pc4_outD),
        .reg_writeD(reg_writeD), .mem_readD(mem_readD), .mem_writeD(mem_writeD), .wb_selD(wb_selD),
        .asel_pcD(asel_pcD), .bsel_immD(bsel_immD), .alu_selD(alu_selD), .imm_selD(imm_selD),
        .branchD(branchD), .jumpD(jumpD), .jalrD(jalrD), .br_unD(br_unD), .branch_funct3D(branch_funct3D),
        .mem_funct3D(mem_funct3D), .use_rs1D(use_rs1D), .use_rs2D(use_rs2D), .validD(validD)
    );

    function automatic [31:0] enc_i(input integer imm, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        enc_i = {imm[11:0], rs1, funct3, rd, opcode};
    endfunction

    initial begin
        pcD = 32'h10; pc4D = 32'h14; rs1_dataD = 32'h1111_1111; rs2_dataD = 32'h2222_2222;
        instrD = enc_i(12, 5'd3, 3'b000, 5'd5, OPC_ITYPE); #1;
        if (!(rs1_addrD == 5'd3 && rd_addrD == 5'd5 && immD == 32'd12 && reg_writeD && bsel_immD)) begin
            $display("FAIL ID addi decode");
            $fatal;
        end
        if (!(d1D == 32'h1111_1111 && d2D == 32'h2222_2222 && pc_outD == 32'h10 && pc4_outD == 32'h14)) begin
            $display("FAIL ID pass-through");
            $fatal;
        end
        $display("tb_id_stage PASSED");
        $finish;
    end
endmodule
