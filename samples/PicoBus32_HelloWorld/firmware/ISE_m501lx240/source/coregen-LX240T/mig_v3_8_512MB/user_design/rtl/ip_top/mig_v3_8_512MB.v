//*****************************************************************************
// (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
//
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
//
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
//
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
//
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
//
//*****************************************************************************
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor             : Xilinx
// \   \   \/     Version            : 3.8
//  \   \         Application        : MIG
//  /   /         Filename           : mig_v3_8_512MB.v
// /___/   /\     Date Last Modified : Thu 14 Jul 2011 10:29:15 AM PDT
// \   \  /  \    Date Created       : Mon Jun 23 2008
//  \___\/\___\
//
// Device           : Virtex-6
// Design Name      : DDR3 SDRAM
// Purpose          :
//                   Top-level  module. This module serves both as an example,
//                   and allows the user to synthesize a self-contained design,
//                   which they can use to test their hardware. In addition to
//                   the memory controller.
//                   instantiates:
//                     1. Clock generation/distribution, reset logic
//                     2. IDELAY control block
//                     3. Synthesizable testbench - used to model user's backend
//                        logic
// Reference        :
// Revision History :
//*****************************************************************************

`timescale 1ps/1ps

module mig_DDR3 #
  (
   parameter REFCLK_FREQ             = 200,
                                       // # = 200 when design frequency <= 533 MHz,
                                       //   = 300 when design frequency > 533 MHz.
   parameter IODELAY_GRP             = "IODELAY_MIG",
                                       // It is associated to a set of IODELAYs with
                                       // an IDELAYCTRL that have same IODELAY CONTROLLER
                                       // clock frequency.
   parameter MMCM_ADV_BANDWIDTH      = "OPTIMIZED",
                                       // MMCM programming algorithm
   //parameter CLKFBOUT_MULT_F         = 16,  // 533 MHz
   parameter CLKFBOUT_MULT_F         = 6,   // 400 MHz
                                       // write PLL VCO multiplier.
   //parameter DIVCLK_DIVIDE           = 3,   // 533 MHz
   parameter DIVCLK_DIVIDE           = 1,   // 400 MHz
                                       // write PLL VCO divisor.
   //parameter CLKOUT_DIVIDE           = 2,   // 533 MHz
   parameter CLKOUT_DIVIDE           = 3,   // 400 MHz
                                       // VCO output divisor for fast (memory) clocks.
   parameter nCK_PER_CLK             = 2,
                                       // # of memory CKs per fabric clock.
                                       // # = 2, 1.
   //parameter tCK                     = 1875,
   parameter tCK                     = 2500,
                                       // memory tCK paramter.
                                       // # = Clock Period.
   parameter DEBUG_PORT              = "OFF",
                                       // # = "ON" Enable debug signals/controls.
                                       //   = "OFF" Disable debug signals/controls.
   `ifdef SIMULATION
      parameter SIM_BYPASS_INIT_CAL     = "FAST",
                                          // # = "OFF" -  Complete memory init &
                                          //              calibration sequence
                                          // # = "SKIP" - Skip memory init &
                                          //              calibration sequence
                                          // # = "FAST" - Skip memory init & use
                                          //              abbreviated calib sequence
   `else
      parameter SIM_BYPASS_INIT_CAL     = "OFF",
                                          // # = "OFF" -  Complete memory init &
                                          //              calibration sequence
                                          // # = "SKIP" - Skip memory init &
                                          //              calibration sequence
                                          // # = "FAST" - Skip memory init & use
                                          //              abbreviated calib sequence
   `endif
   parameter nCS_PER_RANK            = 1,
                                       // # of unique CS outputs per Rank for
                                       // phy.
   parameter DQS_CNT_WIDTH           = 2,
                                       // # = ceil(log2(DQS_WIDTH)).
   parameter RANK_WIDTH              = 1,
                                       // # = ceil(log2(RANKS)).
   parameter BANK_WIDTH              = 3,
                                       // # of memory Bank Address bits.
   parameter CK_WIDTH                = 1,
                                       // # of CK/CK# outputs to memory.
   parameter CKE_WIDTH               = 1,
                                       // # of CKE outputs to memory.
   parameter COL_WIDTH               = 10,
                                       // # of memory Column Address bits.
   parameter CS_WIDTH                = 1,
                                       // # of unique CS outputs to memory.
   parameter DM_WIDTH                = 4,
                                       // # of Data Mask bits.
   parameter DQ_WIDTH                = 32,
                                       // # of Data (DQ) bits.
   parameter DQS_WIDTH               = 4,
                                       // # of DQS/DQS# bits.
   parameter ROW_WIDTH               = 14,
                                       // # of memory Row Address bits.
   parameter BURST_MODE              = "8",
                                       // Burst Length (Mode Register 0).
                                       // # = "8", "4", "OTF".
   parameter BM_CNT_WIDTH            = 3,
                                       // # = ceil(log2(nBANK_MACHS)).
   parameter nBANK_MACHS             = 8,
                                       // # = 2,3,4,5,6,7,8.
   parameter ADDR_CMD_MODE           = "1T" ,
                                       // # = "2T", "1T".
   parameter ORDERING                = "NORM",
                                       // # = "NORM", "STRICT".
   parameter RANKS                   = 1,
                                       // # of Ranks.
   parameter WRLVL                   = "ON",
                                       // # = "ON" - DDR3 SDRAM
                                       //   = "OFF" - DDR2 SDRAM.
   parameter PHASE_DETECT            = "ON",
                                       // # = "ON", "OFF".
   parameter RTT_NOM                 = "60",
                                       // RTT_NOM (ODT) (Mode Register 1).
                                       // # = "DISABLED" - RTT_NOM disabled,
                                       //   = "120" - RZQ/2,
                                       //   = "60"  - RZQ/4,
                                       //   = "40"  - RZQ/6.
   parameter RTT_WR                  = "OFF",
                                       // RTT_WR (ODT) (Mode Register 2).
                                       // # = "OFF" - Dynamic ODT off,
                                       //   = "120" - RZQ/2,
                                       //   = "60"  - RZQ/4,
   parameter OUTPUT_DRV              = "HIGH",
                                       // Output Driver Impedance Control (Mode Register 1).
                                       // # = "HIGH" - RZQ/7,
                                       //   = "LOW" - RZQ/6.
   parameter REG_CTRL                = "OFF",
                                       // # = "ON" - RDIMMs,
                                       //   = "OFF" - Components, SODIMMs, UDIMMs.
   parameter nDQS_COL0               = 3,
                                       // Number of DQS groups in I/O column #1.
   parameter nDQS_COL1               = 1,
                                       // Number of DQS groups in I/O column #2.
   parameter nDQS_COL2               = 0,
                                       // Number of DQS groups in I/O column #3.
   parameter nDQS_COL3               = 0,
                                       // Number of DQS groups in I/O column #4.
   parameter DQS_LOC_COL0            = 24'h020100,
                                       // DQS groups in column #1.
   parameter DQS_LOC_COL1            = 8'h03,
                                       // DQS groups in column #2.
   parameter DQS_LOC_COL2            = 0,
                                       // DQS groups in column #3.
   parameter DQS_LOC_COL3            = 0,
                                       // DQS groups in column #4.
   parameter tPRDI                   = 1_000_000,
                                       // memory tPRDI paramter.
   parameter tREFI                   = 7800000,
                                       // memory tREFI paramter.
   parameter tZQI                    = 128_000_000,
                                       // memory tZQI paramter.
   parameter ADDR_WIDTH              = 28,
                                       // # = RANK_WIDTH + BANK_WIDTH
                                       //     + ROW_WIDTH + COL_WIDTH;
   parameter ECC                     = "OFF",
   parameter ECC_TEST                = "OFF",
   parameter TCQ                     = 100,
   parameter DATA_WIDTH              = 32,
   // If parameters overrinding is used for simulation, PAYLOAD_WIDTH parameter
   // should to be overidden along with the vsim command
   parameter PAYLOAD_WIDTH           = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH,
   parameter INTERFACE               = "AXI4",
                                       // Port Interface.
                                       // # = UI - User Interface,
                                       //   = AXI4 - AXI4 Interface.
   parameter C_S_AXI_ID_WIDTH          = 8,
                                       // Width of all master and slave ID signals.
                                       // # = >= 1.
   parameter C_S_AXI_ADDR_WIDTH        = 32,
                                       // Width of S_AXI_AWADDR, S_AXI_ARADDR, M_AXI_AWADDR and
                                       // M_AXI_ARADDR for all SI/MI slots.
                                       // # = 32.
   parameter C_S_AXI_DATA_WIDTH        = 128,
                                       // Width of WDATA and RDATA on SI slot.
                                       // Must be less or equal to APP_DATA_WIDTH.
                                       // # = 32, 64, 128, 256.
   parameter C_S_AXI_SUPPORTS_NARROW_BURST  = 0,
                                       // Indicates whether to instatiate upsizer
                                       // Range: 0, 1
   parameter ENFORCE_RD_WR             = 0,
   parameter ENFORCE_RD_WR_CMD         = 8'h11,
   parameter ENFORCE_RD_WR_PATTERN     = 3'b000,
   parameter C_EN_WRAP_TRANS           = 0,
   parameter C_AXI_NBURST_TEST         = 0,
   // calibration Address. The address given below will be used for calibration
   // read and write operations. 
   parameter CALIB_ROW_ADD             = 16'h0000,// Calibration row address
   parameter CALIB_COL_ADD             = 12'h000, // Calibration column address
   parameter CALIB_BA_ADD              = 3'h0,    // Calibration bank address
   parameter RST_ACT_LOW             = 0,  //JBC
                                       // =1 for active low reset,
                                       // =0 for active high.
   parameter INPUT_CLK_TYPE          = "SINGLE_ENDED",
                                       // input clock type DIFFERENTIAL or SINGLE_ENDED
   parameter STARVE_LIMIT            = 2,
                                       // # = 2,3,4.
   parameter C_S_AXI_REG_EN0          = 20'h00000,
                                       // Instatiates register slices before upsizer.
                                       // The type of register is specified for each channel
                                       // in a vector. 4 bits per channel are used.
                                       // C_S_AXI_REG_EN0[03:00] = AW CHANNEL REGISTER SLICE
                                       // C_S_AXI_REG_EN0[07:04] =  W CHANNEL REGISTER SLICE
                                       // C_S_AXI_REG_EN0[11:08] =  B CHANNEL REGISTER SLICE
                                       // C_S_AXI_REG_EN0[15:12] = AR CHANNEL REGISTER SLICE
                                       // C_S_AXI_REG_EN0[19:16] =  R CHANNEL REGISTER SLICE
                                       // Possible values for each channel are:
                                       //
                                       //   0 => BYPASS    = The channel is just wired through the
                                       //                    module.
                                       //   1 => FWD       = The master VALID and payload signals
                                       //                    are registrated.
                                       //   2 => REV       = The slave ready signal is registrated
                                       //   3 => FWD_REV   = Both FWD and REV
                                       //   4 => SLAVE_FWD = All slave side signals and master
                                       //                    VALID and payload are registrated.
                                       //   5 => SLAVE_RDY = All slave side signals and master
                                       //                    READY are registrated.
                                       //   6 => INPUTS    = Slave and Master side inputs are
                                       //                    registrated.
                                       //
                                       //                                     A  A
                                       //                                    RRBWW
   parameter C_S_AXI_REG_EN1            = 20'h66666
                                       // Same as C_S_AXI_REG_EN0, but this register is after
                                       // the upsizer
   )
  (

    input                                sys_clk,    //single ended system clocks
    inout  [DQ_WIDTH-1:0]                ddr3_dq,
    output [ROW_WIDTH-1:0]               ddr3_addr,
    output [BANK_WIDTH-1:0]              ddr3_ba,
    output                               ddr3_ras_n,
    output                               ddr3_cas_n,
    output                               ddr3_we_n,
    output                               ddr3_reset_n,
    output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_cs_n,
    output [(CS_WIDTH*nCS_PER_RANK)-1:0] ddr3_odt,
    output [CKE_WIDTH-1:0]               ddr3_cke,
    output [DM_WIDTH-1:0]                 ddr3_dm,
    inout  [DQS_WIDTH-1:0]               ddr3_dqs_p,
    inout  [DQS_WIDTH-1:0]               ddr3_dqs_n,
    output [CK_WIDTH-1:0]                ddr3_ck_p,
    output [CK_WIDTH-1:0]                ddr3_ck_n,
    input                                aresetn,
    input  [C_S_AXI_ID_WIDTH-1:0]        s_axi_awid,
    input  [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_awaddr,
    input  [7:0]                         s_axi_awlen,
    input  [2:0]                         s_axi_awsize,
    input  [1:0]                         s_axi_awburst,
    input  [0:0]                         s_axi_awlock,
    input  [3:0]                         s_axi_awcache,
    input  [2:0]                         s_axi_awprot,
    input  [3:0]                         s_axi_awqos,
    input                                s_axi_awvalid,
    output                               s_axi_awready,
    // Slave Interface Write Data Ports
    input  [C_S_AXI_DATA_WIDTH-1:0]      s_axi_wdata,
    input  [C_S_AXI_DATA_WIDTH/8-1:0]    s_axi_wstrb,
    input                                s_axi_wlast,
    input                                s_axi_wvalid,
    output                               s_axi_wready,
    // Slave Interface Write Response Ports
    output [C_S_AXI_ID_WIDTH-1:0]        s_axi_bid,
    output [1:0]                         s_axi_bresp,
    output                               s_axi_bvalid,
    input                                s_axi_bready,
    // Slave Interface Read Address Ports
    input  [C_S_AXI_ID_WIDTH-1:0]        s_axi_arid,
    input  [C_S_AXI_ADDR_WIDTH-1:0]      s_axi_araddr,
    input  [7:0]                         s_axi_arlen,
    input  [2:0]                         s_axi_arsize,
    input  [1:0]                         s_axi_arburst,
    input  [0:0]                         s_axi_arlock,
    input  [3:0]                         s_axi_arcache,
    input  [2:0]                         s_axi_arprot,
    input  [3:0]                         s_axi_arqos,
    input                                s_axi_arvalid,
    output                               s_axi_arready,
    // Slave Interface Read Data Ports
    output [C_S_AXI_ID_WIDTH-1:0]        s_axi_rid,
    output [C_S_AXI_DATA_WIDTH-1:0]      s_axi_rdata,
    output [1:0]                         s_axi_rresp,
    output                               s_axi_rlast,
    output                               s_axi_rvalid,
    input                                s_axi_rready,
    output                               ui_clk_sync_rst,
    output                               ui_clk,
    output                               phy_init_done,
    
    input                                sys_rst   // System reset
    );



    localparam SYSCLK_PERIOD          = tCK * nCK_PER_CLK;
    localparam APP_DATA_WIDTH      = PAYLOAD_WIDTH * 4;
    localparam APP_MASK_WIDTH      = APP_DATA_WIDTH / 8;

    wire                                clk_ref_p;
    wire                                clk_ref_n;
    wire                                sys_clk_p;
    wire                                sys_clk_n;
    wire                                mmcm_clk;
    wire                                iodelay_ctrl_rdy;
      
    wire                                rst;
    wire                                clk;
    wire                                clk_mem;
    wire                                clk_rd_base;
    wire                                pd_PSDONE;  
    wire                                pd_PSEN;  
    wire                                pd_PSINCDEC;
    wire  [(BM_CNT_WIDTH)-1:0]          bank_mach_next;
    wire                                ddr3_parity;
    wire                                app_hi_pri;
    wire [3:0]                          app_ecc_multiple_err_i;
    wire [47:0]                         traffic_wr_data_counts;
    wire [47:0]                         traffic_rd_data_counts;


    wire [5*DQS_WIDTH-1:0]              dbg_cpt_first_edge_cnt;
    wire [5*DQS_WIDTH-1:0]              dbg_cpt_second_edge_cnt;
    wire [5*DQS_WIDTH-1:0]              dbg_cpt_tap_cnt;
    wire                                dbg_dec_cpt;
    wire                                dbg_dec_rd_dqs;
    wire                                dbg_dec_rd_fps;
    wire [5*DQS_WIDTH-1:0]              dbg_dq_tap_cnt;
    wire [5*DQS_WIDTH-1:0]              dbg_dqs_tap_cnt;
    wire                                dbg_inc_cpt;
    wire [DQS_CNT_WIDTH-1:0]            dbg_inc_dec_sel;
    wire                                dbg_inc_rd_dqs;
    wire                                dbg_inc_rd_fps;
    wire                                dbg_ocb_mon_off;
    wire                                dbg_pd_off;
    wire                                dbg_pd_maintain_off;
    wire                                dbg_pd_maintain_0_only;
    wire [4:0]                          dbg_rd_active_dly;
    wire [3*DQS_WIDTH-1:0]              dbg_rd_bitslip_cnt;
    wire [2*DQS_WIDTH-1:0]              dbg_rd_clkdly_cnt;
    wire [4*DQ_WIDTH-1:0]               dbg_rddata;
    wire [1:0]                          dbg_rdlvl_done;
    wire [1:0]                          dbg_rdlvl_err;
    wire [1:0]                          dbg_rdlvl_start;
    wire [DQS_WIDTH-1:0]                dbg_wl_dqs_inverted;
    wire [5*DQS_WIDTH-1:0]              dbg_wl_odelay_dq_tap_cnt;
    wire [5*DQS_WIDTH-1:0]              dbg_wl_odelay_dqs_tap_cnt;
    wire [2*DQS_WIDTH-1:0]              dbg_wr_calib_clk_delay; 
    wire [5*DQS_WIDTH-1:0]              dbg_wr_dq_tap_set;
    wire [5*DQS_WIDTH-1:0]              dbg_wr_dqs_tap_set;
    wire                                dbg_wr_tap_set_en;
    wire                                dbg_idel_up_all;
    wire                                dbg_idel_down_all;
    wire                                dbg_idel_up_cpt;
    wire                                dbg_idel_down_cpt;
    wire                                dbg_idel_up_rsync;
    wire                                dbg_idel_down_rsync;
    wire                                dbg_sel_all_idel_cpt;
    wire                                dbg_sel_all_idel_rsync;
    wire                                dbg_pd_inc_cpt;
    wire                                dbg_pd_dec_cpt;
    wire                                dbg_pd_inc_dqs;
    wire                                dbg_pd_dec_dqs;
    wire                                dbg_pd_disab_hyst;
    wire                                dbg_pd_disab_hyst_0;
    wire                                dbg_wrlvl_done;
    wire                                dbg_wrlvl_err;
    wire                                dbg_wrlvl_start;
    wire [4:0]                          dbg_tap_cnt_during_wrlvl;
    wire [19:0]                         dbg_rsync_tap_cnt;
    wire [255:0]                        dbg_phy_pd;
    wire [255:0]                        dbg_phy_read;
    wire [255:0]                        dbg_phy_rdlvl;
    wire [255:0]                        dbg_phy_top;
    wire [3:0]                          dbg_pd_msb_sel;
    wire [DQS_WIDTH-1:0]                dbg_rd_data_edge_detect;
    wire [DQS_CNT_WIDTH-1:0]            dbg_sel_idel_cpt;
    wire [DQS_CNT_WIDTH-1:0]            dbg_sel_idel_rsync;
    wire [DQS_CNT_WIDTH-1:0]            dbg_pd_byte_sel;
    wire                                dbg_wr_sts_vld;
    wire                                dbg_rd_sts_vld;

    wire                                ddr3_cs0_clk;
    wire [35:0]                         ddr3_cs0_control;
    wire [383:0]                        ddr3_cs0_data;
    wire [7:0]                          ddr3_cs0_trig;
    wire [255:0]                        ddr3_cs1_async_in;
    wire [35:0]                         ddr3_cs1_control;
    wire [255:0]                        ddr3_cs2_async_in;
    wire [35:0]                         ddr3_cs2_control;
    wire [255:0]                        ddr3_cs3_async_in;
    wire [35:0]                         ddr3_cs3_control;
    wire                                ddr3_cs4_clk;
    wire [35:0]                         ddr3_cs4_control;
    wire [31:0]                         ddr3_cs4_sync_out;

    // register the reset signal
    reg                                 aresetn_q;
    always @ (posedge clk) begin
        aresetn_q <= aresetn;
    end

  //***************************************************************************


    assign app_hi_pri = 1'b0;

    assign ui_clk = clk;
    assign ui_clk_sync_rst = rst;
    assign clk_ref_p = 1'b0;
    assign clk_ref_n = 1'b0;
    assign sys_clk_p = 1'b0;
    assign sys_clk_n = 1'b0;


    iodelay_ctrl #
    (
        .TCQ            (TCQ),
        .IODELAY_GRP    (IODELAY_GRP),
        .INPUT_CLK_TYPE (INPUT_CLK_TYPE),
        .RST_ACT_LOW    (RST_ACT_LOW)
     )
    u_iodelay_ctrl
      (
        .sys_rst          (sys_rst),
        .iodelay_ctrl_rdy (iodelay_ctrl_rdy),
        .clk_ref_ibufg    (mmcm_clk)
    );
    assign mmcm_clk = sys_clk;

    infrastructure #
    (
        .TCQ                (TCQ),
        .CLK_PERIOD         (SYSCLK_PERIOD),
        .nCK_PER_CLK        (nCK_PER_CLK),
        .MMCM_ADV_BANDWIDTH (MMCM_ADV_BANDWIDTH),
        .CLKFBOUT_MULT_F    (CLKFBOUT_MULT_F),
        .DIVCLK_DIVIDE      (DIVCLK_DIVIDE),
        .CLKOUT_DIVIDE      (CLKOUT_DIVIDE),
        .RST_ACT_LOW        (RST_ACT_LOW)
     )
    u_infrastructure
    (
        .clk_mem          (clk_mem),
        .clk              (clk),
        .clk_rd_base      (clk_rd_base),
        .rstdiv0          (rst),
        .mmcm_clk         (mmcm_clk),
        .sys_rst          (sys_rst),
        .iodelay_ctrl_rdy (iodelay_ctrl_rdy),
        .PSDONE           (pd_PSDONE),
        .PSEN             (pd_PSEN),
        .PSINCDEC         (pd_PSINCDEC)
    );

    memc_ui_top #
    (
        .ADDR_CMD_MODE        (ADDR_CMD_MODE),
        .BANK_WIDTH           (BANK_WIDTH),
        .CK_WIDTH             (CK_WIDTH),
        .CKE_WIDTH            (CKE_WIDTH),
        .nCK_PER_CLK          (nCK_PER_CLK),
        .COL_WIDTH            (COL_WIDTH),
        .CS_WIDTH             (CS_WIDTH),
        .DM_WIDTH             (DM_WIDTH),
        .nCS_PER_RANK         (nCS_PER_RANK),
        .DEBUG_PORT           (DEBUG_PORT),
        .IODELAY_GRP          (IODELAY_GRP),
        .DQ_WIDTH             (DQ_WIDTH),
        .DQS_WIDTH            (DQS_WIDTH),
        .DQS_CNT_WIDTH        (DQS_CNT_WIDTH),
        .ORDERING             (ORDERING),
        .OUTPUT_DRV           (OUTPUT_DRV),
        .PHASE_DETECT         (PHASE_DETECT),
        .RANK_WIDTH           (RANK_WIDTH),
        .REFCLK_FREQ          (REFCLK_FREQ),
        .REG_CTRL             (REG_CTRL),
        .ROW_WIDTH            (ROW_WIDTH),
        .RTT_NOM              (RTT_NOM),
        .RTT_WR               (RTT_WR),
        .SIM_BYPASS_INIT_CAL  (SIM_BYPASS_INIT_CAL),
        .WRLVL                (WRLVL),
        .nDQS_COL0            (nDQS_COL0),
        .nDQS_COL1            (nDQS_COL1),
        .nDQS_COL2            (nDQS_COL2),
        .nDQS_COL3            (nDQS_COL3),
        .DQS_LOC_COL0         (DQS_LOC_COL0),
        .DQS_LOC_COL1         (DQS_LOC_COL1),
        .DQS_LOC_COL2         (DQS_LOC_COL2),
        .DQS_LOC_COL3         (DQS_LOC_COL3),
        .tPRDI                (tPRDI),
        .tREFI                (tREFI),
        .tZQI                 (tZQI),
        .BURST_MODE           (BURST_MODE),
        .BM_CNT_WIDTH         (BM_CNT_WIDTH),
        .nBANK_MACHS          (nBANK_MACHS),
        .tCK                  (tCK),
        .ADDR_WIDTH           (ADDR_WIDTH),
        .TCQ                  (TCQ),
        .ECC                  (ECC),
        .ECC_TEST             (ECC_TEST),
        .INTERFACE            (INTERFACE),
        .C_S_AXI_ID_WIDTH     (C_S_AXI_ID_WIDTH),
        .C_S_AXI_ADDR_WIDTH   (C_S_AXI_ADDR_WIDTH),
        .C_S_AXI_DATA_WIDTH   (C_S_AXI_DATA_WIDTH),
        .C_S_AXI_SUPPORTS_NARROW_BURST   (C_S_AXI_SUPPORTS_NARROW_BURST),
        .CALIB_ROW_ADD        (CALIB_ROW_ADD),
        .CALIB_COL_ADD        (CALIB_COL_ADD),
        .CALIB_BA_ADD         (CALIB_BA_ADD),
        .PAYLOAD_WIDTH        (PAYLOAD_WIDTH),
        .APP_DATA_WIDTH       (APP_DATA_WIDTH),
        .APP_MASK_WIDTH       (APP_MASK_WIDTH),
        .C_S_AXI_REG_EN0      (C_S_AXI_REG_EN0),
        .C_S_AXI_REG_EN1      (C_S_AXI_REG_EN1)
    )
    u_memc_ui_top
  (
        .clk                              (clk),
        .clk_mem                          (clk_mem),
        .clk_rd_base                      (clk_rd_base),
        .rst                              (rst),
        .ddr_addr                         (ddr3_addr),
        .ddr_ba                           (ddr3_ba),
        .ddr_cas_n                        (ddr3_cas_n),
        .ddr_ck_n                         (ddr3_ck_n),
        .ddr_ck                           (ddr3_ck_p),
        .ddr_cke                          (ddr3_cke),
        .ddr_cs_n                         (ddr3_cs_n),
        .ddr_dm                           (ddr3_dm),
        .ddr_odt                          (ddr3_odt),
        .ddr_ras_n                        (ddr3_ras_n),
        .ddr_reset_n                      (ddr3_reset_n),
        .ddr_parity                       (ddr3_parity),
        .ddr_we_n                         (ddr3_we_n),
        .ddr_dq                           (ddr3_dq),
        .ddr_dqs_n                        (ddr3_dqs_n),
        .ddr_dqs                          (ddr3_dqs_p),
        .pd_PSEN                          (pd_PSEN),
        .pd_PSINCDEC                      (pd_PSINCDEC),
        .pd_PSDONE                        (pd_PSDONE),
        .phy_init_done                    (phy_init_done),
        .bank_mach_next                   (bank_mach_next),
        .app_ecc_multiple_err             (app_ecc_multiple_err_i),
        .app_raw_not_ecc_i                (4'h0),
        .app_correct_en_i                 (1'b1),
        .aresetn                          (aresetn_q),
        .s_axi_awid                       (s_axi_awid),
        .s_axi_awaddr                     (s_axi_awaddr),
        .s_axi_awlen                      (s_axi_awlen),
        .s_axi_awsize                     (s_axi_awsize),
        .s_axi_awburst                    (s_axi_awburst),
        .s_axi_awlock                     (s_axi_awlock),
        .s_axi_awcache                    (s_axi_awcache),
        .s_axi_awprot                     (s_axi_awprot),
        .s_axi_awqos                      (s_axi_awqos),
        .s_axi_awvalid                    (s_axi_awvalid),
        .s_axi_awready                    (s_axi_awready),
        .s_axi_wdata                      (s_axi_wdata),
        .s_axi_wstrb                      (s_axi_wstrb),
        .s_axi_wlast                      (s_axi_wlast),
        .s_axi_wvalid                     (s_axi_wvalid),
        .s_axi_wready                     (s_axi_wready),
        .s_axi_bid                        (s_axi_bid),
        .s_axi_bresp                      (s_axi_bresp),
        .s_axi_bvalid                     (s_axi_bvalid),
        .s_axi_bready                     (s_axi_bready),
        .s_axi_arid                       (s_axi_arid),
        .s_axi_araddr                     (s_axi_araddr),
        .s_axi_arlen                      (s_axi_arlen),
        .s_axi_arsize                     (s_axi_arsize),
        .s_axi_arburst                    (s_axi_arburst),
        .s_axi_arlock                     (s_axi_arlock),
        .s_axi_arcache                    (s_axi_arcache),
        .s_axi_arprot                     (s_axi_arprot),
        .s_axi_arqos                      (s_axi_arqos),
        .s_axi_arvalid                    (s_axi_arvalid),
        .s_axi_arready                    (s_axi_arready),
        .s_axi_rid                        (s_axi_rid),
        .s_axi_rdata                      (s_axi_rdata),
        .s_axi_rresp                      (s_axi_rresp),
        .s_axi_rlast                      (s_axi_rlast),
        .s_axi_rvalid                     (s_axi_rvalid),
        .s_axi_rready                     (s_axi_rready),
        .dbg_wr_dqs_tap_set               (dbg_wr_dqs_tap_set),
        .dbg_wr_dq_tap_set                (dbg_wr_dq_tap_set),
        .dbg_wr_tap_set_en                (dbg_wr_tap_set_en),
        .dbg_wrlvl_start                  (dbg_wrlvl_start),
        .dbg_wrlvl_done                   (dbg_wrlvl_done),
        .dbg_wrlvl_err                    (dbg_wrlvl_err),
        .dbg_wl_dqs_inverted              (dbg_wl_dqs_inverted),
        .dbg_wr_calib_clk_delay           (dbg_wr_calib_clk_delay),
        .dbg_wl_odelay_dqs_tap_cnt        (dbg_wl_odelay_dqs_tap_cnt),
        .dbg_wl_odelay_dq_tap_cnt         (dbg_wl_odelay_dq_tap_cnt),
        .dbg_rdlvl_start                  (dbg_rdlvl_start),
        .dbg_rdlvl_done                   (dbg_rdlvl_done),
        .dbg_rdlvl_err                    (dbg_rdlvl_err),
        .dbg_cpt_tap_cnt                  (dbg_cpt_tap_cnt),
        .dbg_cpt_first_edge_cnt           (dbg_cpt_first_edge_cnt),
        .dbg_cpt_second_edge_cnt          (dbg_cpt_second_edge_cnt),
        .dbg_rd_bitslip_cnt               (dbg_rd_bitslip_cnt),
        .dbg_rd_clkdly_cnt                (dbg_rd_clkdly_cnt),
        .dbg_rd_active_dly                (dbg_rd_active_dly),
        .dbg_pd_off                       (dbg_pd_off),
        .dbg_pd_maintain_off              (dbg_pd_maintain_off),
        .dbg_pd_maintain_0_only           (dbg_pd_maintain_0_only),
        .dbg_inc_cpt                      (dbg_inc_cpt),
        .dbg_dec_cpt                      (dbg_dec_cpt),
        .dbg_inc_rd_dqs                   (dbg_inc_rd_dqs),
        .dbg_dec_rd_dqs                   (dbg_dec_rd_dqs),
        .dbg_inc_dec_sel                  (dbg_inc_dec_sel),
        .dbg_inc_rd_fps                   (dbg_inc_rd_fps),
        .dbg_dec_rd_fps                   (dbg_dec_rd_fps),
        .dbg_dqs_tap_cnt                  (dbg_dqs_tap_cnt),
        .dbg_dq_tap_cnt                   (dbg_dq_tap_cnt),
        .dbg_rddata                       (dbg_rddata)
   );

  // If debug port is not enabled, then make certain control input
  // to Debug Port are disabled
  generate
    if (DEBUG_PORT == "OFF") begin: gen_dbg_tie_off
      assign dbg_wr_dqs_tap_set     = 'b0;
      assign dbg_wr_dq_tap_set      = 'b0;
      assign dbg_wr_tap_set_en      = 1'b0;
      assign dbg_pd_off             = 1'b0;
      assign dbg_pd_maintain_off    = 1'b0;
      assign dbg_pd_maintain_0_only = 1'b0;
      assign dbg_ocb_mon_off        = 1'b0;
      assign dbg_inc_cpt            = 1'b0;
      assign dbg_dec_cpt            = 1'b0;
      assign dbg_inc_rd_dqs         = 1'b0;
      assign dbg_dec_rd_dqs         = 1'b0;
      assign dbg_inc_dec_sel        = 'b0;
      assign dbg_inc_rd_fps         = 1'b0;
      assign dbg_pd_msb_sel         = 'b0 ;
      assign dbg_sel_idel_cpt       = 'b0 ;
      assign dbg_sel_idel_rsync     = 'b0 ;
      assign dbg_pd_byte_sel        = 'b0 ;
      assign dbg_dec_rd_fps         = 1'b0;
    end
  endgenerate
  generate
    if (DEBUG_PORT == "ON") begin: gen_dbg_enable

      // Connect these to VIO if changing output (write) 
      // IODELAY taps desired 
      assign dbg_wr_dqs_tap_set     = 'b0;
      assign dbg_wr_dq_tap_set      = 'b0;
      assign dbg_wr_tap_set_en      = 1'b0;

      // Connect these to VIO if changing read base clock
      // phase required
      assign dbg_inc_rd_fps         = 1'b0;
      assign dbg_dec_rd_fps         = 1'b0;
      
      //*******************************************************
      // CS0 - ILA for monitoring PHY status, testbench error,
      //       and synchronized read data
      //*******************************************************

      // Assignments for ILA monitoring general PHY
      // status and synchronized read data
      assign ddr3_cs0_clk             = clk;
      assign ddr3_cs0_trig[1:0]       = dbg_rdlvl_done;
      assign ddr3_cs0_trig[3:2]       = dbg_rdlvl_err;
      assign ddr3_cs0_trig[4]         = phy_init_done;
      assign ddr3_cs0_trig[5]         = 1'b0;  // Reserve for ERROR from TrafficGen
      assign ddr3_cs0_trig[7:5]       = 'b0;

      // Support for only up to 72-bits of data
      if (DQ_WIDTH <= 72) begin: gen_dq_le_72
        assign ddr3_cs0_data[4*DQ_WIDTH-1:0] = dbg_rddata;
      end else begin: gen_dq_gt_72
        assign ddr3_cs0_data[287:0] = dbg_rddata[287:0];
      end

      assign ddr3_cs0_data[289:288]   = dbg_rdlvl_done;
      assign ddr3_cs0_data[291:290]   = dbg_rdlvl_err;
      assign ddr3_cs0_data[292]       = phy_init_done;
      assign ddr3_cs0_data[293]       = 1'b0; // Reserve for ERROR from TrafficGen
      assign ddr3_cs0_data[383:294]   = 'b0;

      //*******************************************************
      // CS1 - Input VIO for monitoring PHY status and
      //       write leveling/calibration delays
      //*******************************************************

      // Support for only up to 18 DQS groups
      if (DQS_WIDTH <= 18) begin: gen_dqs_le_18_cs1
        assign ddr3_cs1_async_in[5*DQS_WIDTH-1:0]     = dbg_wl_odelay_dq_tap_cnt;
        assign ddr3_cs1_async_in[5*DQS_WIDTH+89:90]   = dbg_wl_odelay_dqs_tap_cnt;
        assign ddr3_cs1_async_in[DQS_WIDTH+179:180]   = dbg_wl_dqs_inverted;
        assign ddr3_cs1_async_in[2*DQS_WIDTH+197:198] = dbg_wr_calib_clk_delay;
      end else begin: gen_dqs_gt_18_cs1
        assign ddr3_cs1_async_in[89:0]    = dbg_wl_odelay_dq_tap_cnt[89:0];
        assign ddr3_cs1_async_in[179:90]  = dbg_wl_odelay_dqs_tap_cnt[89:0];
        assign ddr3_cs1_async_in[197:180] = dbg_wl_dqs_inverted[17:0];
        assign ddr3_cs1_async_in[233:198] = dbg_wr_calib_clk_delay[35:0];
      end

      assign ddr3_cs1_async_in[235:234] = dbg_rdlvl_done[1:0];
      assign ddr3_cs1_async_in[237:236] = dbg_rdlvl_err[1:0];
      assign ddr3_cs1_async_in[238]     = phy_init_done;
      assign ddr3_cs1_async_in[239]     = 1'b0; // Pre-MIG 3.4: Used for rst_pll_ck_fb
      assign ddr3_cs1_async_in[240]     = 1'b0; // Reserve for ERROR from TrafficGen
      assign ddr3_cs1_async_in[255:241] = 'b0;

      //*******************************************************
      // CS2 - Input VIO for monitoring Read Calibration
      //       results.
      //*******************************************************

      // Support for only up to 18 DQS groups
      if (DQS_WIDTH <= 18) begin: gen_dqs_le_18_cs2
        assign ddr3_cs2_async_in[5*DQS_WIDTH-1:0]     = dbg_cpt_tap_cnt;
        // Reserved for future monitoring of DQ tap counts from read leveling
        assign ddr3_cs2_async_in[5*DQS_WIDTH+89:90]   = 'b0;
        assign ddr3_cs2_async_in[3*DQS_WIDTH+179:180] = dbg_rd_bitslip_cnt;
      end else begin: gen_dqs_gt_18_cs2
        assign ddr3_cs2_async_in[89:0]    = dbg_cpt_tap_cnt[89:0];
        // Reserved for future monitoring of DQ tap counts from read leveling
        assign ddr3_cs2_async_in[179:90]  = 'b0;
        assign ddr3_cs2_async_in[233:180] = dbg_rd_bitslip_cnt[53:0];
      end

      assign ddr3_cs2_async_in[238:234] = dbg_rd_active_dly;
      assign ddr3_cs2_async_in[255:239] = 'b0;

      //*******************************************************
      // CS3 - Input VIO for monitoring more Read Calibration
      //       results.
      //*******************************************************

      // Support for only up to 18 DQS groups
      if (DQS_WIDTH <= 18) begin: gen_dqs_le_18_cs3
        assign ddr3_cs3_async_in[5*DQS_WIDTH-1:0]     = dbg_cpt_first_edge_cnt;
        assign ddr3_cs3_async_in[5*DQS_WIDTH+89:90]   = dbg_cpt_second_edge_cnt;
        assign ddr3_cs3_async_in[2*DQS_WIDTH+179:180] = dbg_rd_clkdly_cnt;
      end else begin: gen_dqs_gt_18_cs3
        assign ddr3_cs3_async_in[89:0]    = dbg_cpt_first_edge_cnt[89:0];
        assign ddr3_cs3_async_in[179:90]  = dbg_cpt_second_edge_cnt[89:0];
        assign ddr3_cs3_async_in[215:180] = dbg_rd_clkdly_cnt[35:0];
      end

      assign ddr3_cs3_async_in[255:216] = 'b0;

      //*******************************************************
      // CS4 - Output VIO for disabling OCB monitor, Read Phase
      //       Detector, and dynamically changing various
      //       IODELAY values used for adjust read data capture
      //       timing
      //*******************************************************

      assign ddr3_cs4_clk                = clk;
      assign dbg_pd_off             = ddr3_cs4_sync_out[0];
      assign dbg_pd_maintain_off    = ddr3_cs4_sync_out[1];
      assign dbg_pd_maintain_0_only = ddr3_cs4_sync_out[2];
      assign dbg_ocb_mon_off        = ddr3_cs4_sync_out[3];
      assign dbg_inc_cpt            = ddr3_cs4_sync_out[4];
      assign dbg_dec_cpt            = ddr3_cs4_sync_out[5];
      assign dbg_inc_rd_dqs         = ddr3_cs4_sync_out[6];
      assign dbg_dec_rd_dqs         = ddr3_cs4_sync_out[7];
      assign dbg_inc_dec_sel        = ddr3_cs4_sync_out[DQS_CNT_WIDTH+7:8];

      icon5 u_icon
        (
         .CONTROL0 (ddr3_cs0_control),
         .CONTROL1 (ddr3_cs1_control),
         .CONTROL2 (ddr3_cs2_control),
         .CONTROL3 (ddr3_cs3_control),
         .CONTROL4 (ddr3_cs4_control)
         );

      ila384_8 u_cs0
        (
         .CLK     (ddr3_cs0_clk),
         .DATA    (ddr3_cs0_data),
         .TRIG0   (ddr3_cs0_trig),
         .CONTROL (ddr3_cs0_control)
         );

      vio_async_in256 u_cs1
        (
         .ASYNC_IN (ddr3_cs1_async_in),
         .CONTROL  (ddr3_cs1_control)
         );

      vio_async_in256 u_cs2
        (
         .ASYNC_IN (ddr3_cs2_async_in),
         .CONTROL  (ddr3_cs2_control)
         );

      vio_async_in256 u_cs3
        (
         .ASYNC_IN (ddr3_cs3_async_in),
         .CONTROL  (ddr3_cs3_control)
         );

      vio_sync_out32 u_cs4
        (
         .SYNC_OUT (ddr3_cs4_sync_out),
         .CLK      (ddr3_cs4_clk),
         .CONTROL  (ddr3_cs4_control)
         );
    end
  endgenerate



endmodule
