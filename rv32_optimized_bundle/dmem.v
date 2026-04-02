module dmem #(
    parameter BYTES = 4096,
    parameter INIT_FILE = ""
) (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [2:0]  funct3,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output reg  [31:0] rdata
);
    localparam ADDR_W = (BYTES <= 2) ? 1 : $clog2(BYTES);

    reg [7:0] mem [0:BYTES-1];
    integer i;

    wire [ADDR_W-1:0] a0 = addr[ADDR_W-1:0];
    wire [ADDR_W-1:0] a1 = addr[ADDR_W-1:0] + 1'b1;
    wire [ADDR_W-1:0] a2 = addr[ADDR_W-1:0] + 2'd2;
    wire [ADDR_W-1:0] a3 = addr[ADDR_W-1:0] + 2'd3;

    initial begin
        for (i = 0; i < BYTES; i = i + 1)
            mem[i] = 8'h00;
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    always @(*) begin
        rdata = 32'h0;
        if (mem_read) begin
            case (funct3)
                3'b000: rdata = {{24{mem[a0][7]}}, mem[a0]};
                3'b100: rdata = {24'h0, mem[a0]};
                3'b001: rdata = {{16{mem[a1][7]}}, mem[a1], mem[a0]};
                3'b101: rdata = {16'h0, mem[a1], mem[a0]};
                3'b010: rdata = {mem[a3], mem[a2], mem[a1], mem[a0]};
                default: rdata = 32'h0;
            endcase
        end
    end

    always @(posedge clk) begin
        if (mem_write) begin
            case (funct3)
                3'b000: mem[a0] <= wdata[7:0];
                3'b001: begin
                    mem[a0] <= wdata[7:0];
                    mem[a1] <= wdata[15:8];
                end
                3'b010: begin
                    mem[a0] <= wdata[7:0];
                    mem[a1] <= wdata[15:8];
                    mem[a2] <= wdata[23:16];
                    mem[a3] <= wdata[31:24];
                end
                default: ;
            endcase
        end
    end
endmodule
