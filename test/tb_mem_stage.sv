`timescale 1ns/1ps

module tb_mem_stage_full;

    logic clk;

    logic        mem_readM;
    logic        mem_writeM;
    logic [2:0]  mem_funct3M;
    logic [31:0] addrM;
    logic [31:0] store_dataM;
    wire  [31:0] load_dataM;

    integer tests;
    integer errors;

    localparam [2:0] F3_BYTE  = 3'b000; // LB / SB
    localparam [2:0] F3_HALF  = 3'b001; // LH / SH
    localparam [2:0] F3_WORD  = 3'b010; // LW / SW
    localparam [2:0] F3_BYTEU = 3'b100; // LBU
    localparam [2:0] F3_HALFU = 3'b101; // LHU

    mem_stage #(
        .DMEM_BYTES(256),
        .DMEM_INIT ("")
    ) dut (
        .clk         (clk),
        .mem_readM   (mem_readM),
        .mem_writeM  (mem_writeM),
        .mem_funct3M (mem_funct3M),
        .addrM       (addrM),
        .store_dataM (store_dataM),
        .load_dataM  (load_dataM)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic check32;
        input string name;
        input [31:0] got;
        input [31:0] exp;
        begin
            if (got !== exp) begin
                $display("[FAIL] %-32s exp=0x%08h got=0x%08h time=%0t",
                         name, exp, got, $time);
                errors = errors + 1;
            end else begin
                $display("[PASS] %-32s = 0x%08h", name, got);
            end
        end
    endtask

    task automatic do_store;
        input string cname;
        input [2:0]  funct3;
        input [31:0] addr;
        input [31:0] data;
        begin
            tests = tests + 1;

            @(negedge clk);
            mem_readM   = 1'b0;
            mem_writeM  = 1'b1;
            mem_funct3M = funct3;
            addrM       = addr;
            store_dataM = data;

            @(posedge clk);
            #1;

            $display("[CASE] STORE %-20s addr=0x%08h data=0x%08h funct3=%03b",
                     cname, addr, data, funct3);

            @(negedge clk);
            mem_writeM = 1'b0;
        end
    endtask

    task automatic do_load_check;
        input string cname;
        input [2:0]  funct3;
        input [31:0] addr;
        input [31:0] exp;
        begin
            tests = tests + 1;

            @(negedge clk);
            mem_readM   = 1'b1;
            mem_writeM  = 1'b0;
            mem_funct3M = funct3;
            addrM       = addr;
            store_dataM = 32'h0;

            #1;

            $display("[CASE] LOAD %-21s addr=0x%08h funct3=%03b",
                     cname, addr, funct3);

            check32(cname, load_dataM, exp);

            @(negedge clk);
            mem_readM = 1'b0;
        end
    endtask

    initial begin
        tests       = 0;
        errors      = 0;

        mem_readM   = 1'b0;
        mem_writeM  = 1'b0;
        mem_funct3M = F3_WORD;
        addrM       = 32'h0;
        store_dataM = 32'h0;

        $display("====================================================");
        $display(" Start full MEM stage test");
        $display("====================================================");

        repeat (2) @(posedge clk);

        // ========================================================
        // Case 1: SW / LW cơ bản
        // Ghi word 0xA1B2_C3D4 tại addr 0.
        // Nếu DMEM little-endian:
        // mem[0] = D4, mem[1] = C3, mem[2] = B2, mem[3] = A1
        // ========================================================

        do_store("SW word @0", F3_WORD, 32'h0000_0000, 32'hA1B2_C3D4);

        do_load_check("LW @0",
            F3_WORD,
            32'h0000_0000,
            32'hA1B2_C3D4
        );

        // ========================================================
        // Case 2: LB / LBU tại byte 0
        // Byte thấp là 0xD4. Signed byte 0xD4 có bit 7 = 1,
        // nên LB phải sign-extend thành 0xFFFF_FFD4.
        // LBU phải zero-extend thành 0x0000_00D4.
        // ========================================================

        do_load_check("LB signed byte @0",
            F3_BYTE,
            32'h0000_0000,
            32'hFFFF_FFD4
        );

        do_load_check("LBU unsigned byte @0",
            F3_BYTEU,
            32'h0000_0000,
            32'h0000_00D4
        );

        // ========================================================
        // Case 3: LH / LHU tại half-word thấp
        // Half-word thấp là 0xC3D4. Bit 15 = 1,
        // nên LH phải sign-extend thành 0xFFFF_C3D4.
        // LHU phải zero-extend thành 0x0000_C3D4.
        // ========================================================

        do_load_check("LH signed half @0",
            F3_HALF,
            32'h0000_0000,
            32'hFFFF_C3D4
        );

        do_load_check("LHU unsigned half @0",
            F3_HALFU,
            32'h0000_0000,
            32'h0000_C3D4
        );

        // ========================================================
        // Case 4: Kiểm tra byte order bằng load từng byte
        // Với 0xA1B2_C3D4 ghi ở addr 0:
        // addr 0 -> D4
        // addr 1 -> C3
        // addr 2 -> B2
        // addr 3 -> A1
        // ========================================================

        do_load_check("LBU byte addr 0 = D4",
            F3_BYTEU,
            32'h0000_0000,
            32'h0000_00D4
        );

        do_load_check("LBU byte addr 1 = C3",
            F3_BYTEU,
            32'h0000_0001,
            32'h0000_00C3
        );

        do_load_check("LBU byte addr 2 = B2",
            F3_BYTEU,
            32'h0000_0002,
            32'h0000_00B2
        );

        do_load_check("LBU byte addr 3 = A1",
            F3_BYTEU,
            32'h0000_0003,
            32'h0000_00A1
        );

        // ========================================================
        // Case 5: SB chỉ được ghi 1 byte, không phá các byte khác
        // Ghi byte 0x77 vào addr 1.
        // Word ban đầu: A1 B2 C3 D4
        // Byte addr1 C3 -> 77
        // Word mới: A1 B2 77 D4
        // ========================================================

        do_store("SB byte 0x77 @1",
            F3_BYTE,
            32'h0000_0001,
            32'h0000_0077
        );

        do_load_check("LW after SB @1",
            F3_WORD,
            32'h0000_0000,
            32'hA1B2_77D4
        );

        do_load_check("LBU after SB @1",
            F3_BYTEU,
            32'h0000_0001,
            32'h0000_0077
        );

        // ========================================================
        // Case 6: SH chỉ được ghi 2 byte
        // Ghi half-word 0x5566 vào addr 2.
        // Word đang là A1 B2 77 D4
        // addr2 = B2 -> 66
        // addr3 = A1 -> 55
        // Word mới: 55 66 77 D4
        // ========================================================

        do_store("SH half 0x5566 @2",
            F3_HALF,
            32'h0000_0002,
            32'h0000_5566
        );

        do_load_check("LW after SH @2",
            F3_WORD,
            32'h0000_0000,
            32'h5566_77D4
        );

        do_load_check("LHU after SH @2",
            F3_HALFU,
            32'h0000_0002,
            32'h0000_5566
        );

        // ========================================================
        // Case 7: mem_writeM = 0 thì không được ghi
        // Thử đặt data mới nhưng không bật write, rồi đọc lại.
        // ========================================================

        tests = tests + 1;
        @(negedge clk);
        mem_readM   = 1'b0;
        mem_writeM  = 1'b0;
        mem_funct3M = F3_WORD;
        addrM       = 32'h0000_0000;
        store_dataM = 32'hDEAD_BEEF;

        @(posedge clk);
        #1;

        $display("[CASE] No write when mem_writeM=0");

        do_load_check("LW unchanged after no-write",
            F3_WORD,
            32'h0000_0000,
            32'h5566_77D4
        );

        // ========================================================
        // Case 8: mem_readM = 0
        // Kỳ vọng này phụ thuộc RTL của bạn.
        // Nếu dmem của bạn định nghĩa load_dataM = 0 khi không read,
        // thì check dưới đúng. Nếu RTL luôn đọc combinational,
        // bạn bỏ case này hoặc sửa expected theo RTL.
        // ========================================================

        tests = tests + 1;
        @(negedge clk);
        mem_readM   = 1'b0;
        mem_writeM  = 1'b0;
        mem_funct3M = F3_WORD;
        addrM       = 32'h0000_0000;
        store_dataM = 32'h0;
        #1;

        $display("[CASE] mem_readM = 0 behavior");
        check32("load_dataM when mem_readM=0", load_dataM, 32'h0000_0000);

        $display("====================================================");
        if (errors == 0) begin
            $display("[PASS] MEM stage full test passed. tests=%0d", tests);
        end else begin
            $display("[FAIL] MEM stage full test failed. tests=%0d errors=%0d", tests, errors);
            $fatal(1);
        end
        $display("====================================================");

        $finish;
    end

endmodule