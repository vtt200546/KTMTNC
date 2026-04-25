module imem #(
    parameter DEPTH = 256,
    parameter INIT_FILE = ""
) (
    input  wire [31:0] addr,
    output wire [31:0] instr
);
    reg [31:0] mem [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            mem[i] = 32'h00000013; // nop
        if (INIT_FILE != "")
            $readmemh(INIT_FILE, mem);
    end

    assign instr = mem[addr[31:2]];
endmodule
