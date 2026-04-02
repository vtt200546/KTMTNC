`timescale 1ns/1ps
module tb_if_stage;
    reg clk = 0, rst = 1, stallF = 0, pc_sel = 0;
    reg [31:0] pc_target = 0;
    wire [31:0] pcF, pc4F, instrF;

    if_stage #(.IMEM_DEPTH(16)) dut (
        .clk(clk), .rst(rst), .stallF(stallF), .pc_sel(pc_sel), .pc_target(pc_target),
        .pcF(pcF), .pc4F(pc4F), .instrF(instrF)
    );

    always #5 clk = ~clk;

    initial begin
        dut.u_imem.mem[0] = 32'hAAAA_AAAA;
        dut.u_imem.mem[1] = 32'hBBBB_BBBB;
        dut.u_imem.mem[2] = 32'hCCCC_CCCC;

        #12 rst = 0;
        #1 if (pcF !== 0 || instrF !== 32'hAAAA_AAAA) begin
            $display("FAIL IF reset fetch");
            $fatal;
        end

        #10;
        #1 if (pcF !== 4 || instrF !== 32'hBBBB_BBBB) begin
            $display("FAIL IF pc+4");
            $fatal;
        end

        pc_sel = 1; pc_target = 8;
        #10 pc_sel = 0;
        #1 if (pcF !== 8 || instrF !== 32'hCCCC_CCCC) begin
            $display("FAIL IF redirect");
            $fatal;
        end

        stallF = 1;
        #10 stallF = 0;
        #1 if (pcF !== 8) begin
            $display("FAIL IF stall");
            $fatal;
        end

        $display("tb_if_stage PASSED");
        $finish;
    end
endmodule
