`timescale 1ns/1ps
`default_nettype none

module pe #(
    parameter int WEIGHT_WIDTH=16,
    parameter int INPUT_WIDTH=16,
    parameter int SUM_WIDTH=16
    ) (
    input logic clk,
    input logic rst,

    // North wires of PE
    input logic signed [INPUT_WIDTH-1:0] pe_psum_in, 
    input logic signed [WEIGHT_WIDTH-1:0] pe_weight_in,
    input logic pe_accept_w_in, 
    
    // West wires of PE
    input logic signed [INPUT_WIDTH-1:0] pe_input_in, 
    input logic pe_valid_in, 
    input logic pe_switch_in, 
    input logic pe_enabled,

    // South wires of the PE
    output logic signed [SUM_WIDTH-1:0] pe_psum_out,
    output logic signed [WEIGHT_WIDTH-1:0] pe_weight_out,

    // East wires of the PE
    output logic signed [INPUT_WIDTH-1:0] pe_input_out,
    output logic pe_valid_out,
    output logic pe_switch_out,
    output logic pe_overflow_out
);
    logic signed [WEIGHT_WIDTH-1:0] weight_reg_active;
    logic signed [WEIGHT_WIDTH-1:0] weight_reg_inactive;

    wire mult_overflow;
    logic signed [INPUT_WIDTH-1:0] mult_out;

    wire add_overflow;
    logic signed [SUM_WIDTH-1:0] mac_out;

    fxp_mul mult(
        .ina(pe_input_in),
        .inb(weight_reg_active),
        .out(mult_out),
        .overflow(mult_overflow)
    );

    fxp_add adder(
        .ina(mult_out),
        .inb(pe_psum_in),
        .out(mac_out),
        .overflow(add_overflow)
    );

    always_ff @(posedge clk or posedge rst) begin
        if (rst || !pe_enabled) begin
            pe_psum_out <= '0;
            pe_weight_out <= '0;
            pe_input_out <= '0;
            pe_valid_out <= 1'b0;
            pe_switch_out <= 1'b0;
            pe_overflow_out <= 1'b0;
            weight_reg_active <= '0;
            weight_reg_inactive <= '0;
        end else begin
            pe_valid_out <= pe_valid_in;
            pe_switch_out <= pe_switch_in;

            if (pe_accept_w_in) begin
                weight_reg_inactive <= pe_weight_in;
                pe_weight_out <= pe_weight_in;
            end else begin
                pe_weight_out <= '0;
            end

            if (pe_switch_in) begin
                weight_reg_active <= weight_reg_inactive;
            end

            if (pe_valid_in) begin
                pe_psum_out <= mac_out;
                pe_input_out <= pe_input_in;
                pe_overflow_out <= pe_overflow_out | mult_overflow | add_overflow;
            end else begin
                pe_psum_out <= 0;
                pe_input_out <= 0;
            end
        end
    end
endmodule
