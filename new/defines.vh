// registers are 32 bits in RV32
`define REG_SIZE 31

// RV opcodes are 7 bits
`define OPCODE_SIZE 6

// inst. are 32 bits in RV32IM
`define INST_SIZE 31

// opcodes - see section 19 of RiscV spec
`define OpLoad     7'b00_000_11
`define OpStore    7'b01_000_11
`define OpBranch   7'b11_000_11
`define OpJalr     7'b11_001_11
`define OpMiscMem  7'b00_011_11
`define OpJal      7'b11_011_11

`define OpRegImm   7'b00_100_11
`define OpRegReg   7'b01_100_11
`define OpEnviron  7'b11_100_11

`define OpAuipc    7'b00_101_11
`define OpLui      7'b01_101_11

`define DIVIDER_STAGES 8

// ALU Control
`define ALU_AND             5'b00000   
`define ALU_OR              5'b00001   
`define ALU_ADD             5'b00010   
`define ALU_SUB             5'b00011   
`define ALU_LSHIFT_LEFT     5'b00100   
`define ALU_LSHIFT_RIGHT    5'b00101   
`define ALU_ASHIFT_RIGHT    5'b00110   
`define ALU_XOR             5'b00111   
`define ALU_MUL             5'b01000
`define ALU_MULH            5'b01001
`define ALU_MULSU           5'b01010
`define ALU_MULU            5'b01011
`define ALU_DIV             5'b01100
`define ALU_DIVU            5'b01101
`define ALU_REM             5'b01110
`define ALU_REMU            5'b01111
`define ALU_SLT             5'b10000
`define ALU_SLTU            5'b10001
`define NOP                 5'b11111

// Branch Types
`define BEQ     3'b001
`define BNE     3'b010
`define BLT     3'b011
`define BGE     3'b100
`define BLTU    3'b101
`define BGEU    3'b110

//Store Types
`define SB      3'b001
`define SH      3'b010
`define SW      3'b100

//Jump Types
`define JAL     1'b0
`define JALR    1'b1

//Load Types
`define LB      3'b000
`define LH      3'b001
`define LW      3'b010
`define LBU     3'b011
`define LHU     3'b100