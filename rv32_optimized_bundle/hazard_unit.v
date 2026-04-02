module hazard_unit (
    input  wire        mem_readX,
    input  wire [4:0]  rdX,
    input  wire        use_rs1D,
    input  wire        use_rs2D,
    input  wire [4:0]  rs1_addrD,
    input  wire [4:0]  rs2_addrD,
    input  wire [4:0]  rs1_addrX,
    input  wire [4:0]  rs2_addrX,
    input  wire        reg_writeM,
    input  wire [4:0]  rdM,
    input  wire        reg_writeW,
    input  wire [4:0]  rdW,
    output wire        stallF,
    output wire        stallD,
    output wire        flushX,
    output reg  [1:0]  fwd_sel_a,
    output reg  [1:0]  fwd_sel_b
);
    wire load_use_hazard;

    assign load_use_hazard = mem_readX && (rdX != 5'd0) &&
                             ((use_rs1D && (rs1_addrD == rdX)) ||
                              (use_rs2D && (rs2_addrD == rdX)));

    assign stallF = load_use_hazard;
    assign stallD = load_use_hazard;
    assign flushX = load_use_hazard;

    always @(*) begin
        fwd_sel_a = 2'b00;
        fwd_sel_b = 2'b00;

        if (reg_writeM && (rdM != 5'd0) && (rdM == rs1_addrX))
            fwd_sel_a = 2'b01;
        else if (reg_writeW && (rdW != 5'd0) && (rdW == rs1_addrX))
            fwd_sel_a = 2'b10;

        if (reg_writeM && (rdM != 5'd0) && (rdM == rs2_addrX))
            fwd_sel_b = 2'b01;
        else if (reg_writeW && (rdW != 5'd0) && (rdW == rs2_addrX))
            fwd_sel_b = 2'b10;
    end
endmodule
