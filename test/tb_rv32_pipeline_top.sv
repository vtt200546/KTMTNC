`timescale 1ns/1ps
module tb_rv32_pipeline_top;
    `include "rv32_defs.vh"

    reg clk = 0, rst = 1;

    rv32_pipeline_top #(
        .IMEM_DEPTH(64),
        .DMEM_BYTES(256)
    ) uut (
        .clk(clk),
        .rst(rst)
    );

    always #5 clk = ~clk;

    function automatic [31:0] enc_r(input [6:0] funct7, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
    endfunction
    function automatic [31:0] enc_i(input integer imm, input [4:0] rs1, input [2:0] funct3, input [4:0] rd, input [6:0] opcode);
        enc_i = {imm[11:0], rs1, funct3, rd, opcode};
    endfunction
    function automatic [31:0] enc_s(input integer imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [6:0] opcode);
        enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
    endfunction
    function automatic [31:0] enc_b(input integer imm, input [4:0] rs2, input [4:0] rs1, input [2:0] funct3, input [6:0] opcode);
        enc_b = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endfunction
    function automatic [31:0] enc_u(input integer imm20, input [4:0] rd, input [6:0] opcode);
        enc_u = {imm20[19:0], rd, opcode};
    endfunction
    function automatic [31:0] enc_j(input integer imm, input [4:0] rd, input [6:0] opcode);
        enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, opcode};
    endfunction

    task expect_reg(input [4:0] idx, input [31:0] exp, input [255:0] name);
        begin
            if (uut.u_rf.regs[idx] !== exp) begin
                $display("FAIL %0s: x%0d got=%h exp=%h", name, idx, uut.u_rf.regs[idx], exp);
                $fatal;
            end else begin
                $display("PASS %0s", name);
            end
        end
    endtask

    initial begin
        // Program:
        // 0  addi x1, x0, 5
        // 1  addi x2, x0, 7
        // 2  add  x3, x1, x2
        // 3  sw   x3, 0(x0)
        // 4  lw   x4, 0(x0)
        // 5  beq  x4, x3, +8
        // 6  addi x5, x0, 1        ; skipped
        // 7  jal  x6, +8
        // 8  addi x7, x0, 99       ; skipped
        // 9  lui  x10, 0x12345
        // 10 auipc x8, 0
        // 11 nop

        uut.u_if.u_imem.mem[0]  = enc_i(5,   5'd0, 3'b000, 5'd1,  OPC_ITYPE);
        uut.u_if.u_imem.mem[1]  = enc_i(7,   5'd0, 3'b000, 5'd2,  OPC_ITYPE);
        uut.u_if.u_imem.mem[2]  = enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, OPC_RTYPE);
        uut.u_if.u_imem.mem[3]  = enc_s(0,   5'd3, 5'd0, 3'b010, OPC_STORE);
        uut.u_if.u_imem.mem[4]  = enc_i(0,   5'd0, 3'b010, 5'd4,  OPC_LOAD);
        uut.u_if.u_imem.mem[5]  = enc_b(8,   5'd3, 5'd4, 3'b000, OPC_BRANCH);
        uut.u_if.u_imem.mem[6]  = enc_i(1,   5'd0, 3'b000, 5'd5,  OPC_ITYPE);
        uut.u_if.u_imem.mem[7]  = enc_j(8,   5'd6, OPC_JAL);
        uut.u_if.u_imem.mem[8]  = enc_i(99,  5'd0, 3'b000, 5'd7,  OPC_ITYPE);
        uut.u_if.u_imem.mem[9]  = enc_u(20'h12345,            5'd10, OPC_LUI);
        uut.u_if.u_imem.mem[10] = enc_u(20'h00000,            5'd8,  OPC_AUIPC);
        uut.u_if.u_imem.mem[11] = NOP;

        #12 rst = 0;

        // chạy đủ lâu để pipeline drain
        #220;

        expect_reg(5'd1,  32'd5,          "x1=5");
        expect_reg(5'd2,  32'd7,          "x2=7");
        expect_reg(5'd3,  32'd12,         "x3=x1+x2");
        expect_reg(5'd4,  32'd12,         "x4=lw");
        expect_reg(5'd5,  32'd0,          "x5 skipped by beq");
        expect_reg(5'd6,  32'd32,         "x6=pc+4 from jal at PC=28");
        expect_reg(5'd7,  32'd0,          "x7 skipped by jal");
        expect_reg(5'd10, 32'h1234_5000,  "x10=lui");
        expect_reg(5'd8,  32'd40,         "x8=auipc at PC=40");

        if ({uut.u_mem.u_dmem.mem[3], uut.u_mem.u_dmem.mem[2], uut.u_mem.u_dmem.mem[1], uut.u_mem.u_dmem.mem[0]} !== 32'd12) begin
            $display("FAIL DMEM[0]=12");
            $fatal;
        end else begin
            $display("PASS DMEM[0]=12");
        end

        $display("tb_rv32_pipeline_top PASSED");
        $finish;
    end
endmodule
