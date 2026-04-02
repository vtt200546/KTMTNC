`timescale 1ns/1ps
module tb_control_unit;
    `include "rv32_defs.vh"

    reg  [31:0] instr;
    wire reg_write, mem_read, mem_write, asel_pc, bsel_imm, branch, jump, jalr, br_un, use_rs1, use_rs2, valid;
    wire [1:0] wb_sel;
    wire [4:0] alu_sel;
    wire [2:0] imm_sel, branch_funct3, mem_funct3;

    control_unit dut (
        .instr(instr), .reg_write(reg_write), .mem_read(mem_read), .mem_write(mem_write),
        .wb_sel(wb_sel), .asel_pc(asel_pc), .bsel_imm(bsel_imm), .alu_sel(alu_sel),
        .imm_sel(imm_sel), .branch(branch), .jump(jump), .jalr(jalr), .br_un(br_un),
        .branch_funct3(branch_funct3), .mem_funct3(mem_funct3), .use_rs1(use_rs1),
        .use_rs2(use_rs2), .valid(valid)
    );

    function automatic [31:0] enc_r(input [6:0] funct7, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction
    function automatic [31:0] enc_i(input integer imm, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        enc_i = {imm[11:0], rs1, funct3, rd, opcode};
    endfunction
    function automatic [31:0] enc_b(input integer imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [6:0] opcode);
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction
    function automatic [31:0] enc_j(input integer imm, input [4:0] rd, input [6:0] opcode);
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    initial begin
        instr = enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, OPC_RTYPE); #1;
        if (!(reg_write && use_rs1 && use_rs2 && alu_sel == ALU_ADD)) begin
            $display("FAIL CU ADD");
            $fatal;
        end

        instr = enc_i(12, 5'd1, 3'b010, 5'd3, OPC_LOAD); #1;
        if (!(reg_write && mem_read && wb_sel == WB_MEM && bsel_imm)) begin
            $display("FAIL CU LW");
            $fatal;
        end

        instr = enc_b(8, 5'd2, 5'd1, 3'b000, OPC_BRANCH); #1;
        if (!(branch && use_rs1 && use_rs2 && imm_sel == IMM_B)) begin
            $display("FAIL CU BEQ");
            $fatal;
        end

        instr = enc_j(16, 5'd1, OPC_JAL); #1;
        if (!(jump && reg_write && wb_sel == WB_PC4)) begin
            $display("FAIL CU JAL");
            $fatal;
        end

        $display("tb_control_unit PASSED");
        $finish;
    end
endmodule
