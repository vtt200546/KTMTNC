module rv32_single_cycle_top_opt #(
    parameter IMEM_DEPTH = 256,
    parameter IMEM_INIT  = "",
    parameter DMEM_BYTES = 4096,
    parameter DMEM_INIT  = ""
) (
    input  wire clk,
    input  wire rst
);
    `include "rv32_defs.vh"

    reg  [31:0] pc;
    wire [31:0] instr, pc4, imm;
    wire [4:0]  rs1_addr = instr[19:15];
    wire [4:0]  rs2_addr = instr[24:20];
    wire [4:0]  rd_addr  = instr[11:7];
    wire [31:0] rs1_data, rs2_data;
    wire [31:0] alu_out, mem_rdata, wb_data;

    wire        reg_write_dec, mem_read, mem_write, asel_pc, bsel_imm, branch, jump, jalr, br_un, use_rs1, use_rs2, valid;
    wire [1:0]  wb_sel;
    wire [4:0]  alu_sel;
    wire [2:0]  imm_sel, branch_funct3, mem_funct3;

    reg         take_branch;
    reg  [31:0] pc_target;
    wire [31:0] alu_a = asel_pc ? pc : rs1_data;
    wire [31:0] alu_b = bsel_imm ? imm : rs2_data;
    wire        br_eq = (rs1_data == rs2_data);
    wire        br_lt = br_un ? (rs1_data < rs2_data) : ($signed(rs1_data) < $signed(rs2_data));
    wire [31:0] pc_next = take_branch ? pc_target : pc4;
    wire        reg_write = reg_write_dec & valid;

    assign pc4 = pc + 32'd4;

    imem #(
        .DEPTH(IMEM_DEPTH),
        .INIT_FILE(IMEM_INIT)
    ) u_imem (
        .addr (pc),
        .instr(instr)
    );

    control_unit u_cu (
        .instr         (instr),
        .reg_write     (reg_write_dec),
        .mem_read      (mem_read),
        .mem_write     (mem_write),
        .wb_sel        (wb_sel),
        .asel_pc       (asel_pc),
        .bsel_imm      (bsel_imm),
        .alu_sel       (alu_sel),
        .imm_sel       (imm_sel),
        .branch        (branch),
        .jump          (jump),
        .jalr          (jalr),
        .br_un         (br_un),
        .branch_funct3 (branch_funct3),
        .mem_funct3    (mem_funct3),
        .use_rs1       (use_rs1),
        .use_rs2       (use_rs2),
        .valid         (valid)
    );

    imm_gen u_imm (
        .instr   (instr),
        .imm_sel (imm_sel),
        .imm     (imm)
    );

    regfile u_rf (
        .clk (clk),
        .rst (rst),
        .we  (reg_write),
        .rs1 (rs1_addr),
        .rs2 (rs2_addr),
        .rd  (rd_addr),
        .wd  (wb_data),
        .rd1 (rs1_data),
        .rd2 (rs2_data)
    );

    alu u_alu (
        .a      (alu_a),
        .b      (alu_b),
        .alu_sel(alu_sel),
        .y      (alu_out)
    );

    always @(*) begin
        take_branch = 1'b0;
        pc_target   = 32'h0;

        if (jump) begin
            take_branch = 1'b1;
            pc_target   = jalr ? ((rs1_data + imm) & ~32'd1) : (pc + imm);
        end else if (branch) begin
            pc_target = pc + imm;
            case (branch_funct3)
                3'b000: take_branch =  br_eq;
                3'b001: take_branch = ~br_eq;
                3'b100: take_branch =  br_lt;
                3'b101: take_branch = ~br_lt;
                3'b110: take_branch =  br_lt;
                3'b111: take_branch = ~br_lt;
                default: take_branch = 1'b0;
            endcase
        end
    end

    dmem #(
        .BYTES(DMEM_BYTES),
        .INIT_FILE(DMEM_INIT)
    ) u_dmem (
        .clk      (clk),
        .mem_read (mem_read & valid),
        .mem_write(mem_write & valid),
        .funct3   (mem_funct3),
        .addr     (alu_out),
        .wdata    (rs2_data),
        .rdata    (mem_rdata)
    );

    wb_stage u_wb (
        .wb_selW (wb_sel),
        .aluW    (alu_out),
        .memW    (mem_rdata),
        .pc4W    (pc4),
        .wb_dataW(wb_data)
    );

    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'h0;
        else
            pc <= pc_next;
    end
endmodule
