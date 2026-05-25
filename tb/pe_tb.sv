`timescale 1ns/1ps

module pe_tb;
    logic enable;
    logic clk;
    logic rst;
    logic start;
    logic load_weight;
    logic [7:0] input_in;
    logic [7:0] weight_in;
    logic [31:0] psum_in;
    logic [7:0] input_out;
    logic [7:0] weight_out;
    logic [31:0] psum_out;

    int checks;
    int errors;

    PE dut (
        .enable(enable),
        .clk(clk),
        .rst(rst),
        .start(start),
        .load_weight(load_weight),
        .input_in(input_in),
        .weight_in(weight_in),
        .psum_in(psum_in),
        .input_out(input_out),
        .weight_out(weight_out),
        .psum_out(psum_out)
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

    task automatic check_u32(input string name, input logic [31:0] got, input logic [31:0] expected);
        checks++;
        if (got !== expected) begin
            errors++;
            $display("ERROR %s: got 0x%08h expected 0x%08h at %0t", name, got, expected, $time);
        end
    endtask

    task automatic check_u8(input string name, input logic [7:0] got, input logic [7:0] expected);
        checks++;
        if (got !== expected) begin
            errors++;
            $display("ERROR %s: got 0x%02h expected 0x%02h at %0t", name, got, expected, $time);
        end
    endtask

    task automatic load_weight_value(input logic [7:0] weight);
        @(negedge clk);
        load_weight = 1'b1;
        start = 1'b0;
        weight_in = weight;
        @(posedge clk);
        #1;
        @(negedge clk);
        load_weight = 1'b0;
    endtask

    task automatic run_mac(
        input logic [7:0] activation,
        input logic [31:0] psum,
        input logic [7:0] expected_weight
    );
        logic [31:0] expected_psum;

        expected_psum = psum + (activation * expected_weight);

        @(negedge clk);
        input_in = activation;
        psum_in = psum;
        start = 1'b1;
        load_weight = 1'b0;
        @(posedge clk);
        #1;

        check_u8("input_out", input_out, activation);
        check_u8("weight_out", weight_out, expected_weight);
        check_u32("psum_out", psum_out, expected_psum);

        @(negedge clk);
        start = 1'b0;
    endtask

    initial begin
        checks = 0;
        errors = 0;

        enable = 1'b1;
        rst = 1'b0;
        start = 1'b0;
        load_weight = 1'b0;
        input_in = '0;
        weight_in = '0;
        psum_in = '0;

        rst = 1'b1;
        #1;
        check_u8("reset input_out", input_out, 8'h00);
        check_u8("reset weight_out", weight_out, 8'h00);
        check_u32("reset psum_out", psum_out, 32'h00000000);
        @(negedge clk);
        rst = 1'b0;

        load_weight_value(8'd3);
        run_mac(8'd7, 32'd10, 8'd3);
        run_mac(8'd0, 32'd1234, 8'd3);

        load_weight_value(8'd255);
        run_mac(8'd2, 32'd1, 8'd255);

        @(negedge clk);
        enable = 1'b0;
        input_in = 8'd9;
        psum_in = 32'd100;
        weight_in = 8'd4;
        load_weight = 1'b1;
        start = 1'b1;
        @(posedge clk);
        #1;
        check_u8("disabled input_out holds", input_out, 8'd2);
        check_u8("disabled weight_out holds", weight_out, 8'd255);
        check_u32("disabled psum_out holds", psum_out, 32'd511);

        enable = 1'b1;
        load_weight = 1'b0;
        start = 1'b0;

        if (errors == 0) begin
            $display("PASS pe_tb: %0d checks", checks);
            $finish;
        end else begin
            $display("FAIL pe_tb: %0d errors out of %0d checks", errors, checks);
            $fatal(1);
        end
    end
endmodule
