/*  File Name        : SmithWatermanPE_tb.v
 *  Description      : Testbench for fixed implementation of Smith Waterman systolic array PE with
 *                     affine gap penalty.
 *
 *  Revision History :
 *      Albert Ng   May 01 2013     Initial Revision
 *
 */

module SmithWatermanPE_tb;
    // Inputs
    reg clk;
    reg rst;
    reg [9:0] V_in;
    reg [9:0] F_in;
    reg [1:0] T_in;
    reg [1:0] S_in;
    reg store_S;
    reg init_in;

    // Outputs
    wire [9:0] V_out;
    wire [9:0] F_out;
    wire [1:0] T_out;
    wire init_out;

    reg [1:0] short_read [5:0];
    reg [1:0] reference  [7:0];

    // Instantiate the Unit Under Test (UUT)
    SmithWatermanPE #(10, -2, -2, -1) uut (
        .clk(clk), 
        .rst(rst), 
        .V_in(V_in), 
        .F_in(F_in), 
        .T_in(T_in), 
        .S_in(S_in), 
        .store_S(store_S), 
        .init_in(init_in), 
        .V_out(V_out), 
        .F_out(F_out), 
        .T_out(T_out), 
        .init_out(init_out)
    );

    integer i;
    initial begin
        // Initialize short read and reference sequences
        short_read[0] = 2'b00;
        short_read[1] = 2'b01;
        short_read[2] = 2'b00;
        short_read[3] = 2'b01;
        short_read[4] = 2'b11;
        short_read[5] = 2'b00;
        
        reference[0] = 2'b00;
        reference[1] = 2'b01;
        reference[2] = 2'b00;
        reference[3] = 2'b10;
        reference[4] = 2'b00;
        reference[5] = 2'b01;
        reference[6] = 2'b11;
        reference[7] = 2'b00;
        
        // Initialize inputs, variables, and wait for reset
        clk = 0;
        rst = 1;
        V_in = 0;
        F_in = 0;
        T_in = 0;
        S_in = 0;
        store_S = 0;
        init_in = 0;
        i = 0;
        #20
        rst = 0;
        
        // Generate stimulus
        
        // Test 1
        $display("V=0, F=0, S='A' test");
        S_in = short_read[0];   // Store short read sequence
        store_S = 1;
        #10;
        store_S = 0;
        for(i = 0; i < 8; i = i + 1) begin
            T_in = reference[i];
            init_in = 1;
            #10;
            $display("%d %d %d %d", V_out, F_out, T_out, init_out);
        end
        
        // Test 2
        $display("V=0, F=0, S='C' test");
        S_in = short_read[1];
        store_S = 1;
        init_in = 0;
        #10
        store_S = 0;
        for(i = 0; i < 8; i = i + 1) begin
            T_in = reference[i];
            init_in = 1;
            #10;
            $display("%d %d %d %d", V_out, F_out, T_out, init_out);
        end
        
        // Test 3
        $display("V=10, F=-4, S='T' test");
        V_in = 10;
        F_in = -4;
        S_in = short_read[4];
        store_S = 1;
        init_in = 0;
        #10
        store_S = 0;
        for(i = 0; i < 8; i = i + 1) begin
            T_in = reference[i];
            init_in = 1;
            #10;
            $display("%d %d %d %d", V_out, F_out, T_out, init_out);
        end
        
        #100;
        $finish;
    end
    
    always begin
        #5 clk = !clk;
    end
      
endmodule

