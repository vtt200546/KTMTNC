Bộ mã này bám theo datapath trong reference card:
- Trang 4: single-cycle datapath có PCSel, ImmSel, BrUn, BrEq, BrLT, BSel, ASel, ALUSel, MemRW, WBSel, RegWEn.
- Trang 5: pipeline datapath với IF/ID/EX/MEM/WB và các bundle ctrlF/ctrlX/ctrlM/ctrlW.

Các file chính:
- rv32_defs.vh         : define opcode/control chung
- imem.v / dmem.v      : instruction memory / data memory
- regfile.v            : register file 32x32
- alu.v                : ALU
- imm_gen.v            : immediate generator
- control_unit.v       : control unit
- if_stage.v
- id_stage.v
- ex_stage.v
- mem_stage.v
- wb_stage.v
- rv32_pipeline_top.v  : top level

Testbench:
- tb_alu.sv
- tb_regfile.sv
- tb_imem_dmem.sv
- tb_control_unit.sv
- tb_if_stage.sv
- tb_id_stage.sv
- tb_ex_stage.sv
- tb_mem_stage.sv
- tb_wb_stage.sv
- tb_rv32_pipeline_top.sv

Phạm vi hỗ trợ:
- R-type: add/sub/and/or/xor/sll/srl/sra/slt/sltu
- I-type: addi/andi/ori/xori/slti/sltiu/slli/srli/srai
- Load/store: lb/lbu/lh/lhu/lw + sb/sh/sw
- Branch/jump: beq/bne/blt/bge/bltu/bgeu/jal/jalr
- U-type: lui/auipc

Hiện tại ecall/ebreak được coi là bubble/NOP; mul chưa hỗ trợ.
