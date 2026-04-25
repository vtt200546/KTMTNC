`timescale 1ns/1ps

module tb_if_stage;

    logic clk;
    logic rst;
    logic stallF;
    logic pc_sel;
    logic [31:0] pc_target;

    wire [31:0] pcF;
    wire [31:0] pc4F;
    wire [31:0] instrF;

    integer errors;
    localparam string IMEM_FILE = "pro.mem";

    if_stage #(
        .IMEM_DEPTH(256),
        .IMEM_INIT(IMEM_FILE)
    ) dut (
        .clk      (clk),
        .rst      (rst),
        .stallF   (stallF),
        .pc_sel   (pc_sel),
        .pc_target(pc_target),
        .pcF      (pcF),
        .pc4F     (pc4F),
        .instrF   (instrF)
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
                $display("[FAIL] %-24s exp=0x%08h got=0x%08h time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-24s = 0x%08h", name, got);
            end
        end
    endtask

    initial begin
        errors = 0;

        stallF    = 1'b0;
        pc_sel    = 1'b0;
        pc_target = 32'h0000_0000;
        rst       = 1'b1;

        $display("====================================================");
        $display(" Start IF stage test with IMEM_INIT = %s", IMEM_FILE);
        $display("====================================================");

        // Giữ reset vài chu kỳ để chắc imem đã init xong
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;
        #1;

        // PC = 0
        check32("pcF after reset",  pcF,    32'h0000_0000);
        check32("pc4F after reset", pc4F,   32'h0000_0004);
        check32("instr PC=0",       instrF, 32'h0050_0093);

        // PC = 4
        @(posedge clk);
        #1;
        check32("pcF PC=4",         pcF,    32'h0000_0004);
        check32("pc4F PC=4",        pc4F,   32'h0000_0008);
        check32("instr PC=4",       instrF, 32'h0070_0113);

        // PC = 8
        @(posedge clk);
        #1;
        check32("pcF PC=8",         pcF,    32'h0000_0008);
        check32("pc4F PC=8",        pc4F,   32'h0000_000C);
        check32("instr PC=8",       instrF, 32'h0020_81B3);

        // Test redirect tới PC = 16
        @(negedge clk);
        pc_sel    = 1'b1;
        pc_target = 32'h0000_0010;

        @(posedge clk);
        #1;
        pc_sel = 1'b0;

        check32("pcF redirect 16",  pcF,    32'h0000_0010);
        check32("pc4F redirect 16", pc4F,   32'h0000_0014);
        check32("instr PC=16",      instrF, 32'h0000_2203);

        // Test stall: PC giữ nguyên ở 16
        @(negedge clk);
        stallF = 1'b1;

        @(posedge clk);
        #1;
        check32("pcF stall",        pcF,    32'h0000_0010);
        check32("pc4F stall",       pc4F,   32'h0000_0014);
        check32("instr stall",      instrF, 32'h0000_2203);

        // Nhả stall: PC chạy tiếp sang 20
        @(negedge clk);
        stallF = 1'b0;

        @(posedge clk);
        #1;
        check32("pcF after stall",  pcF,    32'h0000_0014);
        check32("pc4F after stall", pc4F,   32'h0000_0018);
        check32("instr PC=20",      instrF, 32'h0000_0013);

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] IF stage init-file test passed");
        end else begin
            $display("[FAIL] IF stage init-file test failed, errors=%0d", errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule