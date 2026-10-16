`timescale 1ns / 1ps

module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16,
    parameter ADDR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH),
    parameter COUNT_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH + 1)
)(
    input  wire                   clk,
    input  wire                   rst,

    input  wire                   wr_en,
    input  wire                   rd_en,
    input  wire [DATA_WIDTH-1:0]  din,

    output reg  [DATA_WIDTH-1:0]  dout,
    output wire                   full,
    output wire                   empty,
    output reg  [COUNT_WIDTH-1:0] count
);

    // Storage array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Circular pointers
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    // Accepted operations are determined from current status.
    wire do_write;
    wire do_read;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    assign do_write = wr_en && !full;
    assign do_read  = rd_en && !empty;

    // Synchronous FIFO controller
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= {ADDR_WIDTH{1'b0}};
            rd_ptr <= {ADDR_WIDTH{1'b0}};
            count  <= {COUNT_WIDTH{1'b0}};
            dout   <= {DATA_WIDTH{1'b0}};
        end
        else begin

            // Write operation
            if (do_write) begin
                mem[wr_ptr] <= din;

                if (wr_ptr == DEPTH - 1)
                    wr_ptr <= {ADDR_WIDTH{1'b0}};
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            // Read operation
            if (do_read) begin
                dout <= mem[rd_ptr];

                if (rd_ptr == DEPTH - 1)
                    rd_ptr <= {ADDR_WIDTH{1'b0}};
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            // Occupancy changes only when one operation is accepted
            case ({do_write, do_read})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

    // Configuration checks for simulation/elaboration.
    // DEPTH must be at least 2.
    initial begin
        if (DEPTH < 2) begin
            $display("ERROR: DEPTH must be at least 2.");
            $finish;
        end

        if (DATA_WIDTH < 1) begin
            $display("ERROR: DATA_WIDTH must be positive.");
            $finish;
        end

        if (ADDR_WIDTH < $clog2(DEPTH)) begin
            $display("ERROR: ADDR_WIDTH is too small for DEPTH.");
            $finish;
        end

        if (COUNT_WIDTH < $clog2(DEPTH + 1)) begin
            $display("ERROR: COUNT_WIDTH cannot represent DEPTH.");
            $finish;
        end
    end

endmodule