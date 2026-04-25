`timescale 1ns/1ps

module tb_rv32_pipeline_top_full;

    `include "rv32_defs.vh"

    logic clk;
    logic rst;

    integer errors;
    integer cycle_count;

    bit seen_load_use_stall;
    bit seen_branch_flush;
    bit seen_jump_flush;
    bit seen_fwd_mem;
    bit seen_fwd_wb;

    rv32_pipeline_top #(
        .IMEM_DEPTH(128),
        .IMEM_INIT(""),
        .DMEM_BYTES(256),
        .DMEM_INIT("")
    ) uut (
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // Instruction encoders
    // ============================================================

    function automatic [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        input [6:0] opcode;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] enc_i;
        input [11:0] imm12;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            enc_i = {imm12, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] enc_s;
        input [11:0] imm12;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        begin
            enc_s = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], opcode};
        end
    endfunction

    function automatic [31:0] enc_b;
        input [12:0] imm13;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [6:0]  opcode;
        begin
            enc_b = {imm13[12], imm13[10:5], rs2, rs1, funct3,
                     imm13[4:1], imm13[11], opcode};
        end
    endfunction

    function automatic [31:0] enc_u;
        input [19:0] imm20;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            enc_u = {imm20, rd, opcode};
        end
    endfunction

    function automatic [31:0] enc_j;
        input [20:0] imm21;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            enc_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, opcode};
        end
    endfunction

    // ============================================================
    // Check helpers
    // ============================================================

    task automatic check32;
        input string name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-32s exp=0x%08h got=0x%08h time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-32s = 0x%08h", name, got);
            end
        end
    endtask

    task automatic check1;
        input string name;
        input bit got;
        input bit exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-32s exp=%0b got=%0b time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-32s = %0b", name, got);
            end
        end
    endtask

    task automatic expect_reg;
        input integer idx;
        input [31:0] exp;
        reg [31:0] got;
        begin
            got = uut.u_rf.regs[idx];
            check32($sformatf("x%0d", idx), got, exp);
        end
    endtask

    task automatic expect_dmem_byte;
        input integer addr;
        input [7:0] exp;
        reg [7:0] got;
        begin
            got = uut.u_mem.u_dmem.mem[addr];
            if (got !== exp) begin
                $display("[FAIL] DMEM[%0d] exp=0x%02h got=0x%02h time=%0t",
                         addr, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] DMEM[%0d] = 0x%02h", addr, got);
            end
        end
    endtask

    task automatic expect_dmem_word;
        input integer addr;
        input [31:0] exp;
        reg [31:0] got;
        begin
            got = {uut.u_mem.u_dmem.mem[addr+3],
                   uut.u_mem.u_dmem.mem[addr+2],
                   uut.u_mem.u_dmem.mem[addr+1],
                   uut.u_mem.u_dmem.mem[addr+0]};
            check32($sformatf("DMEM word @%0d", addr), got, exp);
        end
    endtask

    // ============================================================
    // Runtime monitors
    // ============================================================

    always @(posedge clk) begin
        if (rst) begin
            cycle_count         <= 0;
            seen_load_use_stall <= 1'b0;
            seen_branch_flush   <= 1'b0;
            seen_jump_flush     <= 1'b0;
            seen_fwd_mem        <= 1'b0;
            seen_fwd_wb         <= 1'b0;
        end else begin
            cycle_count <= cycle_count + 1;

            if (uut.stallF && uut.stallD)
                seen_load_use_stall <= 1'b1;

            if (uut.take_branchX && uut.branchX)
                seen_branch_flush <= 1'b1;

            if (uut.take_branchX && uut.jumpX)
                seen_jump_flush <= 1'b1;

            if ((uut.fwd_sel_a == 2'b01) || (uut.fwd_sel_b == 2'b01))
                seen_fwd_mem <= 1'b1;

            if ((uut.fwd_sel_a == 2'b10) || (uut.fwd_sel_b == 2'b10))
                seen_fwd_wb <= 1'b1;
        end
    end

    // ============================================================
    // Main
    // ============================================================

    initial begin
        errors = 0;
        rst    = 1'b1;

        $display("====================================================");
        $display(" Start rv32_pipeline_top full test");
        $display("====================================================");

        // Đợi imem/dmem initial block fill xong để tránh race tại t=0.
        #1;

        // Xóa vùng IMEM dùng cho test
        for (int i = 0; i < 128; i = i + 1) begin
            uut.u_if.u_imem.mem[i] = NOP;
        end

        // ========================================================
        // Program layout
        // PC = index * 4
        // ========================================================

        // 0:  x1 = 5
        uut.u_if.u_imem.mem[0]  = enc_i(12'd5,  5'd0, 3'b000, 5'd1,  OPC_ITYPE);

        // 1:  x2 = 7
        uut.u_if.u_imem.mem[1]  = enc_i(12'd7,  5'd0, 3'b000, 5'd2,  OPC_ITYPE);

        // 2:  x3 = x1 + x2 = 12
        //     Test forwarding ALU dependency.
        uut.u_if.u_imem.mem[2]  = enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3, OPC_RTYPE);

        // 3:  sw x3, 0(x0)
        //     Test store-data forwarding.
        uut.u_if.u_imem.mem[3]  = enc_s(12'd0, 5'd3, 5'd0, 3'b010, OPC_STORE);

        // 4:  lw x4, 0(x0) -> x4 = 12
        uut.u_if.u_imem.mem[4]  = enc_i(12'd0, 5'd0, 3'b010, 5'd4,  OPC_LOAD);

        // 5:  beq x4, x3, +8
        //     Test load-use stall + branch taken.
        //     Target = PC 20 + 8 = 28, index 7.
        uut.u_if.u_imem.mem[5]  = enc_b(13'd8, 5'd3, 5'd4, 3'b000, OPC_BRANCH);

        // 6:  should be flushed/skipped
        uut.u_if.u_imem.mem[6]  = enc_i(12'd1, 5'd0, 3'b000, 5'd5, OPC_ITYPE);

        // 7:  jal x6, +8
        //     PC=28, x6=PC+4=32, target=36 index 9.
        uut.u_if.u_imem.mem[7]  = enc_j(21'd8, 5'd6, OPC_JAL);

        // 8:  should be flushed/skipped
        uut.u_if.u_imem.mem[8]  = enc_i(12'd99, 5'd0, 3'b000, 5'd7, OPC_ITYPE);

        // 9:  lui x10, 0x12345 -> x10 = 0x12345000
        uut.u_if.u_imem.mem[9]  = enc_u(20'h12345, 5'd10, OPC_LUI);

        // 10: auipc x8, 0 -> x8 = PC = 40
        uut.u_if.u_imem.mem[10] = enc_u(20'h00000, 5'd8, OPC_AUIPC);

        // 11: sltiu x11, x1, -1
        //     Correct result: 5 <u 0xFFFF_FFFF => x11 = 1.
        //     Nếu sltiu còn dùng IMM_ZI thì case này sẽ sai.
        uut.u_if.u_imem.mem[11] = enc_i(12'hFFF, 5'd1, 3'b011, 5'd11, OPC_ITYPE);

        // 12: x21 = -44 = 0xFFFF_FFD4
        uut.u_if.u_imem.mem[12] = enc_i(12'hFD4, 5'd0, 3'b000, 5'd21, OPC_ITYPE);

        // 13: sb x21, 16(x0)
        uut.u_if.u_imem.mem[13] = enc_s(12'd16, 5'd21, 5'd0, 3'b000, OPC_STORE);

        // 14: lb x22, 16(x0) -> sign-extend 0xD4 = 0xFFFF_FFD4
        uut.u_if.u_imem.mem[14] = enc_i(12'd16, 5'd0, 3'b000, 5'd22, OPC_LOAD);

        // 15: lbu x23, 16(x0) -> 0x0000_00D4
        uut.u_if.u_imem.mem[15] = enc_i(12'd16, 5'd0, 3'b100, 5'd23, OPC_LOAD);

        // 16: x24 = -2048 = 0xFFFF_F800
        uut.u_if.u_imem.mem[16] = enc_i(12'h800, 5'd0, 3'b000, 5'd24, OPC_ITYPE);

        // 17: sh x24, 20(x0)
        uut.u_if.u_imem.mem[17] = enc_s(12'd20, 5'd24, 5'd0, 3'b001, OPC_STORE);

        // 18: lh x25, 20(x0) -> 0xFFFF_F800
        uut.u_if.u_imem.mem[18] = enc_i(12'd20, 5'd0, 3'b001, 5'd25, OPC_LOAD);

        // 19: lhu x26, 20(x0) -> 0x0000_F800
        uut.u_if.u_imem.mem[19] = enc_i(12'd20, 5'd0, 3'b101, 5'd26, OPC_LOAD);

        // 20: x14 = -1
        uut.u_if.u_imem.mem[20] = enc_i(12'hFFF, 5'd0, 3'b000, 5'd14, OPC_ITYPE);

        // 21: x15 = 1
        uut.u_if.u_imem.mem[21] = enc_i(12'd1, 5'd0, 3'b000, 5'd15, OPC_ITYPE);

        // 22: blt x14, x15, +8
        //     signed: -1 < 1, taken, skip index 23.
        uut.u_if.u_imem.mem[22] = enc_b(13'd8, 5'd15, 5'd14, 3'b100, OPC_BRANCH);

        // 23: should be skipped
        uut.u_if.u_imem.mem[23] = enc_i(12'd1, 5'd0, 3'b000, 5'd16, OPC_ITYPE);

        // 24: bltu x15, x14, +8
        //     unsigned: 1 < 0xFFFF_FFFF, taken, skip index 25.
        uut.u_if.u_imem.mem[24] = enc_b(13'd8, 5'd14, 5'd15, 3'b110, OPC_BRANCH);

        // 25: should be skipped
        uut.u_if.u_imem.mem[25] = enc_i(12'd1, 5'd0, 3'b000, 5'd17, OPC_ITYPE);

        // 26: x12 = 117
        //     Dùng cho JALR target odd: (117 + 4) & ~1 = 120.
        uut.u_if.u_imem.mem[26] = enc_i(12'd117, 5'd0, 3'b000, 5'd12, OPC_ITYPE);

        // 27: jalr x13, x12, 4
        //     PC=108, x13=112, target=120 index 30.
        //     Test JALR + forwarding rs1 cho JALR.
        uut.u_if.u_imem.mem[27] = enc_i(12'd4, 5'd12, 3'b000, 5'd13, OPC_JALR);

        // 28-29: should be flushed/skipped
        uut.u_if.u_imem.mem[28] = enc_i(12'd1, 5'd0, 3'b000, 5'd18, OPC_ITYPE);
        uut.u_if.u_imem.mem[29] = enc_i(12'd1, 5'd0, 3'b000, 5'd19, OPC_ITYPE);

        // 30: reached after JALR
        uut.u_if.u_imem.mem[30] = enc_i(12'd77, 5'd0, 3'b000, 5'd27, OPC_ITYPE);

        // 31: ECALL invalid in current subset, should behave like bubble/no side effect.
        uut.u_if.u_imem.mem[31] = 32'h0000_0073;

        // 32: must still execute after ECALL bubble.
        uut.u_if.u_imem.mem[32] = enc_i(12'd88, 5'd0, 3'b000, 5'd28, OPC_ITYPE);

        // 33+: NOPs
        uut.u_if.u_imem.mem[33] = NOP;
        uut.u_if.u_imem.mem[34] = NOP;
        uut.u_if.u_imem.mem[35] = NOP;
        uut.u_if.u_imem.mem[36] = NOP;

        // Reset phù hợp sync PC.
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        // Chạy đủ lâu để pipeline drain.
        repeat (100) @(posedge clk);
        #1;

        $display("====================================================");
        $display(" Final register checks");
        $display("====================================================");

        expect_reg(0,  32'h0000_0000);
        expect_reg(1,  32'h0000_0005);
        expect_reg(2,  32'h0000_0007);
        expect_reg(3,  32'h0000_000C);
        expect_reg(4,  32'h0000_000C);

        // Các lệnh bị branch/jump flush phải không ghi được.
        expect_reg(5,  32'h0000_0000);
        expect_reg(6,  32'h0000_0020);
        expect_reg(7,  32'h0000_0000);

        expect_reg(8,  32'h0000_0028);
        expect_reg(10, 32'h1234_5000);
        expect_reg(11, 32'h0000_0001);

        expect_reg(21, 32'hFFFF_FFD4);
        expect_reg(22, 32'hFFFF_FFD4);
        expect_reg(23, 32'h0000_00D4);
        expect_reg(24, 32'hFFFF_F800);
        expect_reg(25, 32'hFFFF_F800);
        expect_reg(26, 32'h0000_F800);

        expect_reg(14, 32'hFFFF_FFFF);
        expect_reg(15, 32'h0000_0001);

        // Các lệnh sau branch taken phải bị skip.
        expect_reg(16, 32'h0000_0000);
        expect_reg(17, 32'h0000_0000);

        // JALR
        expect_reg(12, 32'h0000_0075);
        expect_reg(13, 32'h0000_0070);
        expect_reg(18, 32'h0000_0000);
        expect_reg(19, 32'h0000_0000);
        expect_reg(27, 32'h0000_004D);

        // ECALL bubble không được chặn instruction sau nó.
        expect_reg(28, 32'h0000_0058);

        $display("====================================================");
        $display(" Final DMEM checks");
        $display("====================================================");

        expect_dmem_word(0,  32'h0000_000C);
        expect_dmem_byte(16, 8'hD4);
        expect_dmem_byte(20, 8'h00);
        expect_dmem_byte(21, 8'hF8);

        $display("====================================================");
        $display(" Internal event coverage checks");
        $display("====================================================");

        check1("seen load-use stall", seen_load_use_stall, 1'b1);
        check1("seen branch flush",   seen_branch_flush,   1'b1);
        check1("seen jump flush",     seen_jump_flush,     1'b1);
        check1("seen MEM forwarding", seen_fwd_mem,        1'b1);
        check1("seen WB forwarding",  seen_fwd_wb,         1'b1);

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] rv32_pipeline_top full test PASSED");
        end else begin
            $display("[FAIL] rv32_pipeline_top full test FAILED, errors=%0d", errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule