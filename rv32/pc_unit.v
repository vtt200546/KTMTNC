module pc_unit (
    input  wire        clk,
    input  wire        rst,
    input  wire        stallF,
    input  wire        pc_sel,
    input  wire [31:0] pc_target,
    output reg  [31:0] pcF,
    output wire [31:0] pc4F
);
    // Tính toán địa chỉ kế tiếp 
    assign pc4F = pcF + 32'd4;

    // Logic cập nhật PC 
    always @(posedge clk) begin
        if (rst)
            pcF <= 32'h0;
        else if (!stallF)
            pcF <= pc_sel ? pc_target : pc4F;
    end
endmodule