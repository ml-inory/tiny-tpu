module MAC #(parameter WIDTH = 8)
(
    input wire clk,
    input wire rst_n,
    input wire clear,
    input wire enable,
    input wire valid_in,
    input reg [WIDTH-1:0] a_in,
    input reg [WIDTH-1:0] b_in,
    output reg [4*WIDTH-1:0] acc_out,
    output wire valid_out
);
    reg [2*WIDTH-1:0] mul_out;
    
    
endmodule