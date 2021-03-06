/*  File Name        : StreamInputHandler.v
 *  Description      : PCIe stream input handler
 *
 *                     Unit that processes the PCIe stream input. Synchronizes
 *                     the stream data from the stream clock to the engine clock.
 *                     Distinguishes between query info and query sequence, 
 *                     communicating with the appropriate Engine ports.
 *
 *
 *  Revision History :
 *      Albert Ng   Jul 09 2013     Initial Revision
 *      Albert Ng   Jul 15 2013     Added query ID #
 *                                  Added cell score threshold
 *      Albert Ng   Aug 06 2013     Removed latches
 *      Albert Ng   Aug 07 2013     Changed ref_len and ref_addr to 26 bits
 *      Albert Ng   Aug 09 2013     Changed ref_len and ref_addr to 28 bits
 *      Albert Ng   Aug 30 2013     Changed num_query_blocks to query_length
 *
 */
 
module StreamInputHandler(
    input          rst,                                // System reset
    input          si_clk,                             // Stream input clock
    input          si_valid,                           // Stream input valid
    input  [127:0] si_data,                            // Stream input data
    output         si_rdy,                             // Stream input ready
    input          clk,                                // Engine clock    
    output [27:0]  ref_length_out,                     // Reference sequence length (in 128bp blocks)
    output [27:0]  ref_addr_out,                       // Reference sequence address
    output [15:0]  query_length_out,                   // Query sequence length (in bp)
    output [15:0]  query_id_out,                       // Query ID #
    output [31:0]  cell_score_threshold_out,           // Cell score threshold for reporting
    output         query_info_valid_out,               // Query information valid
    input          query_info_rdy_in,                  // Query information ready
    output [(NUM_PES * 2) - 1:0] query_seq_block_out,  // Query sequence block
    output         query_seq_block_valid_out,          // Query sequence block valid
    input          query_seq_block_rdy_in              // Query sequence block ready
    );

    parameter NUM_PES = 64;
    
    // FSM states
    localparam WAIT_QUERY_INFO_VALID      = 4'b0001,
               WAIT_QUERY_INFO_RDY        = 4'b0010,
               WAIT_QUERY_SEQ_BLOCK_VALID = 4'b0100,
               WAIT_QUERY_SEQ_BLOCK_RDY   = 4'b1000;
    reg [3:0] state;
    reg [3:0] next_state;
    
    // FSM outputs
    reg query_info_valid;
    reg query_seq_block_valid;
    reg [9:0] num_query_blocks;
    reg [9:0] query_block_cnt;
    reg [9:0] next_num_query_blocks;
    reg [9:0] next_query_block_cnt;
    
    // Stream data sync buffer signals
    wire [127:0] sdsb_din;
    wire sdsb_wr_en;
    reg  sdsb_rd_en;
    wire [127:0] sdsb_dout;
    wire sdsb_full;
    wire sdsb_empty;
    
    stream_data_sync_buffer sdsb (
        .rst(rst),
        .wr_clk(si_clk),
        .rd_clk(clk),
        .din(sdsb_din),
        .wr_en(sdsb_wr_en),
        .rd_en(sdsb_rd_en),
        .dout(sdsb_dout),
        .full(sdsb_full),
        .empty(sdsb_empty)
    );
    
    // Stream interface w/ sync buffer
    assign sdsb_din = si_data;
    assign sdsb_wr_en = !sdsb_full & si_valid;
    assign si_rdy = sdsb_wr_en;
    
    // Engine interface w/ sync buffer
    assign ref_length_out       = sdsb_dout[27:0];
    assign ref_addr_out         = sdsb_dout[59:32];
    assign query_length_out     = sdsb_dout[79:64];
    assign query_id_out         = sdsb_dout[95:80];
    assign cell_score_threshold_out = sdsb_dout[127:96];
    assign query_info_valid_out = query_info_valid;
    assign query_seq_block_out = sdsb_dout[(NUM_PES * 2) - 1:0];
    assign query_seq_block_valid_out = query_seq_block_valid;

    // FSM
    always @(posedge clk) begin
        if (rst) begin
            state <= WAIT_QUERY_INFO_VALID;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        case(state)
            WAIT_QUERY_INFO_VALID: begin
                if (!sdsb_empty) begin
                    next_state = WAIT_QUERY_INFO_RDY;
                end else begin
                    next_state = WAIT_QUERY_INFO_VALID;
                end
            end
            
            WAIT_QUERY_INFO_RDY: begin
                if (query_info_rdy_in) begin
                    next_state = WAIT_QUERY_SEQ_BLOCK_VALID;
                end else begin
                    next_state = WAIT_QUERY_INFO_RDY;
                end
            end
            
            WAIT_QUERY_SEQ_BLOCK_VALID: begin
                if (!sdsb_empty) begin
                    next_state = WAIT_QUERY_SEQ_BLOCK_RDY;
                end else begin
                    next_state = WAIT_QUERY_SEQ_BLOCK_VALID;
                end
            end
            
            WAIT_QUERY_SEQ_BLOCK_RDY: begin
                if (query_seq_block_rdy_in && (query_block_cnt == num_query_blocks)) begin
                    next_state = WAIT_QUERY_INFO_VALID;
                end else if (query_seq_block_rdy_in) begin
                    next_state = WAIT_QUERY_SEQ_BLOCK_VALID;
                end else begin
                    next_state = WAIT_QUERY_SEQ_BLOCK_RDY;
                end
            end
            
            default: begin  // Shouldn't get here
                next_state = WAIT_QUERY_INFO_VALID;
            end
        endcase
    end
    
    always @(*) begin
        case(state)
            WAIT_QUERY_INFO_VALID: begin
                query_info_valid = !sdsb_empty;
                query_seq_block_valid = 0;
                if (!sdsb_empty) begin
                    if (sdsb_dout[69:64] == 0) begin
                        next_num_query_blocks = sdsb_dout[79:70];
                    end else begin
                        next_num_query_blocks = sdsb_dout[79:70] + 1;
                    end
                end else begin
                    next_num_query_blocks = num_query_blocks;
                end
                next_query_block_cnt = 0;
                sdsb_rd_en = 0;
            end
            
            WAIT_QUERY_INFO_RDY: begin
                query_info_valid = !sdsb_empty;
                query_seq_block_valid = 0;
                next_num_query_blocks = num_query_blocks;
                next_query_block_cnt = query_block_cnt;
                if (query_info_rdy_in) begin
                    sdsb_rd_en = 1;
                end else begin
                    sdsb_rd_en = 0;
                end
            end
            
            WAIT_QUERY_SEQ_BLOCK_VALID: begin
                query_info_valid = 0;
                query_seq_block_valid = !sdsb_empty;
                next_num_query_blocks = num_query_blocks;
                if (!sdsb_empty) begin
                    next_query_block_cnt = query_block_cnt + 1;
                end else begin
                    next_query_block_cnt = query_block_cnt;
                end
                sdsb_rd_en = 0;
            end
            
            WAIT_QUERY_SEQ_BLOCK_RDY: begin
                query_info_valid = 0;
                query_seq_block_valid = !sdsb_empty;
                next_num_query_blocks = num_query_blocks;
                next_query_block_cnt = query_block_cnt;
                if (query_seq_block_rdy_in) begin
                    sdsb_rd_en = 1;
                end else begin
                    sdsb_rd_en = 0;
                end
            end
            
            default: begin  // Shouldn't get here
                query_info_valid = 0;
                query_seq_block_valid = 0;
                next_num_query_blocks = num_query_blocks;
                next_query_block_cnt = 0;
                sdsb_rd_en = 0;
            end
        endcase
    end
                
    always @(posedge clk) begin
        if (rst) begin
            num_query_blocks <= 0;
            query_block_cnt <= 0;
        end else begin
            num_query_blocks <= next_num_query_blocks;
            query_block_cnt <= next_query_block_cnt;
        end
    end

endmodule
