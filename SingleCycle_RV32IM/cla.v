`timescale 1ns / 1ps

/**
 * @param a first 1-bit input
 * @param b second 1-bit input
 * @param g whether a and b generate a carry
 * @param p whether a and b would propagate an incoming carry
 */
module gp1(
        input a,b,
        output g,p
    );
    assign g = a & b;
    assign p = a | b;   
endmodule

/**
 * Computes aggregate generate/propagate signals over a 4-bit window.
 * @param gin incoming generate signals
 * @param pin incoming propagate signals
 * @param cin the incoming carry
 * @param gout whether these 4 bits internally would generate a carry-out (independent of cin)
 * @param pout whether these 4 bits internally would propagate an incoming carry from cin
 * @param cout the carry outs for the low-order 3 bits
 */
module gp4(
        input [3:0] gin, pin,
        input cin,
        output gout, pout,
        output [2:0] cout
    );
    assign cout[0] = gin[0] | (pin[0] & cin);
    assign cout[1] = gin[1] | (pin[1] & cout[0]);
    assign cout[2] = gin[2] | (pin[2] & cout[1]);

    assign pout = &pin;
    assign gout = gin[3] | (pin[3] & gin[2]) | (pin[3] & pin[2] & gin[1]) | (pin[3] & pin[2] & pin[1] & gin[0]);
endmodule

/** Same as gp4 but for an 8-bit window instead */
module gp8(
    input [7:0] gin, pin,
    input cin,
    output gout, pout,
    output [6:0] cout);
    
    wire gout_low, pout_low;
    wire [2:0] cout_low; // carry C1, C2, C3
    wire gout_high, pout_high;
    wire [2:0] cout_high; // carry C5, C6, C7

    wire c4;
    
    gp4 low_4b (
        .gin(gin[3:0]), 
        .pin(pin[3:0]), 
        .cin(cin),
        .gout(gout_low), 
        .pout(pout_low),
        .cout(cout_low)     
    ); 
    
    assign c4 = gout_low | (pout_low & cin);
    
    gp4 high_4b (
        .gin(gin[7:4]),
        .pin(pin[7:4]),
        .cin(c4),          
        .gout(gout_high),
        .pout(pout_high),
        .cout(cout_high)    
    );
    
    assign cout[2:0] = cout_low;  
    assign cout[3]   = c4;        
    assign cout[6:4] = cout_high; 
   
    assign pout = pout_high & pout_low;
    assign gout = gout_high | (pout_high & gout_low);
     
endmodule

module cla
  (input wire [31:0]  a, b,
   input wire         cin,
   output wire [31:0] sum);

    wire [31:0] g, p;
    wire [7:0] g4, p4;

    wire [31:0] c_in_full;
    wire [7:0] cin_gp4;

    wire [6:0] cout_gp8;


    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_gp1
            gp1 gp1_inst (
                .a(a[i]), 
                .b(b[i]), 
                .g(g[i]), 
                .p(p[i])
            );
        end
    endgenerate

    gp8 gp8_top (
        .gin(g4), 
        .pin(p4), 
        .cin(cin),
        .gout(),         
        .pout(),         
        .cout(cout_gp8)  
    );

    assign cin_gp4[0] = cin;          
    assign cin_gp4[7:1] = cout_gp8; 

    genvar j;
    generate
        for (j = 0; j < 8; j = j + 1) begin : gen_gp4
            gp4 gp4_inst (
                .gin(g[(j*4) +: 4]),
                .pin(p[(j*4) +: 4]), 
                .cin(cin_gp4[j]),
                .gout(g4[j]),         
                .pout(p4[j]),         
                .cout(c_in_full[4*j+3 : 4*j+1]) 
            );
        end
    endgenerate

    assign c_in_full[0]    = cin;
    assign c_in_full[4]    = cout_gp8[0]; 
    assign c_in_full[8]    = cout_gp8[1]; 
    assign c_in_full[12]   = cout_gp8[2]; 
    assign c_in_full[16]   = cout_gp8[3]; 
    assign c_in_full[20]   = cout_gp8[4]; 
    assign c_in_full[24]   = cout_gp8[5]; 
    assign c_in_full[28]   = cout_gp8[6]; 

    assign sum = a ^ b ^ c_in_full;

endmodule