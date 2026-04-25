`timescale 1ns/1ps

module tb_hazard_unit_full;

    logic        mem_readX;
    logic [4:0]  rdX;

    logic        use_rs1D;
    logic        use_rs2D;
    logic [4:0]  rs1_addrD;
    logic [4:0]  rs2_addrD;

    logic [4:0]  rs1_addrX;
    logic [4:0]  rs2_addrX;

    logic        reg_writeM;
    logic [4:0]  rdM;

    logic        reg_writeW;
    logic [4:0]  rdW;

    wire         stallF;
    wire         stallD;
    wire         flushX;
    wire [1:0]   fwd_sel_a;
    wire [1:0]   fwd_sel_b;

    integer tests;
    integer errors;

    localparam [1:0] FWD_NONE = 2'b00;
    localparam [1:0] FWD_MEM  = 2'b01;
    localparam [1:0] FWD_WB   = 2'b10;

    hazard_unit dut (
        .mem_readX  (mem_readX),
        .rdX        (rdX),

        .use_rs1D   (use_rs1D),
        .use_rs2D   (use_rs2D),
        .rs1_addrD  (rs1_addrD),
        .rs2_addrD  (rs2_addrD),

        .rs1_addrX  (rs1_addrX),
        .rs2_addrX  (rs2_addrX),

        .reg_writeM (reg_writeM),
        .rdM        (rdM),

        .reg_writeW (reg_writeW),
        .rdW        (rdW),

        .stallF     (stallF),
        .stallD     (stallD),
        .flushX     (flushX),

        .fwd_sel_a  (fwd_sel_a),
        .fwd_sel_b  (fwd_sel_b)
    );

    task automatic set_default;
        begin
            mem_readX  = 1'b0;
            rdX        = 5'd0;

            use_rs1D   = 1'b0;
            use_rs2D   = 1'b0;
            rs1_addrD  = 5'd0;
            rs2_addrD  = 5'd0;

            rs1_addrX  = 5'd0;
            rs2_addrX  = 5'd0;

            reg_writeM = 1'b0;
            rdM        = 5'd0;

            reg_writeW = 1'b0;
            rdW        = 5'd0;
        end
    endtask

    task automatic check1;
        input string name;
        input logic got;
        input logic exp;
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

    task automatic check2;
        input string name;
        input logic [1:0] got;
        input logic [1:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-32s exp=%02b got=%02b time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-32s = %02b", name, got);
            end
        end
    endtask

    task automatic check_all;
        input string cname;
        input logic e_stallF;
        input logic e_stallD;
        input logic e_flushX;
        input logic [1:0] e_fwd_a;
        input logic [1:0] e_fwd_b;
        begin
            #1;
            tests = tests + 1;

            $display("[CASE] %s", cname);

            check1({cname, " stallF"},    stallF,    e_stallF);
            check1({cname, " stallD"},    stallD,    e_stallD);
            check1({cname, " flushX"},    flushX,    e_flushX);
            check2({cname, " fwd_sel_a"}, fwd_sel_a, e_fwd_a);
            check2({cname, " fwd_sel_b"}, fwd_sel_b, e_fwd_b);
        end
    endtask

    initial begin
        tests  = 0;
        errors = 0;

        $display("====================================================");
        $display(" Start hazard_unit full test");
        $display("====================================================");

        // ========================================================
        // Case 1: No hazard
        // Không load-use, không forwarding.
        // ========================================================
        set_default();
        rs1_addrD = 5'd1;
        rs2_addrD = 5'd2;
        rs1_addrX = 5'd3;
        rs2_addrX = 5'd4;
        check_all(
            "NO_HAZARD",
            1'b0, 1'b0, 1'b0,
            FWD_NONE, FWD_NONE
        );

        // ========================================================
        // Case 2: Load-use hazard qua rs1D
        // Lệnh ở EX là load rdX = x5.
        // Lệnh ở ID cần đọc rs1D = x5.
        // Phải stall IF/ID và flush EX.
        // ========================================================
        set_default();
        mem_readX = 1'b1;
        rdX       = 5'd5;

        use_rs1D  = 1'b1;
        use_rs2D  = 1'b0;
        rs1_addrD = 5'd5;
        rs2_addrD = 5'd9;

        check_all(
            "LOAD_USE_RS1D",
            1'b1, 1'b1, 1'b1,
            FWD_NONE, FWD_NONE
        );

        // ========================================================
        // Case 3: Load-use hazard qua rs2D
        // Lệnh ở ID cần đọc rs2D = rdX.
        // ========================================================
        set_default();
        mem_readX = 1'b1;
        rdX       = 5'd6;

        use_rs1D  = 1'b0;
        use_rs2D  = 1'b1;
        rs1_addrD = 5'd1;
        rs2_addrD = 5'd6;

        check_all(
            "LOAD_USE_RS2D",
            1'b1, 1'b1, 1'b1,
            FWD_NONE, FWD_NONE
        );

        // ========================================================
        // Case 4: rdX match rs1D nhưng use_rs1D = 0
        // Không được stall vì instruction ID không thật sự dùng rs1.
        // Ví dụ JAL hoặc LUI không dùng rs1.
        // ========================================================
        set_default();
        mem_readX = 1'b1;
        rdX       = 5'd5;

        use_rs1D  = 1'b0;
        use_rs2D  = 1'b0;
        rs1_addrD = 5'd5;
        rs2_addrD = 5'd5;

        check_all(
            "LOAD_MATCH_BUT_UNUSED",
            1'b0, 1'b0, 1'b0,
            FWD_NONE, FWD_NONE
        );

        // ========================================================
        // Case 5: rdX = x0
        // Dù mem_readX = 1 và rs1D/rs2D = x0, không được stall
        // vì x0 không có dependency thật.
        // ========================================================
        set_default();
        mem_readX = 1'b1;
        rdX       = 5'd0;

        use_rs1D  = 1'b1;
        use_rs2D  = 1'b1;
        rs1_addrD = 5'd0;
        rs2_addrD = 5'd0;

        check_all(
            "LOAD_RD_X0_NO_STALL",
            1'b0, 1'b0, 1'b0,
            FWD_NONE, FWD_NONE
        );

        // ========================================================
        // Case 6: Forward A từ MEM stage
        // EX.rs1 = rdM, và M sẽ ghi register.
        // fwd_sel_a phải = 01.
        // ========================================================
        set_default();
        rs1_addrX  = 5'd8;
        rs2_addrX  = 5'd2;

        reg_writeM = 1'b1;
        rdM        = 5'd8;

        reg_writeW = 1'b0;
        rdW        = 5'd0;

        check_all(
            "FWD_A_FROM_MEM",
            1'b0, 1'b0, 1'b0,
            FWD_MEM, FWD_NONE
        );

        // ========================================================
        // Case 7: Forward A từ WB stage
        // EX.rs1 = rdW, và W sẽ ghi register.
        // fwd_sel_a phải = 10.
        // ========================================================
        set_default();
        rs1_addrX  = 5'd9;
        rs2_addrX  = 5'd2;

        reg_writeM = 1'b0;
        rdM        = 5'd0;

        reg_writeW = 1'b1;
        rdW        = 5'd9;

        check_all(
            "FWD_A_FROM_WB",
            1'b0, 1'b0, 1'b0,
            FWD_WB, FWD_NONE
        );

        // ========================================================
        // Case 8: Forward B từ MEM stage
        // EX.rs2 = rdM.
        // ========================================================
        set_default();
        rs1_addrX  = 5'd1;
        rs2_addrX  = 5'd10;

        reg_writeM = 1'b1;
        rdM        = 5'd10;

        check_all(
            "FWD_B_FROM_MEM",
            1'b0, 1'b0, 1'b0,
            FWD_NONE, FWD_MEM
        );

        // ========================================================
        // Case 9: Forward B từ WB stage
        // EX.rs2 = rdW.
        // ========================================================
        set_default();
        rs1_addrX  = 5'd1;
        rs2_addrX  = 5'd11;

        reg_writeW = 1'b1;
        rdW        = 5'd11;

        check_all(
            "FWD_B_FROM_WB",
            1'b0, 1'b0, 1'b0,
            FWD_NONE, FWD_WB
        );

        // ========================================================
        // Case 10: MEM priority hơn WB cho operand A
        // Cả rdM và rdW đều match rs1X.
        // Phải chọn MEM vì dữ liệu gần nhất nằm ở MEM.
        // ========================================================
        set_default();
        rs1_addrX  = 5'd12;
        rs2_addrX  = 5'd2;

        reg_writeM = 1'b1;
        rdM        = 5'd12;

        reg_writeW = 1'b1;
        rdW        = 5'd12;

        check_all(
            "FWD_A_MEM_PRIORITY",
            1'b0, 1'b0, 1'b0,
            FWD_MEM, FWD_NONE
        );

        // ========================================================
        // Case 11: MEM priority hơn WB cho operand B
        // ========================================================
        set_default();
        rs1_addrX  = 5'd1;
        rs2_addrX  = 5'd13;

        reg_writeM = 1'b1;
        rdM        = 5'd13;

        reg_writeW = 1'b1;
        rdW        = 5'd13;

        check_all(
            "FWD_B_MEM_PRIORITY",
            1'b0, 1'b0, 1'b0,
            FWD_NONE, FWD_MEM
        );

        // ========================================================
        // Case 12: rdM = x0, không được forward
        // ========================================================
        set_default();
        rs1_addrX  = 5'd0;
        rs2_addrX  = 5'd0;

        reg_writeM = 1'b1;
        rdM        = 5'd0;

        reg_writeW = 1'b1;
        rdW        = 5'd0;

        check_all(
            "FWD_X0_NO_FORWARD",
            1'b0, 1'b0, 1'b0,
            FWD_NONE, FWD_NONE
        );

        // ========================================================
        // Case 13: Load-use hazard và forwarding cùng lúc
        // Load-use vẫn phải tạo stall/flush.
        // Forwarding cho EX operand vẫn độc lập.
        // ========================================================
        set_default();

        // Load-use ở ID
        mem_readX = 1'b1;
        rdX       = 5'd14;
        use_rs1D  = 1'b1;
        rs1_addrD = 5'd14;

        // Forwarding cho instruction đang ở EX
        rs1_addrX  = 5'd15;
        rs2_addrX  = 5'd16;

        reg_writeM = 1'b1;
        rdM        = 5'd15;

        reg_writeW = 1'b1;
        rdW        = 5'd16;

        check_all(
            "LOAD_USE_AND_FORWARD",
            1'b1, 1'b1, 1'b1,
            FWD_MEM, FWD_WB
        );

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] hazard_unit full test passed. tests=%0d", tests);
        end else begin
            $display("[FAIL] hazard_unit full test failed. tests=%0d errors=%0d",
                     tests, errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule