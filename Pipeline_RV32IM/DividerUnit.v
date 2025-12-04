`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/01/2025 08:19:42 AM
// Design Name: 
// Module Name: DividerUnit
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

module DividerUnit(
    input clk, rst,
    input is_div_op_E,
    input [4:0] ALUCtrl,
    input [`REG_SIZE:0] A, B,
    input [4:0] rd,           
    input [`REG_SIZE:0] pc,   
    input [31:0] inst,        
    
    output [`REG_SIZE:0] result,
    output [4:0] rd_out,      
    output [`REG_SIZE:0] pc_out,   
    output [`REG_SIZE:0] inst_out,  
    output valid,              
    output reg stall
);
wire is_signed = (ALUCtrl == `ALU_DIV) | (ALUCtrl == `ALU_REM);

// Pipeline delay registers for control signals (8 stages)
integer i;
reg [4:0] rd_pipe [0:7];
reg [`REG_SIZE:0] pc_pipe [0:7];
reg [31:0] inst_pipe [0:7];
reg [4:0] aluctrl_pipe [0:7];  
reg valid_pipe [0:7];           
reg [3:0] stall_counter;

// Wires for divider outputs
wire [`REG_SIZE:0] Q, R;

always @(negedge clk or posedge rst) begin
    if (rst) begin
        stall <= 1'b0;
        stall_counter <= 4'd0;
    end else begin
        if (is_div_op_E) begin
            stall <= 1'b1;
            stall_counter <= 4'd1;   
        end else if (stall) begin
            stall_counter <= stall_counter + 1'b1;
            if (stall_counter == 4'd7) begin
                stall <= 1'b0;        
                stall_counter <= 4'd0;
            end
        end else begin
            stall_counter <= 4'd0;
        end

    end
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 8; i = i + 1) begin
            rd_pipe[i] <= 5'b0;
            pc_pipe[i] <= 32'b0;
            inst_pipe[i] <= 32'b0;
            aluctrl_pipe[i] <= 5'b0;
            valid_pipe[i] <= 1'b0;
        end
    end else begin
        // Always shift stages 1-7
        for (i = 1; i < 8; i = i + 1) begin
            rd_pipe[i] <= rd_pipe[i-1];
            pc_pipe[i] <= pc_pipe[i-1];
            inst_pipe[i] <= inst_pipe[i-1];
            aluctrl_pipe[i] <= aluctrl_pipe[i-1];
            valid_pipe[i] <= valid_pipe[i-1];
        end
        
        // Stage 0: capture new inputs only when div operation
        if (is_div_op_E) begin
            rd_pipe[0] <= rd;
            pc_pipe[0] <= pc;
            inst_pipe[0] <= inst;
            aluctrl_pipe[0] <= ALUCtrl;
            valid_pipe[0] <= 1'b1;
            
        end else begin
            rd_pipe[0] <= 5'b0;
            pc_pipe[0] <= 32'b0;
            inst_pipe[0] <= 32'b0;
            aluctrl_pipe[0] <= 5'b0;
            valid_pipe[0] <= 1'b0;
        end
    end
end

// Output the delayed signals from the last stage
assign rd_out = rd_pipe[7];
assign pc_out = pc_pipe[7];
assign inst_out = inst_pipe[7];
assign valid = valid_pipe[7];  // Valid signal from pipeline

// Select result based on delayed ALUCtrl
wire [4:0] aluctrl_delayed = aluctrl_pipe[7];
wire is_rem_op = (aluctrl_delayed == `ALU_REM) | (aluctrl_delayed == `ALU_REMU);

assign result = is_rem_op ? R : Q;

// Divider pipeline instance
DividerPipeline divider_inst (
    .clk         (clk),
    .rst         (rst),
    .is_signed   (is_signed),   
    .i_dividend  (A),
    .i_divisor   (B),
    .o_remainder (R),
    .o_quotient  (Q)
);

endmodule