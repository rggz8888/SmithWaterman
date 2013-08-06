/*  File Name        : StreamInputHandler_ReferenceReader_SmithWatermanArray_EngineCtrl_Interface.v
 *  Description      : A stream input handler, reference reader, Smith Waterman
 *                     Array and Engine Controller all interfaced together
 *
 *  Revision History :
 *      Albert Ng   Jul 11 2013     Initial Revision
 *      Albert Ng   Jul 24 2013     Changed Engine to SmithWatermanArray_EngineCtrl_Interface
 *      Albert Ng   Jul 26 2013     Added cell score filter interface
 *                                  Added V_out_valid
 *      Albert Ng   Jul 27 2013     Added end_of_query_out
 */
 
module StreamInputHandler_ReferenceReader_SmithWatermanArray_EngineCtrl_Interface(
    input          clk,                                // Engine clock 
    input          rst,                                // System reset
    input          stall,                              // Pipeline stall
    
    // Stream input handler interface
    input          si_clk,                             // Stream input clock
    input          si_valid,                           // Stream input valid
    input  [127:0] si_data,                            // Stream input data
    output         si_rdy,                             // Stream input ready
   
    // AXI bus arbiter interface
    output [5:0]   rd_id_out,           // Read burst ID
    output [31:0]  rd_addr_out,         // Read burst address
    output [7:0]   rd_len_out,          // Read burst length (in terms of 256 bit blocks)
    output         rd_info_valid_out,   // Read info valid
    input          rd_info_rdy_in,      // Read request acknowledged 
    input  [255:0] rd_data_in,          // DRAM read data
    input          rd_data_valid_in,    // DRAM read data valid    
    output         rd_data_rdy_out,     // DRAM read data acknowledged   

    // Cell Score Filter interface
    output [24:0] ref_block_cnt_out,        // Current ref seq block
    output [15:0] query_id_out,             // Current query ID
    output [31:0] cell_score_threshold_out, // Current cell score threshold
    output tracking_info_valid_out,         // Tracking info is valid

    // Smith Waterman systolic array output
    output [NUM_PES * WIDTH - 1:0] V_out,   // Cell score outputs
    output [NUM_PES - 1:0] V_out_valid,     // Cell score outputs valid 
    output end_of_query_out                 // Last PE score is end of query
    );

    parameter NUM_PES = 64;
    parameter REF_LENGTH = 128;
    parameter WIDTH = 10;
    parameter MATCH_REWARD = 2;
    parameter MISMATCH_PEN = -2;
    parameter GAP_OPEN_PEN = -2;
    parameter GAP_EXTEND_PEN = -1;
    parameter PES_PER_FIFO = 4;
       
    // Reference Reader, Engine interface
    wire [24:0] ref_addr;
    wire [24:0] ref_length;
    wire ref_info_valid;
    wire [2*REF_LENGTH - 1:0] ref_seq_block;
    wire ref_seq_block_valid;
    wire ref_seq_block_rdy;
    
    StreamInputHandler_SmithWatermanArray_EngineCtrl_Interface #(NUM_PES, REF_LENGTH, WIDTH, MATCH_REWARD, MISMATCH_PEN, GAP_OPEN_PEN, GAP_EXTEND_PEN, PES_PER_FIFO) sihe (
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .si_clk(si_clk),
        .si_valid(si_valid),
        .si_data(si_data),
        .si_rdy(si_rdy),
        .ref_addr_out(ref_addr),
        .ref_length_out(ref_length),
        .ref_info_valid_out(ref_info_valid),
        .ref_seq_block_in(ref_seq_block),
        .ref_seq_block_valid_in(ref_seq_block_valid),
        .ref_seq_block_rdy_out(ref_seq_block_rdy),
        .ref_block_cnt_out(ref_block_cnt_out),
        .query_id_out(query_id_out),
        .cell_score_threshold_out(cell_score_threshold_out),
        .tracking_info_valid_out(tracking_info_valid_out),
        .V_out(V_out),
        .V_out_valid(V_out_valid),
        .end_of_query_out(end_of_query_out)
    );
    
    ReferenceReader #(REF_LENGTH) rr (
        .clk(clk),
        .rst(rst),
        .ref_addr_in(ref_addr),
        .ref_length_in(ref_length),
        .ref_info_valid_in(ref_info_valid),
        .ref_seq_block_out(ref_seq_block),
        .ref_seq_block_valid_out(ref_seq_block_valid),
        .ref_seq_block_rdy_in(ref_seq_block_rdy),
        .rd_id_out(rd_id_out),
        .rd_addr_out(rd_addr_out),
        .rd_len_out(rd_len_out),
        .rd_info_valid_out(rd_info_valid_out),
        .rd_info_rdy_in(rd_info_rdy_in),
        .rd_data_in(rd_data_in),
        .rd_data_valid_in(rd_data_valid_in),
        .rd_data_rdy_out(rd_data_rdy_out)
    );
        
endmodule