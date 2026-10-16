
`timescale 1ns / 1ps

module sync_fifo_tb;

    parameter DATA_WIDTH  = 8;
    parameter DEPTH       = 16;
    parameter ADDR_WIDTH  = (DEPTH <= 1) ? 1 : $clog2(DEPTH);
    parameter COUNT_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1);

    reg clk;
    reg rst;
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] din;

    wire [DATA_WIDTH-1:0] dout;
    wire full;
    wire empty;
    wire [COUNT_WIDTH-1:0] count;

    integer errors;
    integer cycles;
    integer i;
    integer accepted_write;
    integer accepted_read;

    reg random_wr;
    reg random_rd;
    reg [DATA_WIDTH-1:0] random_data;

    // Reference model
    reg [DATA_WIDTH-1:0] model_mem [0:DEPTH-1];

    integer model_wr_ptr;
    integer model_rd_ptr;
    integer model_count;

    reg [DATA_WIDTH-1:0] expected_dout;

    // DUT
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .COUNT_WIDTH(COUNT_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty),
        .count(count)
    );

    // 10 ns clock period
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Apply one transaction and verify the DUT.
    task tick;
        input reset_in;
        input write_in;
        input read_in;
        input [DATA_WIDTH-1:0] data_in;

        begin
            @(negedge clk);

            rst   = reset_in;
            wr_en = write_in;
            rd_en = read_in;
            din   = data_in;

            if (reset_in) begin
                model_wr_ptr = 0;
                model_rd_ptr = 0;
                model_count = 0;
                expected_dout = {DATA_WIDTH{1'b0}};
            end
            else begin
                // Decide acceptance using pre-edge occupancy.
                accepted_write = write_in &&
                                 (model_count < DEPTH);

                accepted_read = read_in &&
                                (model_count > 0);

                // Model the read first, using the oldest item.
                if (accepted_read) begin
                    expected_dout = model_mem[model_rd_ptr];

                    if (model_rd_ptr == DEPTH - 1)
                        model_rd_ptr = 0;
                    else
                        model_rd_ptr = model_rd_ptr + 1;
                end

                // Model an accepted write.
                if (accepted_write) begin
                    model_mem[model_wr_ptr] = data_in;

                    if (model_wr_ptr == DEPTH - 1)
                        model_wr_ptr = 0;
                    else
                        model_wr_ptr = model_wr_ptr + 1;
                end

                // Update occupancy WITHOUT concatenating integers.
                if (accepted_write && !accepted_read)
                    model_count = model_count + 1;
                else if (!accepted_write && accepted_read)
                    model_count = model_count - 1;
                // Both or neither: occupancy does not change.
            end

            // Check after the active clock edge.
            @(posedge clk);
            #1;

            cycles = cycles + 1;

            if (count !== model_count) begin
                $display(
                    "ERROR cycle %0d: count=%0d expected=%0d",
                    cycles, count, model_count
                );
                errors = errors + 1;
            end

            if (full !== (model_count == DEPTH)) begin
                $display(
                    "ERROR cycle %0d: full=%b expected=%b",
                    cycles, full, (model_count == DEPTH)
                );
                errors = errors + 1;
            end

            if (empty !== (model_count == 0)) begin
                $display(
                    "ERROR cycle %0d: empty=%b expected=%b",
                    cycles, empty, (model_count == 0)
                );
                errors = errors + 1;
            end

            if (dout !== expected_dout) begin
                $display(
                    "ERROR cycle %0d: dout=%h expected=%h",
                    cycles, dout, expected_dout
                );
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        rst = 0;
        wr_en = 0;
        rd_en = 0;
        din = 0;

        errors = 0;
        cycles = 0;

        accepted_write = 0;
        accepted_read = 0;

        model_wr_ptr = 0;
        model_rd_ptr = 0;
        model_count = 0;
        expected_dout = 0;

        $display("========================================");
        $display(" SYNCHRONOUS FIFO TESTBENCH");
        $display(" DATA_WIDTH = %0d", DATA_WIDTH);
        $display(" DEPTH      = %0d", DEPTH);
        $display("========================================");

        // Test 1: Reset
        tick(1, 0, 0, 0);
        tick(1, 0, 0, 0);
        tick(0, 0, 0, 0);
        $display("Test 1: Reset completed");

        // Test 2: FIFO ordering
        tick(0, 1, 0, 8'h12);
        tick(0, 1, 0, 8'h34);
        tick(0, 1, 0, 8'h56);
        tick(0, 0, 1, 0);
        tick(0, 0, 1, 0);
        tick(0, 0, 1, 0);
        tick(0, 0, 0, 0);
        $display("Test 2: FIFO ordering completed");

        // Test 3: Fill to capacity
        for (i = 0; i < DEPTH; i = i + 1)
            tick(0, 1, 0, i);

        tick(0, 0, 0, 0);
        $display("Test 3: Full capacity completed");

        // Test 4: Overflow protection
        tick(0, 1, 0, 8'hEE);
        tick(0, 0, 0, 0);
        $display("Test 4: Overflow protection completed");

        // Test 5: Drain FIFO
        for (i = 0; i < DEPTH; i = i + 1)
            tick(0, 0, 1, 0);

        tick(0, 0, 0, 0);
        $display("Test 5: FIFO drain completed");

        // Test 6: Underflow protection
        tick(0, 0, 1, 0);
        tick(0, 0, 0, 0);
        $display("Test 6: Underflow protection completed");

        // Test 7: Pointer wraparound
        for (i = 0; i < DEPTH-2; i = i + 1)
            tick(0, 1, 0, i + 8'h80);

        for (i = 0; i < DEPTH-3; i = i + 1)
            tick(0, 0, 1, 0);

        for (i = 0; i < DEPTH-3; i = i + 1)
            tick(0, 1, 0, i + 8'hA0);

        while (model_count > 0)
            tick(0, 0, 1, 0);

        tick(0, 0, 0, 0);
        $display("Test 7: Pointer wraparound completed");

        // Test 8: Simultaneous read and write
        tick(0, 1, 0, 8'hA5);
        tick(0, 1, 0, 8'h5A);
        tick(0, 1, 1, 8'hC3);
        tick(0, 0, 1, 0);
        tick(0, 0, 1, 0);
        tick(0, 0, 0, 0);
        $display("Test 8: Simultaneous operations completed");

        // Test 9: Simultaneous operations while full.
        // At full, read is accepted and write is rejected.
        for (i = 0; i < DEPTH; i = i + 1)
            tick(0, 1, 0, i + 8'h20);

        tick(0, 1, 1, 8'hFE);

        while (model_count > 0)
            tick(0, 0, 1, 0);

        tick(0, 0, 0, 0);
        $display("Test 9: Full-boundary behavior completed");

        // Test 10: Simultaneous operations while empty.
        // At empty, write is accepted and read is rejected.
        tick(0, 1, 1, 8'hD7);
        tick(0, 0, 1, 0);
        tick(0, 0, 0, 0);
        $display("Test 10: Empty-boundary behavior completed");

        // Test 11: Randomized stress test
        for (i = 0; i < 500; i = i + 1) begin
            random_wr = $random;
            random_rd = $random;
            random_data = $random;

            tick(0, random_wr, random_rd, random_data);
        end

        // Drain remaining entries
        while (model_count > 0)
            tick(0, 0, 1, 0);

        tick(0, 0, 0, 0);
        $display("Test 11: Randomized stress completed");

        $display("----------------------------------------");
        $display("Cycles checked: %0d", cycles);
        $display("Errors: %0d", errors);

        if (errors == 0)
            $display("PASS: ALL CHECKS PASSED");
        else
            $display("FAIL: CHECKS FAILED");

        $display("========================================");

        $finish;
    end

endmodule
