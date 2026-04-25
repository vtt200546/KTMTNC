`timescale 1ns/1ps

module tb_wb_stage_full;

    `include "rv32_defs.vh"

    logic [31:0] aluW;
    logic [31:0] memW;
    logic [31:0] pc4W;
    logic [1:0]  wb_selW;

    wire [31:0] wb_dataW;

    integer tests;
    integer errors;

    wb_stage dut (
        .aluW     (aluW),
        .memW     (memW),
        .pc4W     (pc4W),
        .wb_selW  (wb_selW),
        .wb_dataW (wb_dataW)
    );

    task automatic check32;
        input string name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-24s exp=0x%08h got=0x%08h time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-24s = 0x%08h", name, got);
            end
        end
    endtask

    task automatic run_case;
        input string cname;
        input [31:0] i_aluW;
        input [31:0] i_memW;
        input [31:0] i_pc4W;
        input [1:0]  i_wb_selW;
        input [31:0] e_wb_dataW;
        begin
            tests = tests + 1;

            aluW    = i_aluW;
            memW    = i_memW;
            pc4W    = i_pc4W;
            wb_selW = i_wb_selW;
            #1;

            $display("[CASE] %s", cname);
            check32({cname, " wb_dataW"}, wb_dataW, e_wb_dataW);
        end
    endtask

    initial begin
        tests  = 0;
        errors = 0;

        aluW    = 32'h0;
        memW    = 32'h0;
        pc4W    = 32'h0;
        wb_selW = WB_ALU;
        #1;

        $display("====================================================");
        $display(" Start WB stage full test");
        $display("====================================================");

        // ========================================================
        // Case 1: Write-back from ALU
        // Dùng cho R-type, I-type ALU, LUI, AUIPC...
        // ========================================================
        run_case(
            "WB_ALU",
            32'h1111_AAAA,
            32'h2222_BBBB,
            32'h3333_CCCC,
            WB_ALU,
            32'h1111_AAAA
        );

        // ========================================================
        // Case 2: Write-back from memory
        // Dùng cho load instruction: lb/lh/lw/lbu/lhu
        // ========================================================
        run_case(
            "WB_MEM",
            32'h1111_AAAA,
            32'h2222_BBBB,
            32'h3333_CCCC,
            WB_MEM,
            32'h2222_BBBB
        );

        // ========================================================
        // Case 3: Write-back from PC+4
        // Dùng cho JAL / JALR ghi return address vào rd
        // ========================================================
        run_case(
            "WB_PC4",
            32'h1111_AAAA,
            32'h2222_BBBB,
            32'h3333_CCCC,
            WB_PC4,
            32'h3333_CCCC
        );

        // ========================================================
        // Case 4: Đổi bộ dữ liệu khác để chắc mux không bị hard-code
        // ========================================================
        run_case(
            "WB_ALU_SET2",
            32'hDEAD_BEEF,
            32'hCAFE_BABE,
            32'h0000_0104,
            WB_ALU,
            32'hDEAD_BEEF
        );

        run_case(
            "WB_MEM_SET2",
            32'hDEAD_BEEF,
            32'hCAFE_BABE,
            32'h0000_0104,
            WB_MEM,
            32'hCAFE_BABE
        );

        run_case(
            "WB_PC4_SET2",
            32'hDEAD_BEEF,
            32'hCAFE_BABE,
            32'h0000_0104,
            WB_PC4,
            32'h0000_0104
        );

        // ========================================================
        // Case 5: Default/invalid wb_selW
        // Nếu rv32_defs.vh chỉ định nghĩa 3 giá trị, giá trị còn lại nên về 0
        // hoặc theo default trong RTL của bạn.
        // Nếu wb_stage.v default chọn ALU thì sửa expected thành aluW.
        // ========================================================
        run_case(
            "WB_INVALID_SEL",
            32'hAAAA_AAAA,
            32'hBBBB_BBBB,
            32'hCCCC_CCCC,
            2'b11,
            32'h0000_0000
        );

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] WB stage full test passed. tests=%0d", tests);
        end else begin
            $display("[FAIL] WB stage full test failed. tests=%0d errors=%0d",
                     tests, errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule