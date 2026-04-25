`timescale 1ns/1ps

module tb_ex_stage;

    `include "rv32_defs.vh"

    logic [31:0] pcX;
    logic [31:0] pc4X;
    logic [31:0] rs1_valX;
    logic [31:0] rs2_valX;
    logic [31:0] immX;

    logic        asel_pcX;
    logic        bsel_immX;
    logic [4:0]  alu_selX;

    logic        branchX;
    logic        jumpX;
    logic        jalrX;
    logic        br_unX;
    logic [2:0]  branch_funct3X;

    wire [31:0] alu_outX;
    wire [31:0] pc_targetX;
    wire        take_branchX;
    wire [31:0] store_dataX;
    wire [31:0] pc4_passX;
    wire        br_eqX;
    wire        br_ltX;

    integer tests;
    integer errors;

    localparam [2:0] BR_BEQ  = 3'b000;
    localparam [2:0] BR_BNE  = 3'b001;
    localparam [2:0] BR_BLT  = 3'b100;
    localparam [2:0] BR_BGE  = 3'b101;
    localparam [2:0] BR_BLTU = 3'b110;
    localparam [2:0] BR_BGEU = 3'b111;

    ex_stage dut (
        .pcX            (pcX),
        .pc4X           (pc4X),
        .rs1_valX       (rs1_valX),
        .rs2_valX       (rs2_valX),
        .immX           (immX),
        .asel_pcX       (asel_pcX),
        .bsel_immX      (bsel_immX),
        .alu_selX       (alu_selX),
        .branchX        (branchX),
        .jumpX          (jumpX),
        .jalrX          (jalrX),
        .br_unX         (br_unX),
        .branch_funct3X (branch_funct3X),
        .alu_outX       (alu_outX),
        .pc_targetX     (pc_targetX),
        .take_branchX   (take_branchX),
        .store_dataX    (store_dataX),
        .pc4_passX      (pc4_passX),
        .br_eqX         (br_eqX),
        .br_ltX         (br_ltX)
    );

    task automatic set_default;
        begin
            pcX            = 32'h0000_0100;
            pc4X           = 32'h0000_0104;
            rs1_valX       = 32'h0000_000A;
            rs2_valX       = 32'h0000_0007;
            immX           = 32'h0000_0010;

            asel_pcX       = 1'b0;
            bsel_immX      = 1'b0;
            alu_selX       = ALU_ADD;

            branchX        = 1'b0;
            jumpX          = 1'b0;
            jalrX          = 1'b0;
            br_unX         = 1'b0;
            branch_funct3X = BR_BEQ;
        end
    endtask

    task automatic check32;
        input string name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-30s exp=0x%08h got=0x%08h time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-30s = 0x%08h", name, got);
            end
        end
    endtask

    task automatic check1;
        input string name;
        input got;
        input exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-30s exp=%0b got=%0b time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-30s = %0b", name, got);
            end
        end
    endtask

    task automatic check_common_pass;
        input string cname;
        begin
            check32({cname, " store_dataX"}, store_dataX, rs2_valX);
            check32({cname, " pc4_passX"},   pc4_passX,   pc4X);
        end
    endtask

    initial begin
        tests  = 0;
        errors = 0;

        $display("====================================================");
        $display(" Start full EX stage test");
        $display("====================================================");

        // ========================================================
        // Case 1: ADD R-type: rs1 + rs2
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX  = 32'd10;
        rs2_valX  = 32'd7;
        alu_selX  = ALU_ADD;
        asel_pcX  = 1'b0;
        bsel_immX = 1'b0;
        #1;

        $display("[CASE] ADD rs1 + rs2");
        check32("ADD alu_outX", alu_outX, 32'd17);
        check1 ("ADD take_branchX", take_branchX, 1'b0);
        check_common_pass("ADD");

        // ========================================================
        // Case 2: SUB R-type: rs1 - rs2
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX = 32'd10;
        rs2_valX = 32'd7;
        alu_selX = ALU_SUB;
        #1;

        $display("[CASE] SUB rs1 - rs2");
        check32("SUB alu_outX", alu_outX, 32'd3);
        check1 ("SUB take_branchX", take_branchX, 1'b0);
        check_common_pass("SUB");

        // ========================================================
        // Case 3: ADDI / LOAD / STORE address: rs1 + imm
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX  = 32'h0000_1000;
        immX      = 32'h0000_0020;
        bsel_immX = 1'b1;
        alu_selX  = ALU_ADD;
        #1;

        $display("[CASE] ADD with immediate");
        check32("ADDI/ADDR alu_outX", alu_outX, 32'h0000_1020);
        check1 ("ADDI/ADDR take_branchX", take_branchX, 1'b0);
        check_common_pass("ADDI/ADDR");

        // ========================================================
        // Case 4: AUIPC: pc + imm
        // ========================================================
        tests = tests + 1;
        set_default();
        pcX       = 32'h0000_0100;
        immX      = 32'h1234_5000;
        asel_pcX  = 1'b1;
        bsel_immX = 1'b1;
        alu_selX  = ALU_ADD;
        #1;

        $display("[CASE] AUIPC pc + imm");
        check32("AUIPC alu_outX", alu_outX, 32'h1234_5100);
        check1 ("AUIPC take_branchX", take_branchX, 1'b0);
        check_common_pass("AUIPC");

        // ========================================================
        // Case 5: LUI: pass immediate
        // ========================================================
        tests = tests + 1;
        set_default();
        immX      = 32'h1234_5000;
        bsel_immX = 1'b1;
        alu_selX  = ALU_PASSB;
        #1;

        $display("[CASE] LUI pass imm");
        check32("LUI alu_outX", alu_outX, 32'h1234_5000);
        check1 ("LUI take_branchX", take_branchX, 1'b0);
        check_common_pass("LUI");

        // ========================================================
        // Case 6: BEQ taken
        // ========================================================
        tests = tests + 1;
        set_default();
        pcX            = 32'h0000_0100;
        immX           = 32'h0000_0010;
        rs1_valX       = 32'h0000_0055;
        rs2_valX       = 32'h0000_0055;
        branchX        = 1'b1;
        branch_funct3X = BR_BEQ;
        br_unX         = 1'b0;
        #1;

        $display("[CASE] BEQ taken");
        check1 ("BEQ br_eqX",       br_eqX,       1'b1);
        check1 ("BEQ take_branchX", take_branchX, 1'b1);
        check32("BEQ pc_targetX",   pc_targetX,   32'h0000_0110);
        check_common_pass("BEQ");

        // ========================================================
        // Case 7: BEQ not taken
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX       = 32'd1;
        rs2_valX       = 32'd2;
        branchX        = 1'b1;
        branch_funct3X = BR_BEQ;
        br_unX         = 1'b0;
        #1;

        $display("[CASE] BEQ not taken");
        check1 ("BEQ_NT br_eqX",       br_eqX,       1'b0);
        check1 ("BEQ_NT take_branchX", take_branchX, 1'b0);

        // ========================================================
        // Case 8: BNE taken
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX       = 32'd1;
        rs2_valX       = 32'd2;
        branchX        = 1'b1;
        branch_funct3X = BR_BNE;
        br_unX         = 1'b0;
        #1;

        $display("[CASE] BNE taken");
        check1 ("BNE br_eqX",       br_eqX,       1'b0);
        check1 ("BNE take_branchX", take_branchX, 1'b1);
        check32("BNE pc_targetX",   pc_targetX,   32'h0000_0110);

        // ========================================================
        // Case 9: BLT signed taken: -2 < 1
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX       = 32'hFFFF_FFFE; // -2 signed
        rs2_valX       = 32'h0000_0001; // 1
        branchX        = 1'b1;
        branch_funct3X = BR_BLT;
        br_unX         = 1'b0;
        #1;

        $display("[CASE] BLT signed taken");
        check1 ("BLT br_ltX",       br_ltX,       1'b1);
        check1 ("BLT take_branchX", take_branchX, 1'b1);

        // ========================================================
        // Case 10: BGE signed taken: 5 >= 1
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX       = 32'd5;
        rs2_valX       = 32'd1;
        branchX        = 1'b1;
        branch_funct3X = BR_BGE;
        br_unX         = 1'b0;
        #1;

        $display("[CASE] BGE signed taken");
        check1 ("BGE br_ltX",       br_ltX,       1'b0);
        check1 ("BGE take_branchX", take_branchX, 1'b1);

        // ========================================================
        // Case 11: BLTU unsigned taken: 1 < 0xFFFF_FFFF
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX       = 32'h0000_0001;
        rs2_valX       = 32'hFFFF_FFFF;
        branchX        = 1'b1;
        branch_funct3X = BR_BLTU;
        br_unX         = 1'b1;
        #1;

        $display("[CASE] BLTU unsigned taken");
        check1 ("BLTU br_ltX",       br_ltX,       1'b1);
        check1 ("BLTU take_branchX", take_branchX, 1'b1);

        // ========================================================
        // Case 12: BGEU unsigned taken: 0xFFFF_FFFF >= 1
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX       = 32'hFFFF_FFFF;
        rs2_valX       = 32'h0000_0001;
        branchX        = 1'b1;
        branch_funct3X = BR_BGEU;
        br_unX         = 1'b1;
        #1;

        $display("[CASE] BGEU unsigned taken");
        check1 ("BGEU br_ltX",       br_ltX,       1'b0);
        check1 ("BGEU take_branchX", take_branchX, 1'b1);

        // ========================================================
        // Case 13: JAL
        // target = pc + imm
        // ========================================================
        tests = tests + 1;
        set_default();
        pcX   = 32'h0000_0100;
        immX  = 32'h0000_0020;
        jumpX = 1'b1;
        jalrX = 1'b0;
        #1;

        $display("[CASE] JAL");
        check1 ("JAL take_branchX", take_branchX, 1'b1);
        check32("JAL pc_targetX",   pc_targetX,   32'h0000_0120);
        check32("JAL pc4_passX",    pc4_passX,    32'h0000_0104);

        // ========================================================
        // Case 14: JALR
        // target = (rs1 + imm) & ~1
        // ========================================================
        tests = tests + 1;
        set_default();
        rs1_valX = 32'h0000_0201;
        immX     = 32'h0000_0008;
        jumpX    = 1'b1;
        jalrX    = 1'b1;
        #1;

        $display("[CASE] JALR");
        check1 ("JALR take_branchX", take_branchX, 1'b1);
        check32("JALR pc_targetX",   pc_targetX,   32'h0000_0208);
        check32("JALR pc4_passX",    pc4_passX,    32'h0000_0104);

        // ========================================================
        // Case 15: No branch, no jump
        // ========================================================
        tests = tests + 1;
        set_default();
        branchX = 1'b0;
        jumpX   = 1'b0;
        jalrX   = 1'b0;
        #1;

        $display("[CASE] No branch/jump");
        check1 ("NO_CTRL take_branchX", take_branchX, 1'b0);

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] EX stage full test passed. tests=%0d", tests);
        end else begin
            $display("[FAIL] EX stage full test failed. tests=%0d errors=%0d", tests, errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule