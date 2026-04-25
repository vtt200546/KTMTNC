`timescale 1ns/1ps

module tb_id_stage;

    `include "rv32_defs.vh"

    logic [31:0] instrD;
    logic [31:0] pcD;
    logic [31:0] pc4D;
    logic [31:0] rs1_dataD;
    logic [31:0] rs2_dataD;

    wire [4:0]  rs1_addrD;
    wire [4:0]  rs2_addrD;
    wire [4:0]  rd_addrD;
    wire [31:0] immD;
    wire [31:0] d1D;
    wire [31:0] d2D;
    wire [31:0] pc_outD;
    wire [31:0] pc4_outD;

    wire        reg_writeD;
    wire        mem_readD;
    wire        mem_writeD;
    wire [1:0]  wb_selD;
    wire        asel_pcD;
    wire        bsel_immD;
    wire [4:0]  alu_selD;
    wire [2:0]  imm_selD;
    wire        branchD;
    wire        jumpD;
    wire        jalrD;
    wire        br_unD;
    wire [2:0]  branch_funct3D;
    wire [2:0]  mem_funct3D;
    wire        use_rs1D;
    wire        use_rs2D;
    wire        validD;

    integer tests;
    integer errors;

    id_stage dut (
        .instrD          (instrD),
        .pcD             (pcD),
        .pc4D            (pc4D),
        .rs1_dataD       (rs1_dataD),
        .rs2_dataD       (rs2_dataD),

        .rs1_addrD       (rs1_addrD),
        .rs2_addrD       (rs2_addrD),
        .rd_addrD        (rd_addrD),
        .immD            (immD),
        .d1D             (d1D),
        .d2D             (d2D),
        .pc_outD         (pc_outD),
        .pc4_outD        (pc4_outD),

        .reg_writeD      (reg_writeD),
        .mem_readD       (mem_readD),
        .mem_writeD      (mem_writeD),
        .wb_selD         (wb_selD),
        .asel_pcD        (asel_pcD),
        .bsel_immD       (bsel_immD),
        .alu_selD        (alu_selD),
        .imm_selD        (imm_selD),
        .branchD         (branchD),
        .jumpD           (jumpD),
        .jalrD           (jalrD),
        .br_unD          (br_unD),
        .branch_funct3D  (branch_funct3D),
        .mem_funct3D     (mem_funct3D),
        .use_rs1D        (use_rs1D),
        .use_rs2D        (use_rs2D),
        .validD          (validD)
    );

    // ============================================================
    // Encoders
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
        begin
            enc_s = {imm12[11:5], rs2, rs1, funct3, imm12[4:0], OPC_STORE};
        end
    endfunction

    function automatic [31:0] enc_b;
        input [12:0] imm13;
        input [4:0]  rs2;
        input [4:0]  rs1;
        input [2:0]  funct3;
        begin
            enc_b = {imm13[12], imm13[10:5], rs2, rs1, funct3,
                     imm13[4:1], imm13[11], OPC_BRANCH};
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
        begin
            enc_j = {imm21[20], imm21[10:1], imm21[11], imm21[19:12], rd, OPC_JAL};
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
                $display("[FAIL] %-28s exp=0x%08h got=0x%08h instr=0x%08h",
                         name, exp, got, instrD);
                errors = errors + 1;
            end
        end
    endtask

    task automatic check5;
        input string name;
        input [4:0] got;
        input [4:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-28s exp=0x%0h got=0x%0h instr=0x%08h",
                         name, exp, got, instrD);
                errors = errors + 1;
            end
        end
    endtask

    task automatic check3;
        input string name;
        input [2:0] got;
        input [2:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-28s exp=0x%0h got=0x%0h instr=0x%08h",
                         name, exp, got, instrD);
                errors = errors + 1;
            end
        end
    endtask

    task automatic check2;
        input string name;
        input [1:0] got;
        input [1:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-28s exp=0x%0h got=0x%0h instr=0x%08h",
                         name, exp, got, instrD);
                errors = errors + 1;
            end
        end
    endtask

    task automatic check1;
        input string name;
        input got;
        input exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-28s exp=%0b got=%0b instr=0x%08h",
                         name, exp, got, instrD);
                errors = errors + 1;
            end
        end
    endtask

    // ============================================================
    // Main case checker
    // ============================================================

    task automatic run_case;
        input string cname;
        input [31:0] ins;

        input [4:0]  e_rs1;
        input [4:0]  e_rs2;
        input [4:0]  e_rd;
        input [31:0] e_imm;

        input        e_reg_write;
        input        e_mem_read;
        input        e_mem_write;
        input [1:0]  e_wb_sel;
        input        e_asel_pc;
        input        e_bsel_imm;
        input [4:0]  e_alu_sel;
        input [2:0]  e_imm_sel;
        input        e_branch;
        input        e_jump;
        input        e_jalr;
        input        e_br_un;
        input        e_use_rs1;
        input        e_use_rs2;
        input        e_valid;

        begin
            tests = tests + 1;

            instrD    = ins;
            pcD       = 32'h0000_0100;
            pc4D      = 32'h0000_0104;
            rs1_dataD = 32'hAAAA_1111;
            rs2_dataD = 32'hBBBB_2222;
            #1;

            $display("[CASE] %s instr=0x%08h", cname, instrD);

            // Field extraction
            check5 ({cname, " rs1_addrD"}, rs1_addrD, e_rs1);
            check5 ({cname, " rs2_addrD"}, rs2_addrD, e_rs2);
            check5 ({cname, " rd_addrD"},  rd_addrD,  e_rd);

            // Immediate
            check32({cname, " immD"},      immD,      e_imm);

            // Pass-through data
            check32({cname, " d1D"},       d1D,       32'hAAAA_1111);
            check32({cname, " d2D"},       d2D,       32'hBBBB_2222);
            check32({cname, " pc_outD"},   pc_outD,   32'h0000_0100);
            check32({cname, " pc4_outD"},  pc4_outD,  32'h0000_0104);

            // Control signals
            check1 ({cname, " reg_writeD"}, reg_writeD, e_reg_write);
            check1 ({cname, " mem_readD"},  mem_readD,  e_mem_read);
            check1 ({cname, " mem_writeD"}, mem_writeD, e_mem_write);
            check2 ({cname, " wb_selD"},    wb_selD,    e_wb_sel);
            check1 ({cname, " asel_pcD"},   asel_pcD,   e_asel_pc);
            check1 ({cname, " bsel_immD"},  bsel_immD,  e_bsel_imm);
            check5 ({cname, " alu_selD"},   alu_selD,   e_alu_sel);
            check3 ({cname, " imm_selD"},   imm_selD,   e_imm_sel);
            check1 ({cname, " branchD"},    branchD,    e_branch);
            check1 ({cname, " jumpD"},      jumpD,      e_jump);
            check1 ({cname, " jalrD"},      jalrD,      e_jalr);
            check1 ({cname, " br_unD"},     br_unD,     e_br_un);
            check1 ({cname, " use_rs1D"},   use_rs1D,   e_use_rs1);
            check1 ({cname, " use_rs2D"},   use_rs2D,   e_use_rs2);
            check1 ({cname, " validD"},     validD,     e_valid);

            check3 ({cname, " branch_funct3D"}, branch_funct3D, ins[14:12]);
            check3 ({cname, " mem_funct3D"},    mem_funct3D,    ins[14:12]);
        end
    endtask

    initial begin
        tests  = 0;
        errors = 0;

        $display("====================================================");
        $display(" Start full ID stage test");
        $display("====================================================");

        // R-type ADD: add x3, x1, x2
        run_case("R_ADD",
            enc_r(7'b0000000, 5'd2, 5'd1, 3'b000, 5'd3),
            5'd1, 5'd2, 5'd3, 32'h0000_0002,
            1, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        // R-type SUB
        run_case("R_SUB",
            enc_r(7'b0100000, 5'd2, 5'd1, 3'b000, 5'd3),
            5'd1, 5'd2, 5'd3, 32'h0000_0402, // immD không dùng cho R-type, nhưng imm_gen vẫn nhìn instr[31:20]
            1, 0, 0, WB_ALU, 0, 0, ALU_SUB, IMM_I,
            0, 0, 0, 0, 1, 1, 1
        );

        // I-type ADDI: addi x2, x1, 1
        run_case("I_ADDI",
            enc_i(12'h001, 5'd1, 3'b000, 5'd2, OPC_ITYPE),
            5'd1, 5'd1, 5'd2, 32'h0000_0001,
            1, 0, 0, WB_ALU, 0, 1, ALU_ADD, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        // I-type SLTIU negative immediate: sltiu x2, x1, -1
        // Đây là case quan trọng: immD phải là 0xFFFF_FFFF, không phải 0x0000_0FFF
        run_case("I_SLTIU_NEG1",
            enc_i(12'hFFF, 5'd1, 3'b011, 5'd2, OPC_ITYPE),
            5'd1, 5'd31, 5'd2, 32'hFFFF_FFFF,
            1, 0, 0, WB_ALU, 0, 1, ALU_SLTU, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        // Shift immediate: slli x2, x1, 5
        run_case("I_SLLI",
            enc_i({7'b0000000, 5'd5}, 5'd1, 3'b001, 5'd2, OPC_ITYPE),
            5'd1, 5'd5, 5'd2, 32'h0000_0005,
            1, 0, 0, WB_ALU, 0, 1, ALU_SLL, IMM_SHAMT,
            0, 0, 0, 0, 1, 0, 1
        );

        // LOAD: lw x4, 8(x1)
        run_case("LOAD_LW",
            enc_i(12'h008, 5'd1, 3'b010, 5'd4, OPC_LOAD),
            5'd1, 5'd8, 5'd4, 32'h0000_0008,
            1, 1, 0, WB_MEM, 0, 1, ALU_ADD, IMM_I,
            0, 0, 0, 0, 1, 0, 1
        );

        // STORE: sw x2, -4(x1)
        run_case("STORE_SW_NEG4",
            enc_s(12'hFFC, 5'd2, 5'd1, 3'b010),
            5'd1, 5'd2, 5'd28, 32'hFFFF_FFFC, // rd field không dùng, nhưng field instr[11:7] vẫn tồn tại
            0, 0, 1, WB_ALU, 0, 1, ALU_ADD, IMM_S,
            0, 0, 0, 0, 1, 1, 1
        );

        // BRANCH: beq x1, x2, +8
        run_case("BR_BEQ_POS8",
            enc_b(13'd8, 5'd2, 5'd1, 3'b000),
            5'd1, 5'd2, 5'd8, 32'h0000_0008,
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_B,
            1, 0, 0, 0, 1, 1, 1
        );

        // BRANCH unsigned: bltu x1, x2, +8
        run_case("BR_BLTU_POS8",
            enc_b(13'd8, 5'd2, 5'd1, 3'b110),
            5'd1, 5'd2, 5'd8, 32'h0000_0008,
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_B,
            1, 0, 0, 1, 1, 1, 1
        );

        // JAL: jal x5, +16
        run_case("JAL_POS16",
            enc_j(21'd16, 5'd5),
            5'd0, 5'd16, 5'd5, 32'h0000_0010,
            1, 0, 0, WB_PC4, 0, 0, ALU_ADD, IMM_J,
            0, 1, 0, 0, 0, 0, 1
        );

        // JALR: jalr x5, x1, 4
        run_case("JALR",
            enc_i(12'h004, 5'd1, 3'b000, 5'd5, OPC_JALR),
            5'd1, 5'd4, 5'd5, 32'h0000_0004,
            1, 0, 0, WB_PC4, 0, 0, ALU_ADD, IMM_I,
            0, 1, 1, 0, 1, 0, 1
        );

        // LUI: lui x6, 0x12345
        run_case("LUI",
            enc_u(20'h12345, 5'd6, OPC_LUI),
            5'd8, 5'd3, 5'd6, 32'h1234_5000,
            1, 0, 0, WB_ALU, 0, 1, ALU_PASSB, IMM_U,
            0, 0, 0, 0, 0, 0, 1
        );

        // AUIPC: auipc x7, 0x12345
        run_case("AUIPC",
            enc_u(20'h12345, 5'd7, OPC_AUIPC),
            5'd8, 5'd3, 5'd7, 32'h1234_5000,
            1, 0, 0, WB_ALU, 1, 1, ALU_ADD, IMM_U,
            0, 0, 0, 0, 0, 0, 1
        );

        // SYSTEM/ECALL: invalid in your current subset
        run_case("ECALL_INVALID",
            32'h0000_0073,
            5'd0, 5'd0, 5'd0, 32'h0000_0000,
            0, 0, 0, WB_ALU, 0, 0, ALU_ADD, IMM_I,
            0, 0, 0, 0, 0, 0, 0
        );

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] ID stage full test passed. tests=%0d", tests);
        end else begin
            $display("[FAIL] ID stage full test failed. tests=%0d errors=%0d", tests, errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule