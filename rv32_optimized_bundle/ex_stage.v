module ex_stage (
    input  wire [31:0] pcX,
    input  wire [31:0] pc4X,
    input  wire [31:0] rs1_valX,
    input  wire [31:0] rs2_valX,
    input  wire [31:0] immX,
    input  wire        asel_pcX,
    input  wire        bsel_immX,
    input  wire [4:0]  alu_selX,
    input  wire        branchX,
    input  wire        jumpX,
    input  wire        jalrX,
    input  wire        br_unX,
    input  wire [2:0]  branch_funct3X,
    output wire [31:0] alu_outX,
    output reg  [31:0] pc_targetX,
    output reg         take_branchX,
    output wire [31:0] store_dataX,
    output wire [31:0] pc4_passX,
    output wire        br_eqX,
    output wire        br_ltX
);
    `include "rv32_defs.vh"

    wire [31:0] alu_a = asel_pcX ? pcX : rs1_valX;
    wire [31:0] alu_b = bsel_immX ? immX : rs2_valX;

    assign store_dataX = rs2_valX;
    assign pc4_passX   = pc4X;
    assign br_eqX      = (rs1_valX == rs2_valX);
    assign br_ltX      = br_unX ? (rs1_valX < rs2_valX) : ($signed(rs1_valX) < $signed(rs2_valX));

    alu u_alu (
        .a      (alu_a),
        .b      (alu_b),
        .alu_sel(alu_selX),
        .y      (alu_outX)
    );

    always @(*) begin
        take_branchX = 1'b0;
        pc_targetX   = 32'h0;

        if (jumpX) begin
            take_branchX = 1'b1;
            pc_targetX   = jalrX ? ((rs1_valX + immX) & ~32'd1) : (pcX + immX);
        end else if (branchX) begin
            pc_targetX = pcX + immX;
            case (branch_funct3X)
                3'b000: take_branchX =  br_eqX;    // beq
                3'b001: take_branchX = ~br_eqX;    // bne
                3'b100: take_branchX =  br_ltX;    // blt / bltu
                3'b101: take_branchX = ~br_ltX;    // bge / bgeu
                3'b110: take_branchX =  br_ltX;    // bltu
                3'b111: take_branchX = ~br_ltX;    // bgeu
                default: take_branchX = 1'b0;
            endcase
        end
    end
endmodule
