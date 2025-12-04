`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 05:34:36 PM
// Design Name: 
// Module Name: IF_Stage
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.vh"
module IF_Stage(
    input clk, rst,
    input PCSrc, IF_Write,
    input [`REG_SIZE:0] PCTarget,
    
    output reg [`REG_SIZE:0] f_pc_current
);
wire [`REG_SIZE:0] next_pc;

// mux before the PC block
mux2X1 pc_mux (
    .a(f_pc_current + 32'd4),
    .b(PCTarget),
    .sel(PCSrc),
    .data_out(next_pc)
);

// program counter
always @(posedge clk or posedge rst) begin
    if (rst) begin
        f_pc_current <= 32'd0;
    end else if (IF_Write) begin
        f_pc_current <= next_pc;
    end
end


endmodule
