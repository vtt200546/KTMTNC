module wb_stage (
    input  wire [1:0]  wb_selW,
    input  wire [31:0] aluW,
    input  wire [31:0] memW,
    input  wire [31:0] pc4W,
    output reg  [31:0] wb_dataW
);
    `include "rv32_defs.vh"

    always @(*) begin
        case (wb_selW)
            WB_ALU: wb_dataW = aluW;
            WB_MEM: wb_dataW = memW;
            WB_PC4: wb_dataW = pc4W;
            default: wb_dataW = 32'h0;
        endcase
    end
endmodule
