/*  File Name        : CellScoreFilter_tb.v
 *  Description      : Cell Score Filter test bench
 *
 *  Revision History :
 *      Albert Ng   Jul 24 2013     Initial Revision
 */

module CellScoreFilter_tb;

	// Inputs
	reg clk;
	reg rst;
	reg [24:0] ref_block_cnt_in;
	reg [15:0] query_id_in;
	reg [31:0] cell_score_threshold_in;
	reg tracking_info_valid_in;
	reg [29:0] V_out_in;
	reg [2:0] V_out_valid_in;
	reg result_0_rdy_in;
	reg result_1_rdy_in;

	// Outputs
	wire stall_out;
	wire [40:0] result_0_data_out;
	wire result_0_valid_out;
	wire [40:0] result_1_data_out;
	wire result_1_valid_out;

    integer i;

	// Instantiate the Unit Under Test (UUT)
	CellScoreFilter #(3, 10) uut (
		.clk(clk), 
		.rst(rst), 
		.stall_out(stall_out), 
		.ref_block_cnt_in(ref_block_cnt_in), 
		.query_id_in(query_id_in), 
		.cell_score_threshold_in(cell_score_threshold_in), 
		.tracking_info_valid_in(tracking_info_valid_in), 
		.V_out_in(V_out_in), 
		.V_out_valid_in(V_out_valid_in), 
		.result_0_data_out(result_0_data_out), 
		.result_0_valid_out(result_0_valid_out), 
		.result_0_rdy_in(result_0_rdy_in), 
		.result_1_data_out(result_1_data_out), 
		.result_1_valid_out(result_1_valid_out), 
		.result_1_rdy_in(result_1_rdy_in)
	);

	initial begin
		// Initialize Inputs
		clk <= 0;
		rst <= 1;
		ref_block_cnt_in <= 0;
		query_id_in <= 0;
		cell_score_threshold_in <= 0;
		tracking_info_valid_in <= 0;
		V_out_in <= 0;
		V_out_valid_in <= 0;
		result_0_rdy_in <= 0;
		result_1_rdy_in <= 0;
        #20;
        rst <= 0;
        
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        ref_block_cnt_in <= 10;
        query_id_in <= 1;
        cell_score_threshold_in <= 15;
        tracking_info_valid_in <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        tracking_info_valid_in <= 0;
        V_out_in[9:0]   <= 10;
        V_out_in[19:10] <= 0;
        V_out_in[29:20] <= 0;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 0;
        #10;
        
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 8;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 0;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 0;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 10;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 7;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 8;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 18;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        // Read port latency 1
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 0;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 16;
        V_out_valid_in[0] <= 0;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        // Read port latency 2
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 10;
        V_out_in[19:10] <= 0;
        V_out_in[29:20] <= 15;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 1;
        
        #10;
        // Read port latency 2
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 1)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_0_data_out != 40'b00000000000000000000010100000000000000001)
            $display("@%0dns result_0_data_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 16;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 0;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 0;
        result_0_rdy_in <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 28;
        V_out_in[19:10] <= 15;
        V_out_in[29:20] <= 7;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        result_0_rdy_in <= 0;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 26;
        V_out_in[19:10] <= 26;
        V_out_in[29:20] <= 14;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 8;
        V_out_in[19:10] <= 38;
        V_out_in[29:20] <= 25;
        V_out_valid_in[0] <= 0;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        ref_block_cnt_in <= 11;
        query_id_in <= 1;
        cell_score_threshold_in <= 15;
        tracking_info_valid_in <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 7;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 36;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 1;
        tracking_info_valid_in <= 0;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 6;
        V_out_in[19:10] <= 6;
        V_out_in[29:20] <= 15;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 0;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 10;
        V_out_in[19:10] <= 17;
        V_out_in[29:20] <= 18;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
                
        #10;
        // Read latency 1
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 8;
        V_out_in[19:10] <= 15;
        V_out_in[29:20] <= 16;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        // Read latency 2
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 0)
            $display("@%0dns result_1_valid_out error", $time);
        V_out_in[9:0]   <= 26;
        V_out_in[19:10] <= 14;
        V_out_in[29:20] <= 15;
        V_out_valid_in[0] <= 0;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 25;
        V_out_in[19:10] <= 38;
        V_out_in[29:20] <= 25;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 24;
        V_out_in[19:10] <= 36;
        V_out_in[29:20] <= 36;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 0;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 26;
        V_out_in[19:10] <= 35;
        V_out_in[29:20] <= 36;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 24;
        V_out_in[19:10] <= 34;
        V_out_in[29:20] <= 46;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 0;
        V_out_in[19:10] <= 33;
        V_out_in[29:20] <= 44;
        V_out_valid_in[0] <= 0;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        ref_block_cnt_in <= 20;
        query_id_in <= 2;
        cell_score_threshold_in <= 10;
        tracking_info_valid_in <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 0;
        V_out_in[19:10] <= 0;
        V_out_in[29:20] <= 43;
        V_out_valid_in[0] <= 0;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 1;
        tracking_info_valid_in <= 0;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 0;
        V_out_in[19:10] <= 0;
        V_out_in[29:20] <= 0;
        V_out_valid_in[0] <= 0;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 0;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 10;
        V_out_in[19:10] <= 0;
        V_out_in[29:20] <= 0;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 0;
        
        #10;
        // Read latency 1
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 8;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 0;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 0;
        
        #10;
        // Read latency 2
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 0)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 10;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 7;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 1)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
            $display("@%0dns result_0_data_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[9:0]   <= 10;
        V_out_in[19:10] <= 8;
        V_out_in[29:20] <= 7;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 1;
        V_out_valid_in[2] <= 1;
        
        // Fill FIFO 1
        for (i = 0; i < 16; i = i + 1) begin
            #10;
            if (stall_out != 0)
                $display("@%0dns stall_out error", $time);
            if (result_0_valid_out != 1)
                $display("@%0dns result_0_valid_out error", $time);
            if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
                $display("@%0dns result_0_data_out error", $time);
            if (result_1_valid_out != 1)
                $display("@%0dns result_1_valid_out error", $time);
            if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
                $display("@%0dns result_1_data_out error", $time);
            V_out_valid_in[0] <= 0;
            V_out_valid_in[1] <= 0;
            V_out_valid_in[2] <= 0;
            ref_block_cnt_in <= 11;
            query_id_in <= 1;
            cell_score_threshold_in <= 1;
            tracking_info_valid_in <= 1;
            
            #10;
            if (stall_out != 0)
                $display("@%0dns stall_out error", $time);
            if (result_0_valid_out != 1)
                $display("@%0dns result_0_valid_out error", $time);
            if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
                $display("@%0dns result_0_data_out error", $time);
            if (result_1_valid_out != 1)
                $display("@%0dns result_1_valid_out error", $time);
            if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
                $display("@%0dns result_1_data_out error", $time);
            V_out_in[0] <= 1;
            V_out_valid_in[0] <= 1;
            V_out_valid_in[1] <= 0;
            V_out_valid_in[2] <= 0;
            tracking_info_valid_in <= 0;
            
            #10;
            if (stall_out != 0)
                $display("@%0dns stall_out error", $time);
            if (result_0_valid_out != 1)
                $display("@%0dns result_0_valid_out error", $time);
            if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
                $display("@%0dns result_0_data_out error", $time);
            if (result_1_valid_out != 1)
                $display("@%0dns result_1_valid_out error", $time);
            if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
                $display("@%0dns result_1_data_out error", $time);
            V_out_valid_in[0] <= 0;
            V_out_valid_in[1] <= 0;
            V_out_valid_in[2] <= 0;
            ref_block_cnt_in <= 11;
            query_id_in <= 1;
            cell_score_threshold_in <= 1;
            tracking_info_valid_in <= 1;
            
            #10;
            if (stall_out != 0)
                $display("@%0dns stall_out error", $time);
            if (result_0_valid_out != 1)
                $display("@%0dns result_0_valid_out error", $time);
            if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
                $display("@%0dns result_0_data_out error", $time);
            if (result_1_valid_out != 1)
                $display("@%0dns result_1_valid_out error", $time);
            if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
                $display("@%0dns result_1_data_out error", $time);
            V_out_valid_in[0] <= 0;
            V_out_valid_in[1] <= 0;
            V_out_valid_in[2] <= 0;
            tracking_info_valid_in <= 0;
        end
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 1)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
            $display("@%0dns result_0_data_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_valid_in[0] <= 0;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 0;
        ref_block_cnt_in <= 11;
        query_id_in <= 1;
        cell_score_threshold_in <= 1;
        tracking_info_valid_in <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 1)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
            $display("@%0dns result_0_data_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[0] <= 1;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 0;
        tracking_info_valid_in <= 0;

        #10;
        if (stall_out != 1)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 1)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
            $display("@%0dns result_0_data_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[0] <= 1;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 0;
        
        #10;
        if (stall_out != 1)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 1)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
            $display("@%0dns result_0_data_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[0] <= 1;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 0;
        result_1_rdy_in <= 1;
        
        #10;
        if (stall_out != 0)
            $display("@%0dns stall_out error", $time);
        if (result_0_valid_out != 1)
            $display("@%0dns result_0_valid_out error", $time);
        if (result_0_data_out != 40'b00000000000000000000101000000000000000010)
            $display("@%0dns result_0_data_out error", $time);
        if (result_1_valid_out != 1)
            $display("@%0dns result_1_valid_out error", $time);
        if (result_1_data_out != 40'b00000000000000000000010110000000000000001)
            $display("@%0dns result_1_data_out error", $time);
        V_out_in[0] <= 1;
        V_out_valid_in[0] <= 1;
        V_out_valid_in[1] <= 0;
        V_out_valid_in[2] <= 0;
        result_1_rdy_in <= 0;

        // Wait 100 ns
        #100;
        $display("Tests complete!");
        $finish;
    end
      
    
    always begin
        #5 clk = !clk;
    end
endmodule

