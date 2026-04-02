`timescale 1ns/1ps
module tb_imem_dmem;
    reg  clk = 0;
    reg  mem_read, mem_write;
    reg  [2:0] funct3;
    reg  [31:0] addr, wdata;
    wire [31:0] instr, rdata;

    imem #(.DEPTH(16)) u_imem (
        .addr(addr),
        .instr(instr)
    );

    dmem #(.BYTES(64)) u_dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .funct3(funct3),
        .addr(addr),
        .wdata(wdata),
        .rdata(rdata)
    );

    always #5 clk = ~clk;

    initial begin
        u_imem.mem[0] = 32'h1234_5678;
        u_imem.mem[1] = 32'h89AB_CDEF;

        addr = 0;
        #1;
        if (instr !== 32'h1234_5678) begin
            $display("FAIL imem word0");
            $fatal;
        end
        addr = 4;
        #1;
        if (instr !== 32'h89AB_CDEF) begin
            $display("FAIL imem word1");
            $fatal;
        end

        mem_read = 0; mem_write = 1; funct3 = 3'b010; addr = 0; wdata = 32'hA1B2_C3D4;
        #10 mem_write = 0;

        mem_read = 1; funct3 = 3'b010; addr = 0; #1;
        if (rdata !== 32'hA1B2_C3D4) begin
            $display("FAIL dmem lw");
            $fatal;
        end

        funct3 = 3'b000; addr = 1; #1; // lb
        if (rdata !== 32'hFFFF_FFC3) begin
            $display("FAIL dmem lb");
            $fatal;
        end

        funct3 = 3'b100; addr = 1; #1; // lbu
        if (rdata !== 32'h0000_00C3) begin
            $display("FAIL dmem lbu");
            $fatal;
        end

        funct3 = 3'b001; addr = 0; #1; // lh => D4C3 sign extend from high byte C3
        if (rdata !== 32'hFFFF_C3D4) begin
            $display("FAIL dmem lh");
            $fatal;
        end

        funct3 = 3'b101; addr = 0; #1; // lhu
        if (rdata !== 32'h0000_C3D4) begin
            $display("FAIL dmem lhu");
            $fatal;
        end

        $display("tb_imem_dmem PASSED");
        $finish;
    end
endmodule
