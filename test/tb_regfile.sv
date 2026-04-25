`timescale 1ns/1ps

module tb_regfile_full;

    logic clk;
    logic rst;
    logic we;

    logic [4:0]  rs1;
    logic [4:0]  rs2;
    logic [4:0]  rd;
    logic [31:0] wd;

    wire [31:0] rd1;
    wire [31:0] rd2;

    integer tests;
    integer errors;

    regfile dut (
        .clk (clk),
        .rst (rst),
        .we  (we),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd),
        .wd  (wd),
        .rd1 (rd1),
        .rd2 (rd2)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic check32;
        input string name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-34s exp=0x%08h got=0x%08h time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-34s = 0x%08h", name, got);
            end
        end
    endtask

    task automatic write_reg;
        input [4:0]  addr;
        input [31:0] data;
        begin
            @(negedge clk);
            we = 1'b1;
            rd = addr;
            wd = data;

            @(posedge clk);
            #1;

            @(negedge clk);
            we = 1'b0;
            rd = 5'd0;
            wd = 32'h0;
        end
    endtask

    initial begin
        tests  = 0;
        errors = 0;

        rst = 1'b1;
        we  = 1'b0;
        rs1 = 5'd0;
        rs2 = 5'd0;
        rd  = 5'd0;
        wd  = 32'h0;

        $display("====================================================");
        $display(" Start regfile full test");
        $display("====================================================");

        // ========================================================
        // Case 1: reset
        // ========================================================
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        #1;

        tests = tests + 1;
        rs1 = 5'd0;
        rs2 = 5'd1;
        #1;

        $display("[CASE] Reset");
        check32("x0 after reset via rd1", rd1, 32'h0000_0000);
        check32("x1 after reset via rd2", rd2, 32'h0000_0000);

        // ========================================================
        // Case 2: write/read normal register x5
        // ========================================================
        tests = tests + 1;
        $display("[CASE] Write/read x5");

        write_reg(5'd5, 32'hDEAD_BEEF);

        rs1 = 5'd5;
        rs2 = 5'd0;
        #1;

        check32("read x5 via rd1", rd1, 32'hDEAD_BEEF);

        // ========================================================
        // Case 3: x0 hardwired zero
        // ========================================================
        tests = tests + 1;
        $display("[CASE] x0 hardwired zero");

        write_reg(5'd0, 32'hFFFF_FFFF);

        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;

        check32("read x0 via rd1", rd1, 32'h0000_0000);
        check32("read x0 via rd2", rd2, 32'h0000_0000);

        // ========================================================
        // Case 4: dual read ports
        // ========================================================
        tests = tests + 1;
        $display("[CASE] Dual read ports");

        write_reg(5'd10, 32'hAAAA_1111);
        write_reg(5'd11, 32'hBBBB_2222);

        rs1 = 5'd10;
        rs2 = 5'd11;
        #1;

        check32("rd1 reads x10", rd1, 32'hAAAA_1111);
        check32("rd2 reads x11", rd2, 32'hBBBB_2222);

        // ========================================================
        // Case 5: we = 0, không được ghi
        // ========================================================
        tests = tests + 1;
        $display("[CASE] we=0 no write");

        @(negedge clk);
        we = 1'b0;
        rd = 5'd12;
        wd = 32'h1234_5678;

        @(posedge clk);
        #1;

        rs1 = 5'd12;
        #1;

        check32("x12 unchanged when we=0", rd1, 32'h0000_0000);

        // ========================================================
        // Case 6: overwrite same register
        // ========================================================
        tests = tests + 1;
        $display("[CASE] Overwrite x13");

        write_reg(5'd13, 32'h1111_1111);
        write_reg(5'd13, 32'h2222_2222);

        rs1 = 5'd13;
        #1;

        check32("x13 overwritten", rd1, 32'h2222_2222);

        // ========================================================
        // Case 7: same-cycle read/write bypass
        // ========================================================
        tests = tests + 1;
        $display("[CASE] Same-cycle bypass");

        write_reg(5'd20, 32'h1111_AAAA);

        @(negedge clk);
        we  = 1'b1;
        rd  = 5'd20;
        wd  = 32'h2222_BBBB;
        rs1 = 5'd20;
        rs2 = 5'd20;
        #1;

        check32("bypass rd1 x20", rd1, 32'h2222_BBBB);
        check32("bypass rd2 x20", rd2, 32'h2222_BBBB);

        @(posedge clk);
        #1;

        @(negedge clk);
        we = 1'b0;

        rs1 = 5'd20;
        rs2 = 5'd20;
        #1;

        check32("x20 after bypass write rd1", rd1, 32'h2222_BBBB);
        check32("x20 after bypass write rd2", rd2, 32'h2222_BBBB);

        // ========================================================
        // Case 8: same-cycle write x0 vẫn phải ra 0
        // ========================================================
        tests = tests + 1;
        $display("[CASE] Same-cycle write x0 still zero");

        @(negedge clk);
        we  = 1'b1;
        rd  = 5'd0;
        wd  = 32'hABCD_EF01;
        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;

        check32("rd1 x0 during write x0", rd1, 32'h0000_0000);
        check32("rd2 x0 during write x0", rd2, 32'h0000_0000);

        @(posedge clk);
        #1;

        @(negedge clk);
        we = 1'b0;

        rs1 = 5'd0;
        rs2 = 5'd0;
        #1;

        check32("rd1 x0 after write x0", rd1, 32'h0000_0000);
        check32("rd2 x0 after write x0", rd2, 32'h0000_0000);

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] regfile full test passed. tests=%0d", tests);
        end else begin
            $display("[FAIL] regfile full test failed. tests=%0d errors=%0d",
                     tests, errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule