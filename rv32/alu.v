module alu (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [4:0]  alu_sel,
    output reg  [31:0] y
);
    `include "rv32_defs.vh"

    always @(*) begin
        case (alu_sel)
            ALU_ADD:   y = a + b;
            ALU_SUB:   y = a - b;
            ALU_AND:   y = a & b;
            ALU_OR:    y = a | b;
            ALU_XOR:   y = a ^ b;
            ALU_SLL:   y = a << b[4:0];
            ALU_SRL:   y = a >> b[4:0];
            ALU_SRA:   y = $signed(a) >>> b[4:0];
            ALU_SLT:   y = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLTU:  y = (a < b) ? 32'd1 : 32'd0;
            ALU_PASSB: y = b;
            default:   y = 32'h0;
        endcase
    end
endmodule
