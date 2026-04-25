localparam [6:0] OPC_RTYPE  = 7'b0110011;
localparam [6:0] OPC_ITYPE  = 7'b0010011;
localparam [6:0] OPC_LOAD   = 7'b0000011;
localparam [6:0] OPC_STORE  = 7'b0100011;
localparam [6:0] OPC_BRANCH = 7'b1100011;
localparam [6:0] OPC_JALR   = 7'b1100111;
localparam [6:0] OPC_JAL    = 7'b1101111;
localparam [6:0] OPC_AUIPC  = 7'b0010111;
localparam [6:0] OPC_LUI    = 7'b0110111;
localparam [6:0] OPC_SYSTEM = 7'b1110011;

localparam [4:0] ALU_ADD   = 5'd0;
localparam [4:0] ALU_SUB   = 5'd1;
localparam [4:0] ALU_AND   = 5'd2;
localparam [4:0] ALU_OR    = 5'd3;
localparam [4:0] ALU_XOR   = 5'd4;
localparam [4:0] ALU_SLL   = 5'd5;
localparam [4:0] ALU_SRL   = 5'd6;
localparam [4:0] ALU_SRA   = 5'd7;
localparam [4:0] ALU_SLT   = 5'd8;
localparam [4:0] ALU_SLTU  = 5'd9;
localparam [4:0] ALU_PASSB = 5'd10;

localparam [2:0] IMM_I     = 3'd0;
localparam [2:0] IMM_S     = 3'd1;
localparam [2:0] IMM_B     = 3'd2;
localparam [2:0] IMM_U     = 3'd3;
localparam [2:0] IMM_J     = 3'd4;
localparam [2:0] IMM_SHAMT = 3'd5;
localparam [2:0] IMM_ZI    = 3'd6;

localparam [1:0] WB_ALU    = 2'd0;
localparam [1:0] WB_MEM    = 2'd1;
localparam [1:0] WB_PC4    = 2'd2;

localparam [31:0] NOP = 32'h00000013; // addi x0, x0, 0

