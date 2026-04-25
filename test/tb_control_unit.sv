`timescale 1ns/1ps

module tb_control_unit_full;

    `include "rv32_defs.vh"

    logic [31:0] instr;

    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic [1:0]  wb_sel;
    logic        asel_pc;
    logic        bsel_imm;
    logic [4:0]  alu_sel;
    logic [2:0]  imm_sel;
    logic [31:0] imm;
    logic        branch;
    logic        jump;
    logic        jalr;
    logic        br_un;
    logic [2:0]  branch_funct3;
    logic [2:0]  mem_funct3;
    logic        use_rs1;
    logic        use_rs2;
    logic        valid;

    integer tests;
    integer errors;

    control_unit dut (
        .instr(instr),
        .reg_write(reg_write),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .wb_sel(wb_sel),
        .asel_pc(asel_pc),
        .bsel_imm(bsel_imm),
        .alu_sel(alu_sel),
        .imm_sel(imm_sel),
        .branch(branch),
        .jump(jump),
        .jalr(jalr),
        .br_un(br_un),
        .branch_funct3(branch_funct3),
        .mem_funct3(mem_funct3),
        .use_rs1(use_rs1),
        .use_rs2(use_rs2),
        .valid(valid)
    );
    imm_gen u_imm (
    .instr(instr),
    .imm_sel(imm_sel),
    .imm(imm)
    );

    // ============================================================
    // Instruction encoders
    // ============================================================

    function automatic [31:0] enc_r;
        input [6:0] funct7;
        input [4:0] rs2;
        input [4:0] rs1;
        input [2:0] funct3;
        input [4:0] rd;
        begin
            enc_r = {funct7, rs2, rs1, funct3, rd, OPC_RTYPE};
        end
    endfunction

    function automatic [31:0] enc_i;
        input [11:0] imm;
        input [4:0]  rs1;
        input [2:0]  funct3;
        input [4:0]  rd;
        input [6:0]  opcode;
        begin
            enc_i = {imm, rs1, funct3, rd, opcode};
        end
    endfunction

    function automatic [31:0] enc_s;
        input [11:0] imm;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        begin
            enc_s = {imm[11:5], rs2, rs1, funct3, imm[4:0], OPC_STORE};
        end
    endfunction

    function automatic [31:0] enc_b;
        input [12:0] imm;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        begin
            enc_b = {imm[12], imm[10:5], rs2, rs1, funct3,
                     imm[4:1], imm[11], OPC_BRANCH};
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
        input [20:0] imm;
        input [4:0]  rd;
        begin
            enc_j = {imm[20], imm[10:1], imm[11], imm[19:12], rd, OPC_JAL};
        end
    endfunction

    // ============================================================
    // Check helper
    // ============================================================

    `define CHECK_EQ(SIG, EXP)                                                    \
        if ((SIG) !== (EXP)) begin                                                \
            $display("[FAIL] %-24s %-16s exp=0x%0h got=0x%0h instr=0x%08h",       \
                     cname, `"SIG`", (EXP), (SIG), ins);                         \
            errors = errors + 1;                                                  \
        end

    task automatic run_case;
        input string cname;
        input logic [31:0] ins;

        input logic        e_reg_write;
        input logic        e_mem_read;
        input logic        e_mem_write;
        input logic [1:0]  e_wb_sel;
        input logic        e_asel_pc;
        input logic        e_bsel_imm;
        input logic [4:0]  e_alu_sel;
        input logic [2:0]  e_imm_sel;
        input logic        e_branch;
        input logic        e_jump;
        input logic        e_jalr;
        input logic        e_br_un;
        input logic        e_use_rs1;
        input logic        e_use_rs2;
        input logic        e_valid;

        begin
            tests = tests + 1;
            instr = ins;
            #1;

            `CHECK_EQ(reg_write, e_reg_write)
            `CHECK_EQ(mem_read,  e_mem_read)
            `CHECK_EQ(mem_write, e_mem_write)
            `CHECK_EQ(wb_sel,    e_wb_sel)
            `CHECK_EQ(asel_pc,   e_asel_pc)
            `CHECK_EQ(bsel_imm,  e_bsel_imm)
            `CHECK_EQ(alu_sel,   e_alu_sel)
            `CHECK_EQ(imm_sel,   e_imm_sel)
            `CHECK_EQ(branch,    e_branch)
            `CHECK_EQ(jump,      e_jump)
            `CHECK_EQ(jalr,      e_jalr)
            `CHECK_EQ(br_un,     e_br_un)
            `CHECK_EQ(use_rs1,   e_use_rs1)
            `CHECK_EQ(use_rs2,   e_use_rs2)
            `CHECK_EQ(valid,     e_valid)

            // Trong control_unit hiện tại, 2 tín hiệu này luôn lấy trực tiếp từ instr[14:12]
            `CHECK_EQ(branch_funct3, ins[14:12])
            `CHECK_EQ(mem_funct3,    ins[14:12])
        end
    endtask

    // ============================================================
    // Main test
    // ============================================================

    initial begin
        tests  = 0;
        errors = 0;
        instr  = 32'h0000_0013; // nop = addi x0, x0, 0
        #1;

        $display("====================================================");
        $display(" Start full control_unit test");
        $display("====================================================");

        // ========================================================
        // R-TYPE
        // ========================================================

        run_case("R_ADD",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_ADD,  IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_SUB",
            enc_r(7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_SUB,  IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_SLL",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b001, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_SLL,  IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_SLT",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b010, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_SLT,  IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_SLTU",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b011, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_SLTU, IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_XOR",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b100, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_XOR,  IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_SRL",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b101, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_SRL,  IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_SRA",
            enc_r(7'b0100000, 5'd2, 5'd1, 3'b101, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_SRA,  IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_OR",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b110, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_OR,   IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("R_AND",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b111, 5'd3),
            1, 0, 0, WB_ALU, 0, 0, ALU_AND,  IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        // ========================================================
        // I-TYPE ALU
        // ========================================================

        run_case("I_ADDI",
            enc_i(12'h001, 5'd1, 3'b000, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_ADD,  IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("I_SLLI",
            enc_i({7'b0000000, 5'd4}, 5'd1, 3'b001, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_SLL,  IMM_SHAMT,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("I_SLTI",
            enc_i(12'hFFF, 5'd1, 3'b010, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_SLT,  IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("I_SLTIU",
            enc_i(12'hFFF, 5'd1, 3'b011, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_SLTU, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("I_XORI",
            enc_i(12'h0AA, 5'd1, 3'b100, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_XOR,  IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("I_SRLI",
            enc_i({7'b0000000, 5'd4}, 5'd1, 3'b101, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_SRL,  IMM_SHAMT,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("I_SRAI",
            enc_i({7'b0100000, 5'd4}, 5'd1, 3'b101, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_SRA,  IMM_SHAMT,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("I_ORI",
            enc_i(12'h055, 5'd1, 3'b110, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_OR,   IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("I_ANDI",
            enc_i(12'h0F0, 5'd1, 3'b111, 5'd2, OPC_ITYPE),
            1, 0, 0, WB_ALU, 0, 1, ALU_AND,  IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        // ========================================================
        // LOAD
        // ========================================================

        run_case("LOAD_LB",
            enc_i(12'h004, 5'd1, 3'b000, 5'd2, OPC_LOAD),
            1, 1, 0, WB_MEM, 0, 1, ALU_ADD, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("LOAD_LH",
            enc_i(12'h004, 5'd1, 3'b001, 5'd2, OPC_LOAD),
            1, 1, 0, WB_MEM, 0, 1, ALU_ADD, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("LOAD_LW",
            enc_i(12'h004, 5'd1, 3'b010, 5'd2, OPC_LOAD),
            1, 1, 0, WB_MEM, 0, 1, ALU_ADD, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("LOAD_LBU",
            enc_i(12'h004, 5'd1, 3'b100, 5'd2, OPC_LOAD),
            1, 1, 0, WB_MEM, 0, 1, ALU_ADD, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        run_case("LOAD_LHU",
            enc_i(12'h004, 5'd1, 3'b101, 5'd2, OPC_LOAD),
            1, 1, 0, WB_MEM, 0, 1, ALU_ADD, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        // ========================================================
        // STORE
        // ========================================================

        run_case("STORE_SB",
            enc_s(12'h008, 5'd2, 5'd1, 3'b000),
            0, 0, 1, WB_ALU, 0, 1, ALU_ADD, IMM_S,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("STORE_SH",
            enc_s(12'h008, 5'd2, 5'd1, 3'b001),
            0, 0, 1, WB_ALU, 0, 1, ALU_ADD, IMM_S,
            0, 0, 0, 0, 1, 1, 1
        );

        run_case("STORE_SW",
            enc_s(12'h008, 5'd2, 5'd1, 3'b010),
            0, 0, 1, WB_ALU, 0, 1, ALU_ADD, IMM_S,
            0, 0, 0, 0, 1, 1, 1
        );

        // ========================================================
        // BRANCH
        // ========================================================

        run_case("BR_BEQ",
            enc_b(13'd8, 5'd2, 5'd1, 3'b000),
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_B,
            1, 0, 0, 0, 1, 1, 1
        );

        run_case("BR_BNE",
            enc_b(13'd8, 5'd2, 5'd1, 3'b001),
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_B,
            1, 0, 0, 0, 1, 1, 1
        );

        run_case("BR_BLT",
            enc_b(13'd8, 5'd2, 5'd1, 3'b100),
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_B,
            1, 0, 0, 0, 1, 1, 1
        );

        run_case("BR_BGE",
            enc_b(13'd8, 5'd2, 5'd1, 3'b101),
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_B,
            1, 0, 0, 0, 1, 1, 1
        );

        run_case("BR_BLTU",
            enc_b(13'd8, 5'd2, 5'd1, 3'b110),
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_B,
            1, 0, 0, 1, 1, 1, 1
        );

        run_case("BR_BGEU",
            enc_b(13'd8, 5'd2, 5'd1, 3'b111),
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_B,
            1, 0, 0, 1, 1, 1, 1
        );

        // ========================================================
        // JUMP
        // ========================================================

        run_case("JAL",
            enc_j(21'd16, 5'd1),
            1, 0, 0, WB_PC4, 0, 0, ALU_ADD, IMM_J,
            0, 1, 0, 0, 0, 0, 1
        );

        run_case("JALR",
            enc_i(12'h004, 5'd1, 3'b000, 5'd2, OPC_JALR),
            1, 0, 0, WB_PC4, 0, 0, ALU_ADD, IMM_I,
            0, 1, 1, 0, 1, 0, 1
        );

        // ========================================================
        // U-TYPE
        // ========================================================

        run_case("AUIPC",
            enc_u(20'h12345, 5'd1, OPC_AUIPC),
            1, 0, 0, WB_ALU, 1, 1, ALU_ADD, IMM_U,
            0, 0, 0, 0, 0, 0, 1
        );

        run_case("LUI",
            enc_u(20'h12345, 5'd1, OPC_LUI),
            1, 0, 0, WB_ALU, 0, 1, ALU_PASSB, IMM_U,
            0, 0, 0, 0, 0, 0, 1
        );

        // ========================================================
        // SYSTEM / INVALID
        // ========================================================

        run_case("SYSTEM_ECALL",
            32'h0000_0073,
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_I,
            0, 0, 0, 0, 0, 0, 0
        );

        run_case("INVALID_OPCODE",
            {25'h0, 7'b0001011},
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_I,
            0, 0, 0, 0, 0, 0, 0
        );

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] control_unit full test passed. tests=%0d", tests);
        end else begin
            $display("[FAIL] control_unit full test failed. tests=%0d errors=%0d", tests, errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule