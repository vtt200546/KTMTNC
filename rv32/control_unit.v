module control_unit (
    input  wire [31:0] instr,
    output reg         reg_write,
    output reg         mem_read,
    output reg         mem_write,
    output reg  [1:0]  wb_sel,
    output reg         asel_pc,
    output reg         bsel_imm,
    output reg  [4:0]  alu_sel,
    output reg  [2:0]  imm_sel,
    output reg         branch,
    output reg         jump,
    output reg         jalr,
    output reg         br_un,
    output reg  [2:0]  branch_funct3,
    output reg  [2:0]  mem_funct3,
    output reg         use_rs1,
    output reg         use_rs2,
    output reg         valid
);
    `include "rv32_defs.vh"

    wire [6:0] opcode = instr[6:0];
    wire [2:0] funct3 = instr[14:12];
    wire [6:0] funct7 = instr[31:25];

    always @(*) begin
        reg_write      = 1'b0;
        mem_read       = 1'b0;
        mem_write      = 1'b0;
        wb_sel         = WB_ALU;
        asel_pc        = 1'b0;
        bsel_imm       = 1'b0;
        alu_sel        = ALU_ADD;
        imm_sel        = IMM_I;
        branch         = 1'b0;
        jump           = 1'b0;
        jalr           = 1'b0;
        br_un          = 1'b0;
        branch_funct3  = funct3;
        mem_funct3     = funct3;
        use_rs1        = 1'b0;
        use_rs2        = 1'b0;
        valid          = 1'b1;

        case (opcode)
            OPC_RTYPE: begin
                reg_write = 1'b1;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
                case (funct3)
                    3'b000: alu_sel = funct7[5] ? ALU_SUB  : ALU_ADD;
                    3'b111: alu_sel = ALU_AND;
                    3'b110: alu_sel = ALU_OR;
                    3'b100: alu_sel = ALU_XOR;
                    3'b001: alu_sel = ALU_SLL;
                    3'b101: alu_sel = funct7[5] ? ALU_SRA  : ALU_SRL;
                    3'b010: alu_sel = ALU_SLT;
                    3'b011: alu_sel = ALU_SLTU;
                    default: valid  = 1'b0;
                endcase
            end

            OPC_ITYPE: begin
                reg_write = 1'b1;
                use_rs1   = 1'b1;
                bsel_imm  = 1'b1;
                case (funct3)
                    3'b000: begin alu_sel = ALU_ADD;  imm_sel = IMM_I;     end // addi
                    3'b111: begin alu_sel = ALU_AND;  imm_sel = IMM_I;     end // andi
                    3'b110: begin alu_sel = ALU_OR;   imm_sel = IMM_I;     end // ori
                    3'b100: begin alu_sel = ALU_XOR;  imm_sel = IMM_I;     end // xori
                    3'b010: begin alu_sel = ALU_SLT;  imm_sel = IMM_I;     end // slti
                    3'b011: begin alu_sel = ALU_SLTU; imm_sel = IMM_I;     end // sltiu 
                    3'b001: begin alu_sel = ALU_SLL;  imm_sel = IMM_SHAMT; end // slli
                    3'b101: begin
                        alu_sel = funct7[5] ? ALU_SRA : ALU_SRL;
                        imm_sel = IMM_SHAMT;                                         // srli / srai
                    end
                    default: valid = 1'b0;
                endcase
            end

            OPC_LOAD: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                wb_sel    = WB_MEM;
                use_rs1   = 1'b1;
                bsel_imm  = 1'b1;
                alu_sel   = ALU_ADD;
                imm_sel   = IMM_I;
                mem_funct3= funct3;
            end

            OPC_STORE: begin
                mem_write = 1'b1;
                use_rs1   = 1'b1;
                use_rs2   = 1'b1;
                bsel_imm  = 1'b1;
                alu_sel   = ALU_ADD;
                imm_sel   = IMM_S;
                mem_funct3= funct3;
            end

            OPC_BRANCH: begin
                branch         = 1'b1;
                use_rs1        = 1'b1;
                use_rs2        = 1'b1;
                imm_sel        = IMM_B;
                branch_funct3  = funct3;
                br_un          = funct3[1]; // bltu/bgeu dùng unsigned
            end

            OPC_JAL: begin
                reg_write = 1'b1;
                wb_sel    = WB_PC4;
                jump      = 1'b1;
                imm_sel   = IMM_J;
            end

            OPC_JALR: begin
                reg_write = 1'b1;
                wb_sel    = WB_PC4;
                jump      = 1'b1;
                jalr      = 1'b1;
                use_rs1   = 1'b1;
                imm_sel   = IMM_I;
            end

            OPC_AUIPC: begin
                reg_write = 1'b1;
                asel_pc   = 1'b1;
                bsel_imm  = 1'b1;
                alu_sel   = ALU_ADD;
                imm_sel   = IMM_U;
            end

            OPC_LUI: begin
                reg_write = 1'b1;
                bsel_imm  = 1'b1;
                alu_sel   = ALU_PASSB;
                imm_sel   = IMM_U;
            end

            OPC_SYSTEM: begin
                valid = 1'b0; // ecall/ebreak: hiện tại coi như bubble/nop
            end

            default: begin
                valid = 1'b0;
            end
        endcase
    end
endmodule
