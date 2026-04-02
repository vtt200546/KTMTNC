module id_stage (
    input  wire [31:0] instrD,
    input  wire [31:0] pcD,
    input  wire [31:0] pc4D,
    input  wire [31:0] rs1_dataD,
    input  wire [31:0] rs2_dataD,
    output wire [4:0]  rs1_addrD,
    output wire [4:0]  rs2_addrD,
    output wire [4:0]  rd_addrD,
    output wire [31:0] immD,
    output wire [31:0] d1D,
    output wire [31:0] d2D,
    output wire [31:0] pc_outD,
    output wire [31:0] pc4_outD,
    output wire        reg_writeD,
    output wire        mem_readD,
    output wire        mem_writeD,
    output wire [1:0]  wb_selD,
    output wire        asel_pcD,
    output wire        bsel_immD,
    output wire [4:0]  alu_selD,
    output wire [2:0]  imm_selD,
    output wire        branchD,
    output wire        jumpD,
    output wire        jalrD,
    output wire        br_unD,
    output wire [2:0]  branch_funct3D,
    output wire [2:0]  mem_funct3D,
    output wire        use_rs1D,
    output wire        use_rs2D,
    output wire        validD
);
    assign rs1_addrD = instrD[19:15];
    assign rs2_addrD = instrD[24:20];
    assign rd_addrD  = instrD[11:7];
    assign d1D       = rs1_dataD;
    assign d2D       = rs2_dataD;
    assign pc_outD   = pcD;
    assign pc4_outD  = pc4D;

    control_unit u_cu (
        .instr         (instrD),
        .reg_write     (reg_writeD),
        .mem_read      (mem_readD),
        .mem_write     (mem_writeD),
        .wb_sel        (wb_selD),
        .asel_pc       (asel_pcD),
        .bsel_imm      (bsel_immD),
        .alu_sel       (alu_selD),
        .imm_sel       (imm_selD),
        .branch        (branchD),
        .jump          (jumpD),
        .jalr          (jalrD),
        .br_un         (br_unD),
        .branch_funct3 (branch_funct3D),
        .mem_funct3    (mem_funct3D),
        .use_rs1       (use_rs1D),
        .use_rs2       (use_rs2D),
        .valid         (validD)
    );

    imm_gen u_imm (
        .instr   (instrD),
        .imm_sel (imm_selD),
        .imm     (immD)
    );
endmodule
