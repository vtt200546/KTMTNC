`timescale 1ns/1ps
module tb_regfile;
    reg clk = 0, rst = 1, we = 0;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] wd;
    wire [31:0] rd1, rd2;

    regfile dut (
        .clk(clk), .rst(rst), .we(we), .rs1(rs1), .rs2(rs2), .rd(rd), .wd(wd), .rd1(rd1), .rd2(rd2)
    );

    always #5 clk = ~clk;

    initial begin
        rs1 = 0; rs2 = 0; rd = 0; wd = 0;
        #12 rst = 0;

        rd = 5; wd = 32'hDEAD_BEEF; we = 1;
        #10 we = 0;

        rs1 = 5; #1;
        if (rd1 !== 32'hDEAD_BEEF) begin
            $display("FAIL reg x5 write/read");
            $fatal;
        end

        rd = 0; wd = 32'hFFFF_FFFF; we = 1;
        #10 we = 0; rs1 = 0; #1;
        if (rd1 !== 32'h0) begin
            $display("FAIL x0 must stay zero");
            $fatal;
        end

        $display("tb_regfile PASSED");
        $finish;
    end
endmodule
