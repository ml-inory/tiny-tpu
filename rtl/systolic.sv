`timescale 1ns/1ps
`default_nettype none

// 2x2 systolic array
module systolic #(
    parameter int SYSTOLIC_ARRAY_WIDTH = 2,
    parameter int DATA_BIT_WIDTH = 16
)(
    input logic clk,
    input logic rst,

    // input signals from left side of systolic array
    input logic [DATA_BIT_WIDTH - 1:0] sys_data_in [SYSTOLIC_ARRAY_WIDTH - 1:0],
    input logic sys_start [SYSTOLIC_ARRAY_WIDTH - 1:0],   // start signal for row 1

    output logic [DATA_BIT_WIDTH - 1:0] sys_data_out,
    output wire sys_valid_out [SYSTOLIC_ARRAY_WIDTH - 1:0], 

    // input signals from top of systolic array
    input logic [DATA_BIT_WIDTH - 1:0] sys_weight_in [SYSTOLIC_ARRAY_WIDTH - 1:0], 
    input logic sys_accept_w [SYSTOLIC_ARRAY_WIDTH - 1:0],             // accept weight signal propagates only from top to bottom in column 1

    input logic sys_switch_in,               // switch signal copies weight from shadow buffer to active buffer. propagates from top left to bottom right

    input logic [SYSTOLIC_ARRAY_WIDTH - 1:0] ub_rd_col_size_in,
    input logic ub_rd_col_size_valid_in
);

    
endmodule