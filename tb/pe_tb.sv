`timescale 1ns/1ps
`default_nettype none

module pe_tb;
    localparam int WEIGHT_WIDTH = 16;
    localparam int INPUT_WIDTH = 16;
    localparam int SUM_WIDTH = 16;

    logic clk;
    logic rst;

    logic signed [SUM_WIDTH-1:0] pe_psum_in;
    logic signed [WEIGHT_WIDTH-1:0] pe_weight_in;
    logic pe_accept_w_in;

    logic signed [INPUT_WIDTH-1:0] pe_input_in;
    logic pe_valid_in;
    logic pe_switch_in;
    logic pe_enabled;

    logic signed [SUM_WIDTH-1:0] pe_psum_out;
    logic signed [WEIGHT_WIDTH-1:0] pe_weight_out;

    logic signed [INPUT_WIDTH-1:0] pe_input_out;
    logic pe_valid_out;
    logic pe_switch_out;
    logic pe_overflow_out;

    int checks;
    int errors;

    pe #(
        .WEIGHT_WIDTH(WEIGHT_WIDTH),
        .INPUT_WIDTH(INPUT_WIDTH),
        .SUM_WIDTH(SUM_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .pe_psum_in(pe_psum_in),
        .pe_weight_in(pe_weight_in),
        .pe_accept_w_in(pe_accept_w_in),
        .pe_input_in(pe_input_in),
        .pe_valid_in(pe_valid_in),
        .pe_switch_in(pe_switch_in),
        .pe_enabled(pe_enabled),
        .pe_psum_out(pe_psum_out),
        .pe_weight_out(pe_weight_out),
        .pe_input_out(pe_input_out),
        .pe_valid_out(pe_valid_out),
        .pe_switch_out(pe_switch_out),
        .pe_overflow_out(pe_overflow_out)
    );

`ifdef PE_TB_WAVES
    initial begin
        $dumpfile("tb/build/pe_tb.vcd");
        $dumpvars(0, pe_tb);
    end
`endif

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task automatic check_bit(input string name, input logic got, input logic expected);
        checks++;
        if (got !== expected) begin
            errors++;
            $display("ERROR %s: got %0b expected %0b at %0t", name, got, expected, $time);
        end
    endtask

    task automatic check_s16(input string name, input logic signed [15:0] got, input logic signed [15:0] expected);
        checks++;
        if (got !== expected) begin
            errors++;
            $display(
                "ERROR %s: got 0x%04h (%0d) expected 0x%04h (%0d) at %0t",
                name,
                got,
                got,
                expected,
                expected,
                $time
            );
        end
    endtask

    task automatic drive_idle;
        pe_psum_in = '0;
        pe_weight_in = '0;
        pe_accept_w_in = 1'b0;
        pe_input_in = '0;
        pe_valid_in = 1'b0;
        pe_switch_in = 1'b0;
    endtask

    task automatic check_all_zero(input string prefix);
        check_s16({prefix, " psum_out"}, pe_psum_out, 16'sh0000);
        check_s16({prefix, " weight_out"}, pe_weight_out, 16'sh0000);
        check_s16({prefix, " input_out"}, pe_input_out, 16'sh0000);
        check_bit({prefix, " valid_out"}, pe_valid_out, 1'b0);
        check_bit({prefix, " switch_out"}, pe_switch_out, 1'b0);
        check_bit({prefix, " overflow_out"}, pe_overflow_out, 1'b0);
    endtask

    task automatic load_inactive_weight(input logic signed [15:0] weight);
        @(negedge clk);
        drive_idle();
        pe_weight_in = weight;
        pe_accept_w_in = 1'b1;

        @(posedge clk);
        #1;
        check_s16("load weight_out", pe_weight_out, weight);
        check_bit("load valid_out", pe_valid_out, 1'b0);
        check_bit("load switch_out", pe_switch_out, 1'b0);

        @(negedge clk);
        drive_idle();

        @(posedge clk);
        #1;
        check_s16("weight_out clears when not accepting", pe_weight_out, 16'sh0000);
    endtask

    task automatic switch_active_weight;
        @(negedge clk);
        drive_idle();
        pe_switch_in = 1'b1;

        @(posedge clk);
        #1;
        check_bit("switch valid_out", pe_valid_out, 1'b0);
        check_bit("switch switch_out", pe_switch_out, 1'b1);
        check_s16("switch psum_out", pe_psum_out, 16'sh0000);
        check_s16("switch input_out", pe_input_out, 16'sh0000);

        @(negedge clk);
        drive_idle();
    endtask

    task automatic run_mac(
        input logic signed [15:0] activation,
        input logic signed [15:0] psum,
        input logic signed [15:0] expected_psum,
        input logic expected_overflow
    );
        @(negedge clk);
        drive_idle();
        pe_input_in = activation;
        pe_psum_in = psum;
        pe_valid_in = 1'b1;

        @(posedge clk);
        #1;
        check_bit("mac valid_out", pe_valid_out, 1'b1);
        check_bit("mac switch_out", pe_switch_out, 1'b0);
        check_s16("mac input_out", pe_input_out, activation);
        check_s16("mac weight_out", pe_weight_out, 16'sh0000);
        check_s16("mac psum_out", pe_psum_out, expected_psum);
        check_bit("mac overflow_out", pe_overflow_out, expected_overflow);

        @(negedge clk);
        drive_idle();
    endtask

    initial begin
        checks = 0;
        errors = 0;

        rst = 1'b0;
        pe_enabled = 1'b1;
        drive_idle();

        rst = 1'b1;
        #1;
        check_all_zero("reset");

        @(negedge clk);
        rst = 1'b0;

        // Without a switch, the active weight remains zero and the MAC passes psum through.
        load_inactive_weight(16'sh0180); // 1.5 in signed 8.8 fixed-point.
        run_mac(16'sh0200, 16'sh0100, 16'sh0100, 1'b0);

        switch_active_weight();
        run_mac(16'sh0200, 16'sh0040, 16'sh0340, 1'b0); // 2.0 * 1.5 + 0.25 = 3.25.

        // Loading the inactive weight must not disturb the active weight until switch_in is asserted.
        load_inactive_weight(16'shff00); // -1.0
        run_mac(16'sh0100, 16'sh0000, 16'sh0180, 1'b0); // Still using active weight 1.5.

        switch_active_weight();
        run_mac(16'sh0200, 16'sh0000, 16'shfe00, 1'b0); // 2.0 * -1.0 = -2.0.

        // Positive overflow saturates the fixed-point multiply and latches overflow_out.
        load_inactive_weight(16'sh0200); // 2.0
        switch_active_weight();
        run_mac(16'sh7f00, 16'sh0000, 16'sh7fff, 1'b1);
        run_mac(16'sh0100, 16'sh0000, 16'sh0200, 1'b1);

        @(negedge clk);
        pe_enabled = 1'b0;
        pe_weight_in = 16'sh0300;
        pe_accept_w_in = 1'b1;
        pe_input_in = 16'sh0100;
        pe_psum_in = 16'sh0100;
        pe_valid_in = 1'b1;
        pe_switch_in = 1'b1;

        @(posedge clk);
        #1;
        check_all_zero("disabled");

        @(negedge clk);
        pe_enabled = 1'b1;
        drive_idle();

        run_mac(16'sh0100, 16'sh0080, 16'sh0080, 1'b0);

        if (errors == 0) begin
            $display("PASS pe_tb: %0d checks", checks);
            $finish;
        end else begin
            $display("FAIL pe_tb: %0d errors out of %0d checks", errors, checks);
            $fatal(1);
        end
    end
endmodule

`default_nettype wire
