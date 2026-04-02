`timescale 1ns/1ps
module tb_alu;
    `include "rv32_defs.vh"

    reg  [31:0] a, b;
    reg  [4:0]  alu_sel;
    wire [31:0] y;

    alu dut (.a(a), .b(b), .alu_sel(alu_sel), .y(y));

    task check(input [255:0] name, input [31:0] exp);
        begin
            #1;
            if (y !== exp) begin
                $display("FAIL %0s: got=%h exp=%h", name, y, exp);
                $fatal;
            end else begin
                $display("PASS %0s", name);
            end
        end
    endtask

    initial begin
        a = 32'd10; b = 32'd3; alu_sel = ALU_ADD;  check("ADD",  32'd13);
        alu_sel = ALU_SUB;  check("SUB",  32'd7);
        alu_sel = ALU_AND;  check("AND",  (32'd10 & 32'd3));
        alu_sel = ALU_OR;   check("OR",   (32'd10 | 32'd3));
        alu_sel = ALU_XOR;  check("XOR",  (32'd10 ^ 32'd3));
        alu_sel = ALU_SLL;  check("SLL",  (32'd10 << 3));
        alu_sel = ALU_SRL;  check("SRL",  (32'd10 >> 3));
        a = 32'hFFFF_FFF0; b = 32'd2; alu_sel = ALU_SRA; check("SRA", 32'hFFFF_FFFC);
        a = 32'd1; b = 32'd2; alu_sel = ALU_SLT;  check("SLT", 32'd1);
        a = 32'hFFFF_FFFF; b = 32'd1; alu_sel = ALU_SLTU; check("SLTU", 32'd0);
        b = 32'h1234_5678; alu_sel = ALU_PASSB; check("PASSB", 32'h1234_5678);
        $display("tb_alu PASSED");
        $finish;
    end
endmodule
