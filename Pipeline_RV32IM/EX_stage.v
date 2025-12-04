`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/27/2025 04:33:09 PM
// Design Name: 
// Module Name: EX_stage
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
module EX_stage(
    input clk, rst,
    // From ID_Stage
    input is_div_op_E,
    input [`REG_SIZE:0] rs1_data_E, rs2_data_E, immediate_E,
    input [`REG_SIZE:0] pc_current_E, inst_E,
    input [4:0] rd_E,
    input [4:0] ALUCtrl_E,
    input RegWrite_E, ALUSrc_E, MemWrite_E, MemToReg_E, MemRead_E, Branch_E,
    input Jal_E, Jalr_E,
    input [2:0] BranchType_E, StoreType_E, LoadType_E,
    
    // From data forwarding
    input [`REG_SIZE:0] rd_data_W,
    input [1:0] ForwardA, ForwardB,
    
    output div_stall,
    output reg [`REG_SIZE:0] pc_current_M, inst_M,
    output reg [`REG_SIZE:0] ExeResult_M,
    output [`REG_SIZE:0] PCTarget,
    output PCSrc,
    output reg [`REG_SIZE:0] rs2_data_M,
    output reg [4:0] rd_M,
    output reg [2:0] StoreType_M, LoadType_M,
    output reg  RegWrite_M, MemWrite_M, MemToReg_M, MemRead_M
);

reg [`REG_SIZE:0] pc_current_reg, inst_reg;
reg [`REG_SIZE:0] ALUResult_reg;
reg [`REG_SIZE:0] rs2_data_reg;
reg [4:0] rd_reg;
reg [2:0] StoreType_reg, LoadType_reg;
reg  RegWrite_reg, MemWrite_reg, MemToReg_reg, MemRead_reg;
reg stall_Ex;
reg [2:0] stall_counter;

wire [`REG_SIZE:0] div_result, ALUResult;
wire [`REG_SIZE:0] SrcA, SrcB, SrcB_tmp;
wire LessThan, LessThanU, Zero;
wire [4:0] div_rd_out;      
wire [`REG_SIZE:0] div_pc_out;   
wire [`REG_SIZE:0] div_inst_out;   
wire div_valid;             

mux3X1 srca_mux (
    .a(rs1_data_E),
    .b(rd_data_W),
    .c(ExeResult_M),
    .sel(ForwardA),
    .data_out(SrcA)
);

mux3X1 srcb_mux (
    .a(rs2_data_E),
    .b(rd_data_W),
    .c(ExeResult_M),
    .sel(ForwardB),
    .data_out(SrcB_tmp)
);

mux2X1 alu_mux (
    .a(SrcB_tmp),
    .b(immediate_E),
    .sel(ALUSrc_E),
    .data_out(SrcB)
);

ALU alu (
    .A(SrcA),
    .B(SrcB),
    .ALUCtrl(ALUCtrl_E),
    .ALUResult(ALUResult),
    .Zero(Zero),
    .LessThan(LessThan),
    .LessThanU(LessThanU)
);

DividerUnit div_inst (
    .clk(clk),
    .rst(rst),
    .is_div_op_E(is_div_op_E),
    .ALUCtrl(ALUCtrl_E),
    .A(SrcA),
    .B(SrcB),
    .rd(rd_E),
    .pc(pc_current_E),
    .inst(inst_E),
    
    .result(div_result),
    .rd_out(div_rd_out),     
    .pc_out(div_pc_out),  
    .inst_out(div_inst_out),
    .valid(div_valid),
    .stall(div_stall)
);

PCUpdateUnit pc_update_unit_inst (
    .rs1_data_E    (SrcA),   
    .pc_current_E  (pc_current_E),   
    .immediate_E   (immediate_E),   

    .Branch_E      (Branch_E),   
    .Jal_E         (Jal_E),   
    .Jalr_E        (Jalr_E),   
    .BranchType_E  (BranchType_E),   

    .Zero          (Zero),   
    .LessThan      (LessThan),   
    .LessThanU     (LessThanU),   

    .PCTarget      (PCTarget),   
    .PCSrc         (PCSrc)    
);

always@(posedge clk) begin
    if (Jalr_E || Jal_E)
        ALUResult_reg <= pc_current_E + 32'd4;
    else 
        ALUResult_reg <= ALUResult;
end

// Div stall
always @(posedge clk or posedge rst) begin
    if (rst) begin
        stall_Ex      <= 1'b0;
        stall_counter <= 3'd0;
    end 
    else begin
        
        if (div_stall) begin                       // b?t ??u stall do DIV
            stall_Ex <= 1'b1;
            if (stall_counter < 3'd7)
                stall_counter <= stall_counter + 1;
            else begin                              // khi ?ã stall ?? 6 chu k?
                stall_Ex      <= 1'b0;
                stall_counter <= 3'd0;
            end
        end 
        
        else begin                                  // không còn div_stall ? clear
            stall_Ex      <= 1'b0;
            stall_counter <= 3'd0;
        end
    end
end

// Propagate signal
always@(posedge clk or posedge rst) begin
    if (rst) begin
        RegWrite_reg      <= 0;
        MemWrite_reg      <= 0;
        MemToReg_reg      <= 0;
        MemRead_reg       <= 0;
        StoreType_reg     <= 0;
        LoadType_reg      <= 0;
        rd_reg            <= 4'd0;
        rs2_data_reg      <= 32'd0;
        pc_current_reg    <= 32'd0;
        inst_reg          <= 32'd0;
    end else begin
        RegWrite_reg      <= RegWrite_E;
        MemWrite_reg      <= MemWrite_E;
        MemToReg_reg      <= MemToReg_E;
        MemRead_reg       <= MemRead_E;
        StoreType_reg     <= StoreType_E;
        LoadType_reg      <= LoadType_E;
        rd_reg            <= rd_E;
        rs2_data_reg      <= SrcB_tmp;
        pc_current_reg    <= pc_current_E;
        inst_reg          <= inst_E;
    end
end

// Final signal
always@(*) begin
    if (rst || stall_Ex) begin
        RegWrite_M      <= 0;
        MemWrite_M      <= 0;
        MemToReg_M      <= 0;
        MemRead_M       <= 0;
        StoreType_M     <= 0;
        LoadType_M      <= 0;
        rd_M            <= 4'd0;
        rs2_data_M      <= 32'd0;
        pc_current_M    <= 32'd0;
        inst_M          <= 32'd0;
    end else if (!div_valid) begin
        RegWrite_M      <= RegWrite_reg;
        MemWrite_M      <= MemWrite_reg;
        MemToReg_M      <= MemToReg_reg;
        MemRead_M       <= MemRead_reg;
        StoreType_M     <= StoreType_reg;
        LoadType_M      <= LoadType_reg;
        rd_M            <= rd_reg;
        rs2_data_M      <= rs2_data_reg;
        pc_current_M    <= pc_current_reg;
        inst_M          <= inst_reg;
        ExeResult_M     <= ALUResult_reg;
    end else if (div_valid) begin
        RegWrite_M      <= 1'b1;
        MemWrite_M      <= 1'b0;
        MemToReg_M      <= 1'b0;
        MemRead_M       <= 1'b0;
        StoreType_M     <= 3'b0;
        LoadType_M      <= 3'b0;
        rd_M            <= div_rd_out;
        rs2_data_M      <= 32'b0;
        pc_current_M    <= div_pc_out;
        inst_M          <= div_inst_out;
        ExeResult_M     <= div_result;
    end 
end

endmodule
