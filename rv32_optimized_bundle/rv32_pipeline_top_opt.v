module rv32_pipeline_top_opt #(
    parameter IMEM_DEPTH = 256,
    parameter IMEM_INIT  = "",
    parameter DMEM_BYTES = 4096,
    parameter DMEM_INIT  = ""
) (
    input  wire clk,
    input  wire rst
);
    `include "rv32_defs.vh"

    // IF
    wire [31:0] pcF, pc4F, instrF;
    wire        stallF;
    wire        pc_selF;
    wire [31:0] pc_targetF;

    if_stage #(
        .IMEM_DEPTH(IMEM_DEPTH),
        .IMEM_INIT (IMEM_INIT)
    ) u_if (
        .clk      (clk),
        .rst      (rst),
        .stallF   (stallF),
        .pc_sel   (pc_selF),
        .pc_target(pc_targetF),
        .pcF      (pcF),
        .pc4F     (pc4F),
        .instrF   (instrF)
    );

    // F/D regs
    reg [31:0] instrD, pcD, pc4D;

    // ID
    wire [4:0]  rs1_addrD, rs2_addrD, rd_addrD;
    wire [31:0] rs1_dataD, rs2_dataD;
    wire [31:0] immD, d1D, d2D, pc_outD, pc4_outD;
    wire        reg_writeD, mem_readD, mem_writeD, asel_pcD, bsel_immD, branchD, jumpD, jalrD, br_unD, use_rs1D, use_rs2D, validD;
    wire [1:0]  wb_selD;
    wire [4:0]  alu_selD;
    wire [2:0]  imm_selD, branch_funct3D, mem_funct3D;

    wire [31:0] wb_dataW;
    wire        reg_writeW;
    reg  [4:0]  rdW;

    regfile u_rf (
        .clk (clk),
        .rst (rst),
        .we  (reg_writeW),
        .rs1 (rs1_addrD),
        .rs2 (rs2_addrD),
        .rd  (rdW),
        .wd  (wb_dataW),
        .rd1 (rs1_dataD),
        .rd2 (rs2_dataD)
    );

    id_stage u_id (
        .instrD          (instrD),
        .pcD             (pcD),
        .pc4D            (pc4D),
        .rs1_dataD       (rs1_dataD),
        .rs2_dataD       (rs2_dataD),
        .rs1_addrD       (rs1_addrD),
        .rs2_addrD       (rs2_addrD),
        .rd_addrD        (rd_addrD),
        .immD            (immD),
        .d1D             (d1D),
        .d2D             (d2D),
        .pc_outD         (pc_outD),
        .pc4_outD        (pc4_outD),
        .reg_writeD      (reg_writeD),
        .mem_readD       (mem_readD),
        .mem_writeD      (mem_writeD),
        .wb_selD         (wb_selD),
        .asel_pcD        (asel_pcD),
        .bsel_immD       (bsel_immD),
        .alu_selD        (alu_selD),
        .imm_selD        (imm_selD),
        .branchD         (branchD),
        .jumpD           (jumpD),
        .jalrD           (jalrD),
        .br_unD          (br_unD),
        .branch_funct3D  (branch_funct3D),
        .mem_funct3D     (mem_funct3D),
        .use_rs1D        (use_rs1D),
        .use_rs2D        (use_rs2D),
        .validD          (validD)
    );

    // D/X regs
    reg [31:0] pcX, pc4X, rs1_valX, rs2_valX, immX;
    reg [4:0]  rs1_addrX, rs2_addrX, rdX;
    reg        reg_writeX, mem_readX, mem_writeX, asel_pcX, bsel_immX, branchX, jumpX, jalrX, br_unX;
    reg [1:0]  wb_selX;
    reg [4:0]  alu_selX;
    reg [2:0]  branch_funct3X, mem_funct3X;

    // X/M regs
    reg [31:0] aluM, store_dataM, pc4M;
    reg [4:0]  rdM;
    reg        reg_writeM, mem_readM, mem_writeM;
    reg [1:0]  wb_selM;
    reg [2:0]  mem_funct3M;

    // M/W regs
    reg [31:0] aluW, memW, pc4W;
    reg [1:0]  wb_selW_r;
    reg        reg_writeW_r;
    assign reg_writeW = reg_writeW_r;

    // hazard / forwarding
    wire stallD;
    wire flushX_hz;
    wire [1:0] fwd_sel_a, fwd_sel_b;

    hazard_unit u_hzd (
        .mem_readX (mem_readX),
        .rdX       (rdX),
        .use_rs1D  (use_rs1D),
        .use_rs2D  (use_rs2D),
        .rs1_addrD (rs1_addrD),
        .rs2_addrD (rs2_addrD),
        .rs1_addrX (rs1_addrX),
        .rs2_addrX (rs2_addrX),
        .reg_writeM(reg_writeM),
        .rdM       (rdM),
        .reg_writeW(reg_writeW),
        .rdW       (rdW),
        .stallF    (stallF),
        .stallD    (stallD),
        .flushX    (flushX_hz),
        .fwd_sel_a (fwd_sel_a),
        .fwd_sel_b (fwd_sel_b)
    );

    wire [31:0] load_dataM;
    wire [31:0] resultM = (wb_selM == WB_ALU) ? aluM :
                          (wb_selM == WB_MEM) ? load_dataM :
                          (wb_selM == WB_PC4) ? pc4M : 32'h0;
    wire [31:0] resultW = wb_dataW;

    reg [31:0] fwd_rs1X, fwd_rs2X;
    always @(*) begin
        case (fwd_sel_a)
            2'b01: fwd_rs1X = resultM;
            2'b10: fwd_rs1X = resultW;
            default: fwd_rs1X = rs1_valX;
        endcase

        case (fwd_sel_b)
            2'b01: fwd_rs2X = resultM;
            2'b10: fwd_rs2X = resultW;
            default: fwd_rs2X = rs2_valX;
        endcase
    end

    // EX
    wire [31:0] alu_outX, pc_targetX, store_dataX, pc4_passX;
    wire        take_branchX, br_eqX, br_ltX;

    ex_stage u_ex (
        .pcX            (pcX),
        .pc4X           (pc4X),
        .rs1_valX       (fwd_rs1X),
        .rs2_valX       (fwd_rs2X),
        .immX           (immX),
        .asel_pcX       (asel_pcX),
        .bsel_immX      (bsel_immX),
        .alu_selX       (alu_selX),
        .branchX        (branchX),
        .jumpX          (jumpX),
        .jalrX          (jalrX),
        .br_unX         (br_unX),
        .branch_funct3X (branch_funct3X),
        .alu_outX       (alu_outX),
        .pc_targetX     (pc_targetX),
        .take_branchX   (take_branchX),
        .store_dataX    (store_dataX),
        .pc4_passX      (pc4_passX),
        .br_eqX         (br_eqX),
        .br_ltX         (br_ltX)
    );

    assign pc_selF    = take_branchX;
    assign pc_targetF = pc_targetX;
    wire flushD = take_branchX;
    wire flushX = flushX_hz | take_branchX;

    // MEM
    mem_stage #(
        .DMEM_BYTES(DMEM_BYTES),
        .DMEM_INIT (DMEM_INIT)
    ) u_mem (
        .clk         (clk),
        .mem_readM   (mem_readM),
        .mem_writeM  (mem_writeM),
        .mem_funct3M (mem_funct3M),
        .addrM       (aluM),
        .store_dataM (store_dataM),
        .load_dataM  (load_dataM)
    );

    // WB
    wb_stage u_wb (
        .wb_selW (wb_selW_r),
        .aluW    (aluW),
        .memW    (memW),
        .pc4W    (pc4W),
        .wb_dataW(wb_dataW)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instrD         <= NOP;
            pcD            <= 32'h0;
            pc4D           <= 32'h0;

            pcX            <= 32'h0;
            pc4X           <= 32'h0;
            rs1_valX       <= 32'h0;
            rs2_valX       <= 32'h0;
            immX           <= 32'h0;
            rs1_addrX      <= 5'h0;
            rs2_addrX      <= 5'h0;
            rdX            <= 5'h0;
            reg_writeX     <= 1'b0;
            mem_readX      <= 1'b0;
            mem_writeX     <= 1'b0;
            asel_pcX       <= 1'b0;
            bsel_immX      <= 1'b0;
            branchX        <= 1'b0;
            jumpX          <= 1'b0;
            jalrX          <= 1'b0;
            br_unX         <= 1'b0;
            wb_selX        <= WB_ALU;
            alu_selX       <= ALU_ADD;
            branch_funct3X <= 3'b0;
            mem_funct3X    <= 3'b010;

            aluM           <= 32'h0;
            store_dataM    <= 32'h0;
            pc4M           <= 32'h0;
            rdM            <= 5'h0;
            reg_writeM     <= 1'b0;
            mem_readM      <= 1'b0;
            mem_writeM     <= 1'b0;
            wb_selM        <= WB_ALU;
            mem_funct3M    <= 3'b010;

            aluW           <= 32'h0;
            memW           <= 32'h0;
            pc4W           <= 32'h0;
            rdW            <= 5'h0;
            wb_selW_r      <= WB_ALU;
            reg_writeW_r   <= 1'b0;
        end else begin
            // F/D
            if (!stallD) begin
                if (flushD) begin
                    instrD <= NOP;
                    pcD    <= 32'h0;
                    pc4D   <= 32'h0;
                end else begin
                    instrD <= instrF;
                    pcD    <= pcF;
                    pc4D   <= pc4F;
                end
            end

            // D/X
            if (flushX) begin
                pcX            <= 32'h0;
                pc4X           <= 32'h0;
                rs1_valX       <= 32'h0;
                rs2_valX       <= 32'h0;
                immX           <= 32'h0;
                rs1_addrX      <= 5'h0;
                rs2_addrX      <= 5'h0;
                rdX            <= 5'h0;
                reg_writeX     <= 1'b0;
                mem_readX      <= 1'b0;
                mem_writeX     <= 1'b0;
                asel_pcX       <= 1'b0;
                bsel_immX      <= 1'b0;
                branchX        <= 1'b0;
                jumpX          <= 1'b0;
                jalrX          <= 1'b0;
                br_unX         <= 1'b0;
                wb_selX        <= WB_ALU;
                alu_selX       <= ALU_ADD;
                branch_funct3X <= 3'b0;
                mem_funct3X    <= 3'b010;
            end else begin
                pcX            <= pc_outD;
                pc4X           <= pc4_outD;
                rs1_valX       <= d1D;
                rs2_valX       <= d2D;
                immX           <= immD;
                rs1_addrX      <= rs1_addrD;
                rs2_addrX      <= rs2_addrD;
                rdX            <= rd_addrD;
                reg_writeX     <= reg_writeD & validD;
                mem_readX      <= mem_readD  & validD;
                mem_writeX     <= mem_writeD & validD;
                asel_pcX       <= asel_pcD;
                bsel_immX      <= bsel_immD;
                branchX        <= branchD;
                jumpX          <= jumpD;
                jalrX          <= jalrD;
                br_unX         <= br_unD;
                wb_selX        <= wb_selD;
                alu_selX       <= alu_selD;
                branch_funct3X <= branch_funct3D;
                mem_funct3X    <= mem_funct3D;
            end

            // X/M
            aluM         <= alu_outX;
            store_dataM  <= store_dataX;
            pc4M         <= pc4_passX;
            rdM          <= rdX;
            reg_writeM   <= reg_writeX;
            mem_readM    <= mem_readX;
            mem_writeM   <= mem_writeX;
            wb_selM      <= wb_selX;
            mem_funct3M  <= mem_funct3X;

            // M/W
            aluW         <= aluM;
            memW         <= load_dataM;
            pc4W         <= pc4M;
            rdW          <= rdM;
            wb_selW_r    <= wb_selM;
            reg_writeW_r <= reg_writeM;
        end
    end
endmodule
