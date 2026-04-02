module regfile (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);
    reg [31:0] regs [0:31];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = 32'h0;
    end

    // synchronous reset is friendlier for synthesis than clearing a whole RF asynchronously
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'h0;
        end else if (we && (rd != 5'd0)) begin
            regs[rd] <= wd;
        end
        regs[0] <= 32'h0;
    end

    wire hit_rs1_wb = we && (rd != 5'd0) && (rd == rs1);
    wire hit_rs2_wb = we && (rd != 5'd0) && (rd == rs2);

    assign rd1 = (rs1 == 5'd0) ? 32'h0 : (hit_rs1_wb ? wd : regs[rs1]);
    assign rd2 = (rs2 == 5'd0) ? 32'h0 : (hit_rs2_wb ? wd : regs[rs2]);
endmodule
