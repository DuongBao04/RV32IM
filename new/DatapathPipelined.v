`timescale 1ns / 1ns
`include "defines.vh"

// Don't forget your old codes
//`include "cla.v"
//`include "DividerUnsignedPipelined.v"

module DatapathPipelined (
  input                     clk,
  input                     rst,
  output     [ `REG_SIZE:0] pc_to_imem,
  input      [`INST_SIZE:0] inst_from_imem,
  // dmem is read/write
  output reg [ `REG_SIZE:0] addr_to_dmem,
  input      [ `REG_SIZE:0] load_data_from_dmem,
  output reg [ `REG_SIZE:0] store_data_to_dmem,
  output reg [         3:0] store_we_to_dmem,
  output reg                halt,
  // The PC of the inst currently in Writeback. 0 if not a valid inst.
  output reg [ `REG_SIZE:0] trace_writeback_pc,
  // The bits of the inst currently in Writeback. 0 if not a valid inst.
  output reg [`INST_SIZE:0] trace_writeback_inst
);
  // cycle counter, not really part of any stage but useful for orienting within GtkWave
  // do not rename this as the testbench uses this value
  reg [`REG_SIZE:0] cycles_current;
  always @(posedge clk) begin
    if (rst) begin
      cycles_current <= 0;
    end else begin
      cycles_current <= cycles_current + 1;
    end
  end
  
  /***************/
  /* Signal Declaration */
  /***************/
  // Program Counter
  wire  [`REG_SIZE:0] f_pc_current;
  wire [`REG_SIZE:0] f_inst;
  wire PCSrc;
  wire [`REG_SIZE:0] PCTarget;
  
  // Decode -> Execute wire
  wire [4:0] rs1_E, rs2_E, rd_E;
  wire [`REG_SIZE:0] rs1_data_E, rs2_data_E, immediate_E;
  wire [`REG_SIZE:0] pc_current_E, inst_E;
  wire [4:0] ALUCtrl_E;
  wire RegWrite_E, ALUSrc_E, MemWrite_E, MemToReg_E, Branch_E, MemRead_E;
  wire d_halt;
  wire [2:0] BranchType_E, StoreType_E, LoadType_E;
  
  // Execute -> Mem wire
  wire [4:0] rd_M;
  wire [`REG_SIZE:0] ExeResult_M, rs2_data_M;
  wire [`REG_SIZE:0] pc_current_M, inst_M;
  wire RegWrite_M, MemWrite_M, MemToReg_M, MemRead_M;
  wire [2:0] StoreType_M, LoadType_M;
  
  // Memory -> Writeback wires
  wire [`REG_SIZE:0] rd_data_W;
  reg [4:0] rd_W;
  reg RegWrite_W;
  reg [`REG_SIZE:0] dmem_rdata, ExeResult_W, dmem_rdata_W;
  reg MemToReg_W;
  
  // Forwarding wires
  wire [1:0] ForwardA, ForwardB;
  
  // Hazard detection
  wire IF_Write, ID_Flush;
  wire div_stall, div_overlap;
  
  /***************/
  /* FETCH STAGE */
  /***************/
  IF_Stage Fetch (
    .clk(clk),
    .rst(rst),
    .PCSrc(PCSrc),
    .PCTarget(PCTarget),
    .IF_Write(IF_Write),
    .f_pc_current(f_pc_current)
  );
  
  // send PC to imem
  assign pc_to_imem = (rst) ? 32'd0 : f_pc_current;
  assign f_inst = (rst) ? 32'd0 : inst_from_imem;

  /****************/
  /* DECODE STAGE */
  /****************/
  ID_Stage Decode (
    // ---------------- IF to ID ----------------
    .clk            (clk),
    .rst            (rst),
    .f_inst         (f_inst),
    .f_pc_current   (f_pc_current),
    .ID_Flush       (ID_Flush),

    // ---------------- WB to ID ----------------
    .rd_W           (rd_W),
    .RegWrite_W     (RegWrite_W),
    .rd_data_W      (rd_data_W),

    // ---------------- Div instruction handle---
    .div_overlap    (div_overlap),
    .is_div_op_E    (is_div_op_E),
    
    // ---------------- ID to EX ----------------
    .rs1_data_E     (rs1_data_E),
    .rs2_data_E     (rs2_data_E),
    .immediate_E    (immediate_E),
    .pc_current_E   (pc_current_E),
    .inst_E         (inst_E),

    .ALUCtrl_E      (ALUCtrl_E),
    .rd_E           (rd_E),
    .rs1_E          (rs1_E),
    .rs2_E          (rs2_E),

    .RegWrite_E     (RegWrite_E),
    .ALUSrc_E       (ALUSrc_E),
    .MemWrite_E     (MemWrite_E),
    .MemToReg_E     (MemToReg_E),
    .MemRead_E      (MemRead_E),
    .Branch_E       (Branch_E),
    .halt_E         (d_halt),

    .Jal_E          (Jal_E),
    .Jalr_E         (Jalr_E),

    .BranchType_E   (BranchType_E),
    .StoreType_E    (StoreType_E),
    .LoadType_E     (LoadType_E)
  );
  always@(*) begin
    halt <= d_halt;
  end

  // TODO: your code here, though you will also need to modify some of the code above
  // TODO: the testbench requires that your register file instance is named `rf`
  /****************/
  /* EXECUTE STAGE */
  /****************/
    EX_stage Execute (
        .clk(clk), 
        .rst(rst),
    
        // From ID stage
        .pc_current_E(pc_current_E),
        .inst_E(inst_E),
        .rs1_data_E(rs1_data_E),
        .rs2_data_E(rs2_data_E),
        .immediate_E(immediate_E),
        .rd_E(rd_E),
        .ALUCtrl_E(ALUCtrl_E),
        .RegWrite_E(RegWrite_E),
        .ALUSrc_E(ALUSrc_E),
        .MemWrite_E(MemWrite_E),
        .MemToReg_E(MemToReg_E),
        .MemRead_E(MemRead_E),
        .Branch_E(Branch_E),
        .Jal_E(Jal_E),
        .Jalr_E(Jalr_E),
        .BranchType_E(BranchType_E),
        .StoreType_E(StoreType_E),
        .LoadType_E(LoadType_E),
        .is_div_op_E(is_div_op_E),
    
        // From data forwarding
        .rd_data_W(rd_data_W),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
    
        // Outputs
        .div_stall(div_stall),
        .pc_current_M(pc_current_M),
        .inst_M(inst_M),
        .ExeResult_M(ExeResult_M),
        .PCTarget(PCTarget),
        .PCSrc(PCSrc),
        .rs2_data_M(rs2_data_M),
        .rd_M(rd_M),
        .StoreType_M(StoreType_M),
        .LoadType_M(LoadType_M),
        .RegWrite_M(RegWrite_M),
        .MemWrite_M(MemWrite_M),
        .MemToReg_M(MemToReg_M),
        .MemRead_M(MemRead_M)
    );


  /****************/
  /* MEM STAGE */
  /****************/
  reg [7:0]  load_byte;
  reg [15:0] load_half;
  
  always@(*) begin
    addr_to_dmem  <= ExeResult_M;
    load_byte     <= load_data_from_dmem[7:0];
    load_half     <= load_data_from_dmem[15:0];
    store_we_to_dmem   <= 4'b0000;
    store_data_to_dmem <= rs2_data_M;
    
    if (MemRead_M) begin
        case (LoadType_M)
            `LB:  dmem_rdata <= {{24{load_byte[7]}},  load_byte};
            `LBU: dmem_rdata <= {24'd0,               load_byte};
            `LH:  dmem_rdata <= {{16{load_half[15]}}, load_half};
            `LHU: dmem_rdata <= {16'd0,               load_half};
            `LW:  dmem_rdata <= load_data_from_dmem;
            default: dmem_rdata <= 32'd0;
        endcase
    end else dmem_rdata <= 32'd0;
    
    // STORE
    if (MemWrite_M) begin
        case (StoreType_M)
            `SB: store_we_to_dmem <= 4'b0001;
            `SH: store_we_to_dmem <= 4'b0011;
            `SW: store_we_to_dmem <= 4'b1111;
            default: store_we_to_dmem <= 4'b0000;
        endcase
    end else store_we_to_dmem <= 4'b0000;
  end

  always@(posedge clk or posedge rst) begin
    if (rst) begin
        dmem_rdata_W<= 0;
        ExeResult_W <= 0;
        rd_W        <= 0;
        MemToReg_W  <= 0;
        RegWrite_W  <= 0;
        trace_writeback_pc   <= 0;
        trace_writeback_inst <= 0;
    end else begin
        dmem_rdata_W<= dmem_rdata;
        ExeResult_W <= ExeResult_M;
        rd_W        <= rd_M;
        MemToReg_W  <= MemToReg_M;
        RegWrite_W  <= RegWrite_M;
        trace_writeback_pc   <= pc_current_M;
        trace_writeback_inst <= inst_M;
    end
  end
  
  /****************/
  /* WB STAGE */
  /****************/
  mux2X1 WB (
    .a(ExeResult_W),
    .b(dmem_rdata_W),
    .sel(MemToReg_W),
    .data_out(rd_data_W)
  );
  
  /****************/
  /* Data Forwarding */
  /****************/
  ForwardingUnit FU (
    .rst(rst),
    .RegWrite_M(RegWrite_M),
    .RegWrite_W(RegWrite_W),

    .Rd_M(rd_M),
    .Rd_W(rd_W),

    .Rs1_E(rs1_E),
    .Rs2_E(rs2_E),

    .ForwardA(ForwardA),   
    .ForwardB(ForwardB)    
);

  /****************/
  /* Hazard detection */
  /****************/
  HazardDetectionUnit HU (
    .rst(rst), 
    .MemRead_E(MemRead_E),
    .PCSrc(PCSrc),
    .div_stall(div_stall),     
    .div_overlap(div_overlap),          
    .rd_E(rd_E),              
    .rs1_D(f_inst[19:15]), .rs2_D(f_inst[24:20]),      
    .IF_Write(IF_Write),        
    .ID_Flush(ID_Flush)            
  );
endmodule


