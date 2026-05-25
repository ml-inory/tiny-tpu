`timescale 1ns/1ps

module PE (
    input wire enable,
    input wire clk,
    input wire rst,
    input wire start,
    input wire load_weight,
    input wire [7:0] input_in,
    input wire [7:0] weight_in,
    input wire [31:0] psum_in,
    output reg [7:0] input_out,
    output reg [7:0] weight_out,
    output reg [31:0] psum_out
);
    reg [7:0] weight_reg;

    always_ff @(posedge clk or posedge rst) begin
        if (enable) begin
            if (rst) begin
                weight_reg <= 0;
                input_out <= 0;
                weight_out <= 0;
                psum_out <= 0;
            end else if (load_weight) begin
                weight_reg <= weight_in;
            end else if (start) begin
                psum_out <= (input_in * weight_reg) + psum_in;
                input_out <= input_in;
                weight_out <= weight_reg;
            end
        end
    end
endmodule
