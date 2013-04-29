// -- (c) Copyright 2012 Xilinx, Inc. All rights reserved.
// --
// -- This file contains confidential and proprietary information
// -- of Xilinx, Inc. and is protected under U.S. and 
// -- international copyright and other intellectual property
// -- laws.
// --
// -- DISCLAIMER
// -- This disclaimer is not a license and does not grant any
// -- rights to the materials distributed herewith. Except as
// -- otherwise provided in a valid license issued to you by
// -- Xilinx, and to the maximum extent permitted by applicable
// -- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// -- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// -- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// -- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// -- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// -- (2) Xilinx shall not be liable (whether in contract or tort,
// -- including negligence, or under any other theory of
// -- liability) for any loss or damage of any kind or nature
// -- related to, arising under or in connection with these
// -- materials, including for any direct, or any indirect,
// -- special, incidental, or consequential loss or damage
// -- (including loss of data, profits, goodwill, or any type of
// -- loss or damage suffered as a result of any action brought
// -- by a third party) even if such damage or loss was
// -- reasonably foreseeable or Xilinx had been advised of the
// -- possibility of the same.
// --
// -- CRITICAL APPLICATIONS
// -- Xilinx products are not designed or intended to be fail-
// -- safe, or for use in any application requiring fail-safe
// -- performance, such as life-support or safety devices or
// -- systems, Class III medical devices, nuclear facilities,
// -- applications related to the deployment of airbags, or any
// -- other applications that could lead to death, personal
// -- injury, or severe property or environmental damage
// -- (individually and collectively, "Critical
// -- Applications"). Customer assumes the sole risk and
// -- liability of any use of Xilinx products in Critical
// -- Applications, subject only to applicable laws and
// -- regulations governing limitations on product liability.
// --
// -- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// -- PART OF THIS FILE AT ALL TIMES.
//-----------------------------------------------------------------------------
//
// axis_data_fifo
//   Instantiates AXIS FIFO Generator Core
//
// Verilog-standard:  Verilog 2001
//--------------------------------------------------------------------------
//
// Structure:
//   axis_data_fifo
//     fifo-generator_v9_2
//--------------------------------------------------------------------------

`timescale 1ps/1ps
`default_nettype none

module axis_data_fifo_v1_0_axis_data_fifo #
(
///////////////////////////////////////////////////////////////////////////////
// Parameter Definitions
///////////////////////////////////////////////////////////////////////////////
   parameter         C_FAMILY           = "virtex6",
   parameter integer C_AXIS_TDATA_WIDTH = 32,
   parameter integer C_AXIS_TID_WIDTH   = 1,
   parameter integer C_AXIS_TDEST_WIDTH = 1,
   parameter integer C_AXIS_TUSER_WIDTH = 1,
   parameter [31:0]  C_AXIS_SIGNAL_SET  = 32'hFF,
   // C_AXIS_SIGNAL_SET: each bit if enabled specifies which axis optional signals are present
   //   [0] => TREADY present
   //   [1] => TDATA present
   //   [2] => TSTRB present, TDATA must be present
   //   [3] => TKEEP present, TDATA must be present
   //   [4] => TLAST present
   //   [5] => TID present
   //   [6] => TDEST present
   //   [7] => TUSER present
   parameter integer C_FIFO_DEPTH       = 1024,
   //  Valid values 16,32,64,128,256,512,1024,2048,4096,...
   parameter integer C_FIFO_MODE  = 1,
   // Values: 
   //   0 == N0 FIFO
   //   1 == Regular FIFO
   //   2 == Store and Forward FIFO (Packet Mode). Requires TLAST. 
   parameter integer C_MEMORY_TYPE = 1,
   // Values: 
   //   1=Block RAM
   //   2=Distributed RAM
   //   3=Shift RAM
   //   4=Built-in FIFO
   parameter integer C_IS_ACLK_ASYNC    = 0,
   //  Enables async clock cross when 1.
   parameter integer C_ACLKEN_CONV_MODE  = 0
   // C_ACLKEN_CONV_MODE: Determines how to handle the clock enable pins during
   // clock conversion
   // 0 -- Clock enables not converted
   // 1 -- S_AXIS_ACLKEN can toggle,  M_AXIS_ACLKEN always high.
   // 2 -- S_AXIS_ACLKEN always high, M_AXIS_ACLKEN can toggle.
   // 3 -- S_AXIS_ACLKEN can toggle,  M_AXIS_ACLKEN can toggle.
   )
  (
///////////////////////////////////////////////////////////////////////////////
// Port Declarations
///////////////////////////////////////////////////////////////////////////////
   // System Signals
   input wire                             S_AXIS_ARESETN,
   input wire                             M_AXIS_ARESETN,
/*   input wire ACLKEN,*/

   // Slave side
   input  wire                            S_AXIS_ACLK,
   input  wire                            S_AXIS_ACLKEN,
   input  wire                            S_AXIS_TVALID,
   output wire                            S_AXIS_TREADY,
   input  wire [C_AXIS_TDATA_WIDTH-1:0]   S_AXIS_TDATA,
   input  wire [C_AXIS_TDATA_WIDTH/8-1:0] S_AXIS_TSTRB,
   input  wire [C_AXIS_TDATA_WIDTH/8-1:0] S_AXIS_TKEEP,
   input  wire                            S_AXIS_TLAST,
   input  wire [C_AXIS_TID_WIDTH-1:0]     S_AXIS_TID,
   input  wire [C_AXIS_TDEST_WIDTH-1:0]   S_AXIS_TDEST,
   input  wire [C_AXIS_TUSER_WIDTH-1:0]   S_AXIS_TUSER,

   // Master side
   input  wire                            M_AXIS_ACLK,
   input  wire                            M_AXIS_ACLKEN,
   output wire                            M_AXIS_TVALID,
   input  wire                            M_AXIS_TREADY,
   output wire [C_AXIS_TDATA_WIDTH-1:0]   M_AXIS_TDATA,
   output wire [C_AXIS_TDATA_WIDTH/8-1:0] M_AXIS_TSTRB,
   output wire [C_AXIS_TDATA_WIDTH/8-1:0] M_AXIS_TKEEP,
   output wire                            M_AXIS_TLAST,
   output wire [C_AXIS_TID_WIDTH-1:0]     M_AXIS_TID,
   output wire [C_AXIS_TDEST_WIDTH-1:0]   M_AXIS_TDEST,
   output wire [C_AXIS_TUSER_WIDTH-1:0]   M_AXIS_TUSER,

   // Status signals
   output wire [31:0]                     AXIS_DATA_COUNT,
   output wire [31:0]                     AXIS_WR_DATA_COUNT,
   output wire [31:0]                     AXIS_RD_DATA_COUNT
   );

////////////////////////////////////////////////////////////////////////////////
// Functions
////////////////////////////////////////////////////////////////////////////////
`include "axis_infrastructure_v1_0_axis_infrastructure.vh"

////////////////////////////////////////////////////////////////////////////////
// Local parameters
////////////////////////////////////////////////////////////////////////////////
localparam P_TREADY_EXISTS = C_AXIS_SIGNAL_SET[0]? 1: 0;
localparam P_TDATA_EXISTS  = C_AXIS_SIGNAL_SET[1]? 1: 0;
localparam P_TSTRB_EXISTS  = C_AXIS_SIGNAL_SET[2]? 1: 0;
localparam P_TKEEP_EXISTS  = C_AXIS_SIGNAL_SET[3]? 1: 0;
localparam P_TLAST_EXISTS  = C_AXIS_SIGNAL_SET[4]? 1: 0;
localparam P_TID_EXISTS    = C_AXIS_SIGNAL_SET[5]? 1: 0;
localparam P_TDEST_EXISTS  = C_AXIS_SIGNAL_SET[6]? 1: 0;
localparam P_TUSER_EXISTS  = C_AXIS_SIGNAL_SET[7]? 1: 0;
localparam P_AXIS_PAYLOAD_WIDTH = f_payload_width(C_AXIS_TDATA_WIDTH, C_AXIS_TID_WIDTH, C_AXIS_TDEST_WIDTH, 
                                             C_AXIS_TUSER_WIDTH, C_AXIS_SIGNAL_SET);
localparam P_WR_PNTR_WIDTH = f_clogb2(C_FIFO_DEPTH);
localparam P_FIFO_COUNT_WIDTH = P_WR_PNTR_WIDTH+1;
localparam P_FIFO_TYPE     = (C_FIFO_DEPTH > 32) ? 1 : 2; // 1 = bram, 2 = lutram.  Force 1 when > 32 deep.
localparam P_IMPLEMENTATION_TYPE_AXIS = C_IS_ACLK_ASYNC ? P_FIFO_TYPE + 10 : P_FIFO_TYPE;
localparam P_COMMON_CLOCK  = C_IS_ACLK_ASYNC ? 0 : 1;
localparam P_MSGON_VAL     = C_IS_ACLK_ASYNC ? 0 : 1;

// Packet mode only valid if tlast is enabled.  Force to 0 if no TLAST
// present.
localparam integer P_APPLICATION_TYPE_AXIS = P_TLAST_EXISTS ? (C_FIFO_MODE == 2) : 0;
localparam integer LP_S_ACLKEN_CAN_TOGGLE = (C_ACLKEN_CONV_MODE == 1) || (C_ACLKEN_CONV_MODE == 3);
localparam integer LP_M_ACLKEN_CAN_TOGGLE = (C_ACLKEN_CONV_MODE == 2) || (C_ACLKEN_CONV_MODE == 3);
                                           

////////////////////////////////////////////////////////////////////////////////
// Wires/Reg declarations
////////////////////////////////////////////////////////////////////////////////
wire [P_FIFO_COUNT_WIDTH-1:0]   axis_data_count_i;
wire [P_FIFO_COUNT_WIDTH-1:0]   axis_wr_data_count_i;
wire [P_FIFO_COUNT_WIDTH-1:0]   axis_rd_data_count_i;
wire                            s_and_m_aresetn_i;
wire                            d1_tvalid;
wire                            d1_tready;
wire [C_AXIS_TDATA_WIDTH-1:0]   d1_tdata;
wire [C_AXIS_TDATA_WIDTH/8-1:0] d1_tstrb;
wire [C_AXIS_TDATA_WIDTH/8-1:0] d1_tkeep;
wire                            d1_tlast;
wire [C_AXIS_TID_WIDTH-1:0]     d1_tid  ;
wire [C_AXIS_TDEST_WIDTH-1:0]   d1_tdest;
wire [C_AXIS_TUSER_WIDTH-1:0]   d1_tuser;

wire                            d2_tvalid;
wire                            d2_tready;
wire [C_AXIS_TDATA_WIDTH-1:0]   d2_tdata;
wire [C_AXIS_TDATA_WIDTH/8-1:0] d2_tstrb;
wire [C_AXIS_TDATA_WIDTH/8-1:0] d2_tkeep;
wire                            d2_tlast;
wire [C_AXIS_TID_WIDTH-1:0]     d2_tid  ;
wire [C_AXIS_TDEST_WIDTH-1:0]   d2_tdest;
wire [C_AXIS_TUSER_WIDTH-1:0]   d2_tuser;

////////////////////////////////////////////////////////////////////////////////
// BEGIN RTL
////////////////////////////////////////////////////////////////////////////////

// Both S and M have to be out of reset before fifo will be let out of reset.
assign s_and_m_aresetn_i = S_AXIS_ARESETN & M_AXIS_ARESETN;

generate 
  if (C_FIFO_MODE > 0) begin : gen_fifo_generator
    assign AXIS_DATA_COUNT    = (P_COMMON_CLOCK == 1) ? {{(32-P_FIFO_COUNT_WIDTH){1'b0}}, axis_data_count_i} : AXIS_WR_DATA_COUNT;
    assign AXIS_WR_DATA_COUNT = (P_COMMON_CLOCK == 0) ? {{(32-P_FIFO_COUNT_WIDTH){1'b0}}, axis_wr_data_count_i} : AXIS_DATA_COUNT;
    assign AXIS_RD_DATA_COUNT = (P_COMMON_CLOCK == 0) ? {{(32-P_FIFO_COUNT_WIDTH){1'b0}}, axis_rd_data_count_i} : AXIS_DATA_COUNT;

    axis_infrastructure_v1_0_util_aclken_converter_wrapper #( 
      .C_TDATA_WIDTH         ( C_AXIS_TDATA_WIDTH     ) ,
      .C_TID_WIDTH           ( C_AXIS_TID_WIDTH       ) ,
      .C_TDEST_WIDTH         ( C_AXIS_TDEST_WIDTH     ) ,
      .C_TUSER_WIDTH         ( C_AXIS_TUSER_WIDTH     ) ,
      .C_S_ACLKEN_CAN_TOGGLE ( LP_S_ACLKEN_CAN_TOGGLE ) ,
      .C_M_ACLKEN_CAN_TOGGLE ( 0                      ) 
    )
    s_util_aclken_converter_wrapper_0 ( 
      .ACLK     ( S_AXIS_ACLK    ) ,
      .ARESETN  ( S_AXIS_ARESETN ) ,
      .S_ACLKEN ( S_AXIS_ACLKEN  ) ,
      .S_VALID  ( S_AXIS_TVALID  ) ,
      .S_READY  ( S_AXIS_TREADY  ) ,
      .S_TDATA  ( S_AXIS_TDATA   ) ,
      .S_TSTRB  ( S_AXIS_TSTRB   ) ,
      .S_TKEEP  ( S_AXIS_TKEEP   ) ,
      .S_TLAST  ( S_AXIS_TLAST   ) ,
      .S_TID    ( S_AXIS_TID     ) ,
      .S_TDEST  ( S_AXIS_TDEST   ) ,
      .S_TUSER  ( S_AXIS_TUSER   ) ,
      .M_ACLKEN ( M_AXIS_ACLKEN  ) ,
      .M_VALID  ( d1_tvalid      ) ,
      .M_READY  ( d1_tready      ) ,
      .M_TDATA  ( d1_tdata       ) ,
      .M_TSTRB  ( d1_tstrb       ) ,
      .M_TKEEP  ( d1_tkeep       ) ,
      .M_TLAST  ( d1_tlast       ) ,
      .M_TID    ( d1_tid         ) ,
      .M_TDEST  ( d1_tdest       ) ,
      .M_TUSER  ( d1_tuser       ) 
    );
    
    // synthesis xilinx_generatecore
   fifo_generator_v9_2 #(
      .C_ADD_NGC_CONSTRAINT                ( 0                          ) ,
      .C_APPLICATION_TYPE_AXIS             ( P_APPLICATION_TYPE_AXIS    ) ,
      .C_APPLICATION_TYPE_RACH             ( 0                          ) ,
      .C_APPLICATION_TYPE_RDCH             ( 0                          ) ,
      .C_APPLICATION_TYPE_WACH             ( 0                          ) ,
      .C_APPLICATION_TYPE_WDCH             ( 0                          ) ,
      .C_APPLICATION_TYPE_WRCH             ( 0                          ) ,
      .C_AXI_ADDR_WIDTH                    ( 32                         ) ,
      .C_AXI_ARUSER_WIDTH                  ( 1                          ) ,
      .C_AXI_AWUSER_WIDTH                  ( 1                          ) ,
      .C_AXI_BUSER_WIDTH                   ( 1                          ) ,
      .C_AXI_DATA_WIDTH                    ( 64                         ) ,
      .C_AXI_ID_WIDTH                      ( 4                          ) ,
      .C_AXI_RUSER_WIDTH                   ( 1                          ) ,
      .C_AXI_TYPE                          ( 0                          ) ,
      .C_AXI_WUSER_WIDTH                   ( 1                          ) ,
      .C_AXIS_TDATA_WIDTH                  ( C_AXIS_TDATA_WIDTH         ) ,
      .C_AXIS_TDEST_WIDTH                  ( C_AXIS_TDEST_WIDTH         ) ,
      .C_AXIS_TID_WIDTH                    ( C_AXIS_TID_WIDTH           ) ,
      .C_AXIS_TKEEP_WIDTH                  ( C_AXIS_TDATA_WIDTH/8       ) ,
      .C_AXIS_TSTRB_WIDTH                  ( C_AXIS_TDATA_WIDTH/8       ) ,
      .C_AXIS_TUSER_WIDTH                  ( C_AXIS_TUSER_WIDTH         ) ,
      .C_AXIS_TYPE                         ( 0                          ) ,
      .C_COMMON_CLOCK                      ( P_COMMON_CLOCK             ) ,
      .C_COUNT_TYPE                        ( 0                          ) ,
      .C_DATA_COUNT_WIDTH                  ( 10                         ) ,
      .C_DEFAULT_VALUE                     ( "BlankString"              ) ,
      .C_DIN_WIDTH                         ( 18                         ) ,
      .C_DIN_WIDTH_AXIS                    ( P_AXIS_PAYLOAD_WIDTH       ) ,
      .C_DIN_WIDTH_RACH                    ( 32                         ) ,
      .C_DIN_WIDTH_RDCH                    ( 64                         ) ,
      .C_DIN_WIDTH_WACH                    ( 32                         ) ,
      .C_DIN_WIDTH_WDCH                    ( 64                         ) ,
      .C_DIN_WIDTH_WRCH                    ( 2                          ) ,
      .C_DOUT_RST_VAL                      ( "0"                        ) ,
      .C_DOUT_WIDTH                        ( 18                         ) ,
      .C_ENABLE_RLOCS                      ( 0                          ) ,
      .C_ENABLE_RST_SYNC                   ( 1                          ) ,
      .C_ERROR_INJECTION_TYPE              ( 0                          ) ,
      .C_ERROR_INJECTION_TYPE_AXIS         ( 0                          ) ,
      .C_ERROR_INJECTION_TYPE_RACH         ( 0                          ) ,
      .C_ERROR_INJECTION_TYPE_RDCH         ( 0                          ) ,
      .C_ERROR_INJECTION_TYPE_WACH         ( 0                          ) ,
      .C_ERROR_INJECTION_TYPE_WDCH         ( 0                          ) ,
      .C_ERROR_INJECTION_TYPE_WRCH         ( 0                          ) ,
      .C_FAMILY                            ( C_FAMILY                   ) ,
      .C_FULL_FLAGS_RST_VAL                ( 1                          ) ,
      .C_HAS_ALMOST_EMPTY                  ( 0                          ) ,
      .C_HAS_ALMOST_FULL                   ( 0                          ) ,
      .C_HAS_AXI_ARUSER                    ( 0                          ) ,
      .C_HAS_AXI_AWUSER                    ( 0                          ) ,
      .C_HAS_AXI_BUSER                     ( 0                          ) ,
      .C_HAS_AXI_RD_CHANNEL                ( 0                          ) ,
      .C_HAS_AXI_RUSER                     ( 0                          ) ,
      .C_HAS_AXI_WR_CHANNEL                ( 0                          ) ,
      .C_HAS_AXI_WUSER                     ( 0                          ) ,
      .C_HAS_AXIS_TDATA                    ( P_TDATA_EXISTS             ) ,
      .C_HAS_AXIS_TDEST                    ( P_TDEST_EXISTS             ) ,
      .C_HAS_AXIS_TID                      ( P_TID_EXISTS               ) ,
      .C_HAS_AXIS_TKEEP                    ( P_TKEEP_EXISTS             ) ,
      .C_HAS_AXIS_TLAST                    ( P_TLAST_EXISTS             ) ,
      .C_HAS_AXIS_TREADY                   ( P_TREADY_EXISTS            ) ,
      .C_HAS_AXIS_TSTRB                    ( P_TSTRB_EXISTS             ) ,
      .C_HAS_AXIS_TUSER                    ( P_TUSER_EXISTS             ) ,
      .C_HAS_BACKUP                        ( 0                          ) ,
      .C_HAS_DATA_COUNT                    ( 0                          ) ,
      .C_HAS_DATA_COUNTS_AXIS              ( 1                          ) ,
      .C_HAS_DATA_COUNTS_RACH              ( 0                          ) ,
      .C_HAS_DATA_COUNTS_RDCH              ( 0                          ) ,
      .C_HAS_DATA_COUNTS_WACH              ( 0                          ) ,
      .C_HAS_DATA_COUNTS_WDCH              ( 0                          ) ,
      .C_HAS_DATA_COUNTS_WRCH              ( 0                          ) ,
      .C_HAS_INT_CLK                       ( 0                          ) ,
      .C_HAS_MASTER_CE                     ( 0                          ) ,
      .C_HAS_MEMINIT_FILE                  ( 0                          ) ,
      .C_HAS_OVERFLOW                      ( 0                          ) ,
      .C_HAS_PROG_FLAGS_AXIS               ( 0                          ) ,
      .C_HAS_PROG_FLAGS_RACH               ( 0                          ) ,
      .C_HAS_PROG_FLAGS_RDCH               ( 0                          ) ,
      .C_HAS_PROG_FLAGS_WACH               ( 0                          ) ,
      .C_HAS_PROG_FLAGS_WDCH               ( 0                          ) ,
      .C_HAS_PROG_FLAGS_WRCH               ( 0                          ) ,
      .C_HAS_RD_DATA_COUNT                 ( 0                          ) ,
      .C_HAS_RD_RST                        ( 0                          ) ,
      .C_HAS_RST                           ( 1                          ) ,
      .C_HAS_SLAVE_CE                      ( 0                          ) ,
      .C_HAS_SRST                          ( 0                          ) ,
      .C_HAS_UNDERFLOW                     ( 0                          ) ,
      .C_HAS_VALID                         ( 0                          ) ,
      .C_HAS_WR_ACK                        ( 0                          ) ,
      .C_HAS_WR_DATA_COUNT                 ( 0                          ) ,
      .C_HAS_WR_RST                        ( 0                          ) ,
      .C_IMPLEMENTATION_TYPE               ( 0                          ) ,
      .C_IMPLEMENTATION_TYPE_AXIS          ( P_IMPLEMENTATION_TYPE_AXIS ) ,
      .C_IMPLEMENTATION_TYPE_RACH          ( 2                          ) ,
      .C_IMPLEMENTATION_TYPE_RDCH          ( 1                          ) ,
      .C_IMPLEMENTATION_TYPE_WACH          ( 2                          ) ,
      .C_IMPLEMENTATION_TYPE_WDCH          ( 1                          ) ,
      .C_IMPLEMENTATION_TYPE_WRCH          ( 2                          ) ,
      .C_INIT_WR_PNTR_VAL                  ( 0                          ) ,
      .C_INTERFACE_TYPE                    ( 1                          ) ,
      .C_MEMORY_TYPE                       ( C_MEMORY_TYPE              ) , //JBC 1=Block RAM 2=Distributed RAM 3=Shift RAM 4=Built-in FIFO
      .C_MIF_FILE_NAME                     ( "BlankString"              ) ,
      .C_MSGON_VAL                         ( P_MSGON_VAL                ) ,
      .C_OPTIMIZATION_MODE                 ( 0                          ) ,
      .C_OVERFLOW_LOW                      ( 0                          ) ,
      .C_PRELOAD_LATENCY                   ( 1                          ) ,
      .C_PRELOAD_REGS                      ( 0                          ) ,
      .C_PRIM_FIFO_TYPE                    ( "4kx4"                     ) ,
      .C_PROG_EMPTY_THRESH_ASSERT_VAL      ( 2                          ) ,
      .C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS ( C_FIFO_DEPTH - 2           ) ,
      .C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH ( 14                         ) ,
      .C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH ( 1022                       ) ,
      .C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH ( 14                         ) ,
      .C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH ( 1022                       ) ,
      .C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH ( 14                         ) ,
      .C_PROG_EMPTY_THRESH_NEGATE_VAL      ( 3                          ) ,
      .C_PROG_EMPTY_TYPE                   ( 0                          ) ,
      .C_PROG_EMPTY_TYPE_AXIS              ( 0                          ) ,
      .C_PROG_EMPTY_TYPE_RACH              ( 0                          ) ,
      .C_PROG_EMPTY_TYPE_RDCH              ( 0                          ) ,
      .C_PROG_EMPTY_TYPE_WACH              ( 0                          ) ,
      .C_PROG_EMPTY_TYPE_WDCH              ( 0                          ) ,
      .C_PROG_EMPTY_TYPE_WRCH              ( 0                          ) ,
      .C_PROG_FULL_THRESH_ASSERT_VAL       ( 1022                       ) ,
      .C_PROG_FULL_THRESH_ASSERT_VAL_AXIS  ( C_FIFO_DEPTH - 1           ) ,
      .C_PROG_FULL_THRESH_ASSERT_VAL_RACH  ( 15                         ) ,
      .C_PROG_FULL_THRESH_ASSERT_VAL_RDCH  ( 1023                       ) ,
      .C_PROG_FULL_THRESH_ASSERT_VAL_WACH  ( 15                         ) ,
      .C_PROG_FULL_THRESH_ASSERT_VAL_WDCH  ( 1023                       ) ,
      .C_PROG_FULL_THRESH_ASSERT_VAL_WRCH  ( 15                         ) ,
      .C_PROG_FULL_THRESH_NEGATE_VAL       ( 1021                       ) ,
      .C_PROG_FULL_TYPE                    ( 0                          ) ,
      .C_PROG_FULL_TYPE_AXIS               ( 0                          ) ,
      .C_PROG_FULL_TYPE_RACH               ( 0                          ) ,
      .C_PROG_FULL_TYPE_RDCH               ( 0                          ) ,
      .C_PROG_FULL_TYPE_WACH               ( 0                          ) ,
      .C_PROG_FULL_TYPE_WDCH               ( 0                          ) ,
      .C_PROG_FULL_TYPE_WRCH               ( 0                          ) ,
      .C_RACH_TYPE                         ( 0                          ) ,
      .C_RD_DATA_COUNT_WIDTH               ( 10                         ) ,
      .C_RD_DEPTH                          ( 1024                       ) ,
      .C_RD_FREQ                           ( 1                          ) ,
      .C_RD_PNTR_WIDTH                     ( 10                         ) ,
      .C_RDCH_TYPE                         ( 0                          ) ,
      .C_REG_SLICE_MODE_AXIS               ( 0                          ) ,
      .C_REG_SLICE_MODE_RACH               ( 0                          ) ,
      .C_REG_SLICE_MODE_RDCH               ( 0                          ) ,
      .C_REG_SLICE_MODE_WACH               ( 0                          ) ,
      .C_REG_SLICE_MODE_WDCH               ( 0                          ) ,
      .C_REG_SLICE_MODE_WRCH               ( 0                          ) ,
      .C_SYNCHRONIZER_STAGE                ( 2                          ) ,
      .C_UNDERFLOW_LOW                     ( 0                          ) ,
      .C_USE_COMMON_OVERFLOW               ( 0                          ) ,
      .C_USE_COMMON_UNDERFLOW              ( 0                          ) ,
      .C_USE_DEFAULT_SETTINGS              ( 0                          ) ,
      .C_USE_DOUT_RST                      ( 1                          ) ,
      .C_USE_ECC                           ( 0                          ) ,
      .C_USE_ECC_AXIS                      ( 0                          ) ,
      .C_USE_ECC_RACH                      ( 0                          ) ,
      .C_USE_ECC_RDCH                      ( 0                          ) ,
      .C_USE_ECC_WACH                      ( 0                          ) ,
      .C_USE_ECC_WDCH                      ( 0                          ) ,
      .C_USE_ECC_WRCH                      ( 0                          ) ,
      .C_USE_EMBEDDED_REG                  ( 0                          ) ,
      .C_USE_FIFO16_FLAGS                  ( 0                          ) ,
      .C_USE_FWFT_DATA_COUNT               ( 0                          ) ,
      .C_VALID_LOW                         ( 0                          ) ,
      .C_WACH_TYPE                         ( 0                          ) ,
      .C_WDCH_TYPE                         ( 0                          ) ,
      .C_WR_ACK_LOW                        ( 0                          ) ,
      .C_WR_DATA_COUNT_WIDTH               ( 10                         ) ,
      .C_WR_DEPTH                          ( 1024                       ) ,
      .C_WR_DEPTH_AXIS                     ( C_FIFO_DEPTH               ) ,
      .C_WR_DEPTH_RACH                     ( 16                         ) ,
      .C_WR_DEPTH_RDCH                     ( 1024                       ) ,
      .C_WR_DEPTH_WACH                     ( 16                         ) ,
      .C_WR_DEPTH_WDCH                     ( 1024                       ) ,
      .C_WR_DEPTH_WRCH                     ( 16                         ) ,
      .C_WR_FREQ                           ( 1                          ) ,
      .C_WR_PNTR_WIDTH                     ( 10                         ) ,
      .C_WR_PNTR_WIDTH_AXIS                ( P_WR_PNTR_WIDTH            ) ,
      .C_WR_PNTR_WIDTH_RACH                ( 4                          ) ,
      .C_WR_PNTR_WIDTH_RDCH                ( 10                         ) ,
      .C_WR_PNTR_WIDTH_WACH                ( 4                          ) ,
      .C_WR_PNTR_WIDTH_WDCH                ( 10                         ) ,
      .C_WR_PNTR_WIDTH_WRCH                ( 4                          ) ,
      .C_WR_RESPONSE_LATENCY               ( 1                          ) ,
      .C_WRCH_TYPE                         ( 0                          ) 
    )
    fifo_generator_v9_2_inst (
      .M_ACLK                   ( M_AXIS_ACLK          ) ,
      .S_ACLK                   ( S_AXIS_ACLK          ) ,
      .S_ARESETN                ( s_and_m_aresetn_i    ) ,
      .S_AXIS_TVALID            ( d1_tvalid            ) ,
      .S_AXIS_TREADY            ( d1_tready            ) ,
      .S_AXIS_TDATA             ( d1_tdata             ) ,
      .S_AXIS_TSTRB             ( d1_tstrb             ) ,
      .S_AXIS_TKEEP             ( d1_tkeep             ) ,
      .S_AXIS_TLAST             ( d1_tlast             ) ,
      .S_AXIS_TID               ( d1_tid               ) ,
      .S_AXIS_TDEST             ( d1_tdest             ) ,
      .S_AXIS_TUSER             ( d1_tuser             ) ,
      .M_AXIS_TVALID            ( d2_tvalid            ) ,
      .M_AXIS_TREADY            ( d2_tready            ) ,
      .M_AXIS_TDATA             ( d2_tdata             ) ,
      .M_AXIS_TSTRB             ( d2_tstrb             ) ,
      .M_AXIS_TKEEP             ( d2_tkeep             ) ,
      .M_AXIS_TLAST             ( d2_tlast             ) ,
      .M_AXIS_TID               ( d2_tid               ) ,
      .M_AXIS_TDEST             ( d2_tdest             ) ,
      .M_AXIS_TUSER             ( d2_tuser             ) ,
      .AXIS_DATA_COUNT          ( axis_data_count_i    ) ,
      .AXIS_WR_DATA_COUNT       ( axis_wr_data_count_i ) ,
      .AXIS_RD_DATA_COUNT       ( axis_rd_data_count_i ) 
      /*COMMENTED OUT
      .BACKUP                   (                      ) ,
      .BACKUP_MARKER            (                      ) ,
      .CLK                      (                      ) ,
      .RST                      (                      ) ,
      .SRST                     (                      ) ,
      .WR_CLK                   (                      ) ,
      .WR_RST                   (                      ) ,
      .RD_CLK                   (                      ) ,
      .RD_RST                   (                      ) ,
      .DIN                      (                      ) ,
      .WR_EN                    (                      ) ,
      .RD_EN                    (                      ) ,
      .PROG_EMPTY_THRESH        (                      ) ,
      .PROG_EMPTY_THRESH_ASSERT (                      ) ,
      .PROG_EMPTY_THRESH_NEGATE (                      ) ,
      .PROG_FULL_THRESH         (                      ) ,
      .PROG_FULL_THRESH_ASSERT  (                      ) ,
      .PROG_FULL_THRESH_NEGATE  (                      ) ,
      .INT_CLK                  (                      ) ,
      .INJECTDBITERR            (                      ) ,
      .INJECTSBITERR            (                      ) ,
      .DOUT                     (                      ) ,
      .FULL                     (                      ) ,
      .ALMOST_FULL              (                      ) ,
      .WR_ACK                   (                      ) ,
      .OVERFLOW                 (                      ) ,
      .EMPTY                    (                      ) ,
      .ALMOST_EMPTY             (                      ) ,
      .VALID                    (                      ) ,
      .UNDERFLOW                (                      ) ,
      .DATA_COUNT               (                      ) ,
      .RD_DATA_COUNT            (                      ) ,
      .WR_DATA_COUNT            (                      ) ,
      .PROG_FULL                (                      ) ,
      .PROG_EMPTY               (                      ) ,
      .SBITERR                  (                      ) ,
      .DBITERR                  (                      ) ,
      .M_ACLK_EN                (                      ) ,
      .S_ACLK_EN                (                      ) ,
      .S_AXI_AWID               (                      ) ,
      .S_AXI_AWADDR             (                      ) ,
      .S_AXI_AWLEN              (                      ) ,
      .S_AXI_AWSIZE             (                      ) ,
      .S_AXI_AWBURST            (                      ) ,
      .S_AXI_AWLOCK             (                      ) ,
      .S_AXI_AWCACHE            (                      ) ,
      .S_AXI_AWPROT             (                      ) ,
      .S_AXI_AWQOS              (                      ) ,
      .S_AXI_AWREGION           (                      ) ,
      .S_AXI_AWUSER             (                      ) ,
      .S_AXI_AWVALID            (                      ) ,
      .S_AXI_AWREADY            (                      ) ,
      .S_AXI_WID                (                      ) ,
      .S_AXI_WDATA              (                      ) ,
      .S_AXI_WSTRB              (                      ) ,
      .S_AXI_WLAST              (                      ) ,
      .S_AXI_WUSER              (                      ) ,
      .S_AXI_WVALID             (                      ) ,
      .S_AXI_WREADY             (                      ) ,
      .S_AXI_BID                (                      ) ,
      .S_AXI_BRESP              (                      ) ,
      .S_AXI_BUSER              (                      ) ,
      .S_AXI_BVALID             (                      ) ,
      .S_AXI_BREADY             (                      ) ,
      .M_AXI_AWID               (                      ) ,
      .M_AXI_AWADDR             (                      ) ,
      .M_AXI_AWLEN              (                      ) ,
      .M_AXI_AWSIZE             (                      ) ,
      .M_AXI_AWBURST            (                      ) ,
      .M_AXI_AWLOCK             (                      ) ,
      .M_AXI_AWCACHE            (                      ) ,
      .M_AXI_AWPROT             (                      ) ,
      .M_AXI_AWQOS              (                      ) ,
      .M_AXI_AWREGION           (                      ) ,
      .M_AXI_AWUSER             (                      ) ,
      .M_AXI_AWVALID            (                      ) ,
      .M_AXI_AWREADY            (                      ) ,
      .M_AXI_WID                (                      ) ,
      .M_AXI_WDATA              (                      ) ,
      .M_AXI_WSTRB              (                      ) ,
      .M_AXI_WLAST              (                      ) ,
      .M_AXI_WUSER              (                      ) ,
      .M_AXI_WVALID             (                      ) ,
      .M_AXI_WREADY             (                      ) ,
      .M_AXI_BID                (                      ) ,
      .M_AXI_BRESP              (                      ) ,
      .M_AXI_BUSER              (                      ) ,
      .M_AXI_BVALID             (                      ) ,
      .M_AXI_BREADY             (                      ) ,
      .S_AXI_ARID               (                      ) ,
      .S_AXI_ARADDR             (                      ) ,
      .S_AXI_ARLEN              (                      ) ,
      .S_AXI_ARSIZE             (                      ) ,
      .S_AXI_ARBURST            (                      ) ,
      .S_AXI_ARLOCK             (                      ) ,
      .S_AXI_ARCACHE            (                      ) ,
      .S_AXI_ARPROT             (                      ) ,
      .S_AXI_ARQOS              (                      ) ,
      .S_AXI_ARREGION           (                      ) ,
      .S_AXI_ARUSER             (                      ) ,
      .S_AXI_ARVALID            (                      ) ,
      .S_AXI_ARREADY            (                      ) ,
      .S_AXI_RID                (                      ) ,
      .S_AXI_RDATA              (                      ) ,
      .S_AXI_RRESP              (                      ) ,
      .S_AXI_RLAST              (                      ) ,
      .S_AXI_RUSER              (                      ) ,
      .S_AXI_RVALID             (                      ) ,
      .S_AXI_RREADY             (                      ) ,
      .M_AXI_ARID               (                      ) ,
      .M_AXI_ARADDR             (                      ) ,
      .M_AXI_ARLEN              (                      ) ,
      .M_AXI_ARSIZE             (                      ) ,
      .M_AXI_ARBURST            (                      ) ,
      .M_AXI_ARLOCK             (                      ) ,
      .M_AXI_ARCACHE            (                      ) ,
      .M_AXI_ARPROT             (                      ) ,
      .M_AXI_ARQOS              (                      ) ,
      .M_AXI_ARREGION           (                      ) ,
      .M_AXI_ARUSER             (                      ) ,
      .M_AXI_ARVALID            (                      ) ,
      .M_AXI_ARREADY            (                      ) ,
      .M_AXI_RID                (                      ) ,
      .M_AXI_RDATA              (                      ) ,
      .M_AXI_RRESP              (                      ) ,
      .M_AXI_RLAST              (                      ) ,
      .M_AXI_RUSER              (                      ) ,
      .M_AXI_RVALID             (                      ) ,
      .M_AXI_RREADY             (                      ) ,
      .AXI_AW_INJECTSBITERR     (                      ) ,
      .AXI_AW_INJECTDBITERR     (                      ) ,
      .AXI_AW_PROG_FULL_THRESH  (                      ) ,
      .AXI_AW_PROG_EMPTY_THRESH (                      ) ,
      .AXI_AW_DATA_COUNT        (                      ) ,
      .AXI_AW_WR_DATA_COUNT     (                      ) ,
      .AXI_AW_RD_DATA_COUNT     (                      ) ,
      .AXI_AW_SBITERR           (                      ) ,
      .AXI_AW_DBITERR           (                      ) ,
      .AXI_AW_OVERFLOW          (                      ) ,
      .AXI_AW_UNDERFLOW         (                      ) ,
      .AXI_AW_PROG_FULL         (                      ) ,
      .AXI_AW_PROG_EMPTY        (                      ) ,
      .AXI_W_INJECTSBITERR      (                      ) ,
      .AXI_W_INJECTDBITERR      (                      ) ,
      .AXI_W_PROG_FULL_THRESH   (                      ) ,
      .AXI_W_PROG_EMPTY_THRESH  (                      ) ,
      .AXI_W_DATA_COUNT         (                      ) ,
      .AXI_W_WR_DATA_COUNT      (                      ) ,
      .AXI_W_RD_DATA_COUNT      (                      ) ,
      .AXI_W_SBITERR            (                      ) ,
      .AXI_W_DBITERR            (                      ) ,
      .AXI_W_OVERFLOW           (                      ) ,
      .AXI_W_UNDERFLOW          (                      ) ,
      .AXI_W_PROG_FULL          (                      ) ,
      .AXI_W_PROG_EMPTY         (                      ) ,
      .AXI_B_INJECTSBITERR      (                      ) ,
      .AXI_B_INJECTDBITERR      (                      ) ,
      .AXI_B_PROG_FULL_THRESH   (                      ) ,
      .AXI_B_PROG_EMPTY_THRESH  (                      ) ,
      .AXI_B_DATA_COUNT         (                      ) ,
      .AXI_B_WR_DATA_COUNT      (                      ) ,
      .AXI_B_RD_DATA_COUNT      (                      ) ,
      .AXI_B_SBITERR            (                      ) ,
      .AXI_B_DBITERR            (                      ) ,
      .AXI_B_OVERFLOW           (                      ) ,
      .AXI_B_UNDERFLOW          (                      ) ,
      .AXI_B_PROG_FULL          (                      ) ,
      .AXI_B_PROG_EMPTY         (                      ) ,
      .AXI_AR_INJECTSBITERR     (                      ) ,
      .AXI_AR_INJECTDBITERR     (                      ) ,
      .AXI_AR_PROG_FULL_THRESH  (                      ) ,
      .AXI_AR_PROG_EMPTY_THRESH (                      ) ,
      .AXI_AR_DATA_COUNT        (                      ) ,
      .AXI_AR_WR_DATA_COUNT     (                      ) ,
      .AXI_AR_RD_DATA_COUNT     (                      ) ,
      .AXI_AR_SBITERR           (                      ) ,
      .AXI_AR_DBITERR           (                      ) ,
      .AXI_AR_OVERFLOW          (                      ) ,
      .AXI_AR_UNDERFLOW         (                      ) ,
      .AXI_AR_PROG_FULL         (                      ) ,
      .AXI_AR_PROG_EMPTY        (                      ) ,
      .AXI_R_INJECTSBITERR      (                      ) ,
      .AXI_R_INJECTDBITERR      (                      ) ,
      .AXI_R_PROG_FULL_THRESH   (                      ) ,
      .AXI_R_PROG_EMPTY_THRESH  (                      ) ,
      .AXI_R_DATA_COUNT         (                      ) ,
      .AXI_R_WR_DATA_COUNT      (                      ) ,
      .AXI_R_RD_DATA_COUNT      (                      ) ,
      .AXI_R_SBITERR            (                      ) ,
      .AXI_R_DBITERR            (                      ) ,
      .AXI_R_OVERFLOW           (                      ) ,
      .AXI_R_UNDERFLOW          (                      ) ,
      .AXI_R_PROG_FULL          (                      ) ,
      .AXI_R_PROG_EMPTY         (                      ) ,
      .AXIS_INJECTSBITERR       (                      ) ,
      .AXIS_INJECTDBITERR       (                      ) ,
      .AXIS_PROG_FULL_THRESH    (                      ) ,
      .AXIS_PROG_EMPTY_THRESH   (                      ) ,
      .AXIS_SBITERR             (                      ) ,
      .AXIS_DBITERR             (                      ) ,
      .AXIS_OVERFLOW            (                      ) ,
      .AXIS_UNDERFLOW           (                      ) ,
      .AXIS_PROG_FULL           (                      ) ,
      .AXIS_PROG_EMPTY          (                      ) 
      COMMENTED OUT*/
    );

    axis_infrastructure_v1_0_util_aclken_converter_wrapper #( 
      .C_TDATA_WIDTH         ( C_AXIS_TDATA_WIDTH     ) ,
      .C_TID_WIDTH           ( C_AXIS_TID_WIDTH       ) ,
      .C_TDEST_WIDTH         ( C_AXIS_TDEST_WIDTH     ) ,
      .C_TUSER_WIDTH         ( C_AXIS_TUSER_WIDTH     ) ,
      .C_S_ACLKEN_CAN_TOGGLE (                      0 ) ,
      .C_M_ACLKEN_CAN_TOGGLE ( LP_M_ACLKEN_CAN_TOGGLE )
    )
    m_util_aclken_converter_wrapper_0 ( 
      .ACLK     ( M_AXIS_ACLK    ) ,
      .ARESETN  ( M_AXIS_ARESETN ) ,
      .S_ACLKEN ( S_AXIS_ACLKEN  ) ,
      .S_VALID  ( d2_tvalid      ) ,
      .S_READY  ( d2_tready      ) ,
      .S_TDATA  ( d2_tdata       ) ,
      .S_TSTRB  ( d2_tstrb       ) ,
      .S_TKEEP  ( d2_tkeep       ) ,
      .S_TLAST  ( d2_tlast       ) ,
      .S_TID    ( d2_tid         ) ,
      .S_TDEST  ( d2_tdest       ) ,
      .S_TUSER  ( d2_tuser       ) ,
      .M_ACLKEN ( M_AXIS_ACLKEN  ) ,
      .M_VALID  ( M_AXIS_TVALID  ) ,
      .M_READY  ( M_AXIS_TREADY  ) ,
      .M_TDATA  ( M_AXIS_TDATA   ) ,
      .M_TSTRB  ( M_AXIS_TSTRB   ) ,
      .M_TKEEP  ( M_AXIS_TKEEP   ) ,
      .M_TLAST  ( M_AXIS_TLAST   ) ,
      .M_TID    ( M_AXIS_TID     ) ,
      .M_TDEST  ( M_AXIS_TDEST   ) ,
      .M_TUSER  ( M_AXIS_TUSER   )  
    );
  end
  else begin : gen_fifo_passthru
    assign S_AXIS_TREADY   = M_AXIS_TREADY ;
    assign M_AXIS_TVALID   = S_AXIS_TVALID ;
    assign M_AXIS_TDATA    = S_AXIS_TDATA  ;
    assign M_AXIS_TSTRB    = S_AXIS_TSTRB  ;
    assign M_AXIS_TKEEP    = S_AXIS_TKEEP  ;
    assign M_AXIS_TLAST    = S_AXIS_TLAST  ;
    assign M_AXIS_TID      = S_AXIS_TID    ;
    assign M_AXIS_TDEST    = S_AXIS_TDEST  ;
    assign M_AXIS_TUSER    = S_AXIS_TUSER  ;
    assign AXIS_DATA_COUNT = 32'b0;
    assign AXIS_WR_DATA_COUNT = 32'b0;
    assign AXIS_RD_DATA_COUNT = 32'b0;
  end
endgenerate

endmodule // axis_data_fifo

`default_nettype wire

(* BOX_TYPE="BLACK_BOX" *) 

(* black_box *) module fifo_generator_v9_2
  #(
    //-----------------------------------------------------------------------
    // Generic Declarations
    //-----------------------------------------------------------------------
    parameter C_COMMON_CLOCK                 = 0,
    parameter C_COUNT_TYPE                   = 0,
    parameter C_DATA_COUNT_WIDTH             = 2,
    parameter C_DEFAULT_VALUE                = "",
    parameter C_DIN_WIDTH                    = 8,
    parameter C_DOUT_RST_VAL                 = "",
    parameter C_DOUT_WIDTH                   = 8,
    parameter C_ENABLE_RLOCS                 = 0,
    parameter C_FAMILY                       = "",
    parameter C_FULL_FLAGS_RST_VAL           = 1,
    parameter C_HAS_ALMOST_EMPTY             = 0,
    parameter C_HAS_ALMOST_FULL              = 0,
    parameter C_HAS_BACKUP                   = 0,
    parameter C_HAS_DATA_COUNT               = 0,
    parameter C_HAS_INT_CLK                  = 0,
    parameter C_HAS_MEMINIT_FILE             = 0,
    parameter C_HAS_OVERFLOW                 = 0,
    parameter C_HAS_RD_DATA_COUNT            = 0,
    parameter C_HAS_RD_RST                   = 0,
    parameter C_HAS_RST                      = 1,
    parameter C_HAS_SRST                     = 0,
    parameter C_HAS_UNDERFLOW                = 0,
    parameter C_HAS_VALID                    = 0,
    parameter C_HAS_WR_ACK                   = 0,
    parameter C_HAS_WR_DATA_COUNT            = 0,
    parameter C_HAS_WR_RST                   = 0,
    parameter C_IMPLEMENTATION_TYPE          = 0,
    parameter C_INIT_WR_PNTR_VAL             = 0,
    parameter C_MEMORY_TYPE                  = 1,
    parameter C_MIF_FILE_NAME                = "",
    parameter C_OPTIMIZATION_MODE            = 0,
    parameter C_OVERFLOW_LOW                 = 0,
    parameter C_PRELOAD_LATENCY              = 1,
    parameter C_PRELOAD_REGS                 = 0,
    parameter C_PRIM_FIFO_TYPE               = "4kx4",
    parameter C_PROG_EMPTY_THRESH_ASSERT_VAL = 0,
    parameter C_PROG_EMPTY_THRESH_NEGATE_VAL = 0,
    parameter C_PROG_EMPTY_TYPE              = 0,
    parameter C_PROG_FULL_THRESH_ASSERT_VAL  = 0,
    parameter C_PROG_FULL_THRESH_NEGATE_VAL  = 0,
    parameter C_PROG_FULL_TYPE               = 0,
    parameter C_RD_DATA_COUNT_WIDTH          = 2,
    parameter C_RD_DEPTH                     = 256,
    parameter C_RD_FREQ                      = 1,
    parameter C_RD_PNTR_WIDTH                = 8,
    parameter C_UNDERFLOW_LOW                = 0,
    parameter C_USE_DOUT_RST                 = 0,
    parameter C_USE_ECC                      = 0,
    parameter C_USE_EMBEDDED_REG             = 0,
    parameter C_USE_FIFO16_FLAGS             = 0,
    parameter C_USE_FWFT_DATA_COUNT          = 0,
    parameter C_VALID_LOW                    = 0,
    parameter C_WR_ACK_LOW                   = 0,
    parameter C_WR_DATA_COUNT_WIDTH          = 2,
    parameter C_WR_DEPTH                     = 256,
    parameter C_WR_FREQ                      = 1,
    parameter C_WR_PNTR_WIDTH                = 8,
    parameter C_WR_RESPONSE_LATENCY          = 1,
    parameter C_MSGON_VAL                    = 1,
    parameter C_ENABLE_RST_SYNC              = 1,
    parameter C_ERROR_INJECTION_TYPE         = 0,
    parameter C_SYNCHRONIZER_STAGE           = 2,

    // AXI Interface related parameters start here
    parameter C_INTERFACE_TYPE               = 0, // 0: Native Interface, 1: AXI Interface
    parameter C_AXI_TYPE                     = 0, // 0: AXI Stream, 1: AXI Full, 2: AXI Lite
    parameter C_HAS_AXI_WR_CHANNEL           = 0,
    parameter C_HAS_AXI_RD_CHANNEL           = 0,
    parameter C_HAS_SLAVE_CE                 = 0,
    parameter C_HAS_MASTER_CE                = 0,
    parameter C_ADD_NGC_CONSTRAINT           = 0,
    parameter C_USE_COMMON_UNDERFLOW         = 0,
    parameter C_USE_COMMON_OVERFLOW          = 0,
    parameter C_USE_DEFAULT_SETTINGS         = 0,

    // AXI Full/Lite
    parameter C_AXI_ID_WIDTH                 = 0,
    parameter C_AXI_ADDR_WIDTH               = 0,
    parameter C_AXI_DATA_WIDTH               = 0,
    parameter C_HAS_AXI_AWUSER               = 0,
    parameter C_HAS_AXI_WUSER                = 0,
    parameter C_HAS_AXI_BUSER                = 0,
    parameter C_HAS_AXI_ARUSER               = 0,
    parameter C_HAS_AXI_RUSER                = 0,
    parameter C_AXI_ARUSER_WIDTH             = 0,
    parameter C_AXI_AWUSER_WIDTH             = 0,
    parameter C_AXI_WUSER_WIDTH              = 0,
    parameter C_AXI_BUSER_WIDTH              = 0,
    parameter C_AXI_RUSER_WIDTH              = 0,

    // AXI Streaming
    parameter C_HAS_AXIS_TDATA               = 0,
    parameter C_HAS_AXIS_TID                 = 0,
    parameter C_HAS_AXIS_TDEST               = 0,
    parameter C_HAS_AXIS_TUSER               = 0,
    parameter C_HAS_AXIS_TREADY              = 0,
    parameter C_HAS_AXIS_TLAST               = 0,
    parameter C_HAS_AXIS_TSTRB               = 0,
    parameter C_HAS_AXIS_TKEEP               = 0,
    parameter C_AXIS_TDATA_WIDTH             = 1,
    parameter C_AXIS_TID_WIDTH               = 1,
    parameter C_AXIS_TDEST_WIDTH             = 1,
    parameter C_AXIS_TUSER_WIDTH             = 1,
    parameter C_AXIS_TSTRB_WIDTH             = 1,
    parameter C_AXIS_TKEEP_WIDTH             = 1,

    // AXI Channel Type
    // WACH --> Write Address Channel
    // WDCH --> Write Data Channel
    // WRCH --> Write Response Channel
    // RACH --> Read Address Channel
    // RDCH --> Read Data Channel
    // AXIS --> AXI Streaming
    parameter C_WACH_TYPE                    = 0, // 0 = FIFO, 1 = Register Slice, 2 = Pass Through Logic
    parameter C_WDCH_TYPE                    = 0, // 0 = FIFO, 1 = Register Slice, 2 = Pass Through Logie
    parameter C_WRCH_TYPE                    = 0, // 0 = FIFO, 1 = Register Slice, 2 = Pass Through Logie
    parameter C_RACH_TYPE                    = 0, // 0 = FIFO, 1 = Register Slice, 2 = Pass Through Logie
    parameter C_RDCH_TYPE                    = 0, // 0 = FIFO, 1 = Register Slice, 2 = Pass Through Logie
    parameter C_AXIS_TYPE                    = 0, // 0 = FIFO, 1 = Register Slice, 2 = Pass Through Logie

    // AXI Implementation Type
    // 1 = Common Clock Block RAM FIFO
    // 2 = Common Clock Distributed RAM FIFO
    // 11 = Independent Clock Block RAM FIFO
    // 12 = Independent Clock Distributed RAM FIFO
    parameter C_IMPLEMENTATION_TYPE_WACH     = 0,
    parameter C_IMPLEMENTATION_TYPE_WDCH     = 0,
    parameter C_IMPLEMENTATION_TYPE_WRCH     = 0,
    parameter C_IMPLEMENTATION_TYPE_RACH     = 0,
    parameter C_IMPLEMENTATION_TYPE_RDCH     = 0,
    parameter C_IMPLEMENTATION_TYPE_AXIS     = 0,

    // AXI FIFO Type
    // 0 = Data FIFO
    // 1 = Packet FIFO
    // 2 = Low Latency Sync FIFO
    // 3 = Low Latency Async FIFO
    parameter C_APPLICATION_TYPE_WACH        = 0,
    parameter C_APPLICATION_TYPE_WDCH        = 0,
    parameter C_APPLICATION_TYPE_WRCH        = 0,
    parameter C_APPLICATION_TYPE_RACH        = 0,
    parameter C_APPLICATION_TYPE_RDCH        = 0,
    parameter C_APPLICATION_TYPE_AXIS        = 0,

    // Enable ECC
    // 0 = ECC disabled
    // 1 = ECC enabled
    parameter C_USE_ECC_WACH                 = 0,
    parameter C_USE_ECC_WDCH                 = 0,
    parameter C_USE_ECC_WRCH                 = 0,
    parameter C_USE_ECC_RACH                 = 0,
    parameter C_USE_ECC_RDCH                 = 0,
    parameter C_USE_ECC_AXIS                 = 0,

    // ECC Error Injection Type
    // 0 = No Error Injection
    // 1 = Single Bit Error Injection
    // 2 = Double Bit Error Injection
    // 3 = Single Bit and Double Bit Error Injection
    parameter C_ERROR_INJECTION_TYPE_WACH    = 0,
    parameter C_ERROR_INJECTION_TYPE_WDCH    = 0,
    parameter C_ERROR_INJECTION_TYPE_WRCH    = 0,
    parameter C_ERROR_INJECTION_TYPE_RACH    = 0,
    parameter C_ERROR_INJECTION_TYPE_RDCH    = 0,
    parameter C_ERROR_INJECTION_TYPE_AXIS    = 0,

    // Input Data Width
    // Accumulation of all AXI input signal's width
    parameter C_DIN_WIDTH_WACH               = 1,
    parameter C_DIN_WIDTH_WDCH               = 1,
    parameter C_DIN_WIDTH_WRCH               = 1,
    parameter C_DIN_WIDTH_RACH               = 1,
    parameter C_DIN_WIDTH_RDCH               = 1,
    parameter C_DIN_WIDTH_AXIS               = 1,

    parameter C_WR_DEPTH_WACH                = 16,
    parameter C_WR_DEPTH_WDCH                = 16,
    parameter C_WR_DEPTH_WRCH                = 16,
    parameter C_WR_DEPTH_RACH                = 16,
    parameter C_WR_DEPTH_RDCH                = 16,
    parameter C_WR_DEPTH_AXIS                = 16,

    parameter C_WR_PNTR_WIDTH_WACH           = 4,
    parameter C_WR_PNTR_WIDTH_WDCH           = 4,
    parameter C_WR_PNTR_WIDTH_WRCH           = 4,
    parameter C_WR_PNTR_WIDTH_RACH           = 4,
    parameter C_WR_PNTR_WIDTH_RDCH           = 4,
    parameter C_WR_PNTR_WIDTH_AXIS           = 4,

    parameter C_HAS_DATA_COUNTS_WACH         = 0,
    parameter C_HAS_DATA_COUNTS_WDCH         = 0,
    parameter C_HAS_DATA_COUNTS_WRCH         = 0,
    parameter C_HAS_DATA_COUNTS_RACH         = 0,
    parameter C_HAS_DATA_COUNTS_RDCH         = 0,
    parameter C_HAS_DATA_COUNTS_AXIS         = 0,

    parameter C_HAS_PROG_FLAGS_WACH          = 0,
    parameter C_HAS_PROG_FLAGS_WDCH          = 0,
    parameter C_HAS_PROG_FLAGS_WRCH          = 0,
    parameter C_HAS_PROG_FLAGS_RACH          = 0,
    parameter C_HAS_PROG_FLAGS_RDCH          = 0,
    parameter C_HAS_PROG_FLAGS_AXIS          = 0,

    parameter C_PROG_FULL_TYPE_WACH          = 0,
    parameter C_PROG_FULL_TYPE_WDCH          = 0,
    parameter C_PROG_FULL_TYPE_WRCH          = 0,
    parameter C_PROG_FULL_TYPE_RACH          = 0,
    parameter C_PROG_FULL_TYPE_RDCH          = 0,
    parameter C_PROG_FULL_TYPE_AXIS          = 0,

    parameter C_PROG_FULL_THRESH_ASSERT_VAL_WACH      = 0,
    parameter C_PROG_FULL_THRESH_ASSERT_VAL_WDCH      = 0,
    parameter C_PROG_FULL_THRESH_ASSERT_VAL_WRCH      = 0,
    parameter C_PROG_FULL_THRESH_ASSERT_VAL_RACH      = 0,
    parameter C_PROG_FULL_THRESH_ASSERT_VAL_RDCH      = 0,
    parameter C_PROG_FULL_THRESH_ASSERT_VAL_AXIS      = 0,

    parameter C_PROG_EMPTY_TYPE_WACH         = 0,
    parameter C_PROG_EMPTY_TYPE_WDCH         = 0,
    parameter C_PROG_EMPTY_TYPE_WRCH         = 0,
    parameter C_PROG_EMPTY_TYPE_RACH         = 0,
    parameter C_PROG_EMPTY_TYPE_RDCH         = 0,
    parameter C_PROG_EMPTY_TYPE_AXIS         = 0,

    parameter C_PROG_EMPTY_THRESH_ASSERT_VAL_WACH     = 0,
    parameter C_PROG_EMPTY_THRESH_ASSERT_VAL_WDCH     = 0,
    parameter C_PROG_EMPTY_THRESH_ASSERT_VAL_WRCH     = 0,
    parameter C_PROG_EMPTY_THRESH_ASSERT_VAL_RACH     = 0,
    parameter C_PROG_EMPTY_THRESH_ASSERT_VAL_RDCH     = 0,
    parameter C_PROG_EMPTY_THRESH_ASSERT_VAL_AXIS     = 0,

    parameter C_REG_SLICE_MODE_WACH          = 0,
    parameter C_REG_SLICE_MODE_WDCH          = 0,
    parameter C_REG_SLICE_MODE_WRCH          = 0,
    parameter C_REG_SLICE_MODE_RACH          = 0,
    parameter C_REG_SLICE_MODE_RDCH          = 0,
    parameter C_REG_SLICE_MODE_AXIS          = 0

    )

   (
    //------------------------------------------------------------------------------
    // Input and Output Declarations
    //------------------------------------------------------------------------------

    // Conventional FIFO Interface Signals
    input                               BACKUP,
    input                               BACKUP_MARKER,
    input                               CLK,
    input                               RST,
    input                               SRST,
    input                               WR_CLK,
    input                               WR_RST,
    input                               RD_CLK,
    input                               RD_RST,
    input [C_DIN_WIDTH-1:0]             DIN,
    input                               WR_EN,
    input                               RD_EN,
    // Optional inputs
    input [C_RD_PNTR_WIDTH-1:0]         PROG_EMPTY_THRESH,
    input [C_RD_PNTR_WIDTH-1:0]         PROG_EMPTY_THRESH_ASSERT,
    input [C_RD_PNTR_WIDTH-1:0]         PROG_EMPTY_THRESH_NEGATE,
    input [C_WR_PNTR_WIDTH-1:0]         PROG_FULL_THRESH,
    input [C_WR_PNTR_WIDTH-1:0]         PROG_FULL_THRESH_ASSERT,
    input [C_WR_PNTR_WIDTH-1:0]         PROG_FULL_THRESH_NEGATE,
    input                               INT_CLK,
    input                               INJECTDBITERR,
    input                               INJECTSBITERR,

    output [C_DOUT_WIDTH-1:0]           DOUT,
    output                              FULL,
    output                              ALMOST_FULL,
    output                              WR_ACK,
    output                              OVERFLOW,
    output                              EMPTY,
    output                              ALMOST_EMPTY,
    output                              VALID,
    output                              UNDERFLOW,
    output [C_DATA_COUNT_WIDTH-1:0]     DATA_COUNT,
    output [C_RD_DATA_COUNT_WIDTH-1:0]  RD_DATA_COUNT,
    output [C_WR_DATA_COUNT_WIDTH-1:0]  WR_DATA_COUNT,
    output                              PROG_FULL,
    output                              PROG_EMPTY,
    output                              SBITERR,
    output                              DBITERR,


    // AXI Global Signal
    input                               M_ACLK,
    input                               S_ACLK,
    input                               S_ARESETN,
    input                               S_ACLK_EN,
    input                               M_ACLK_EN,
    
    // AXI Full/Lite Slave Write Channel (write side)
    input [C_AXI_ID_WIDTH-1:0]          S_AXI_AWID,
    input [C_AXI_ADDR_WIDTH-1:0]        S_AXI_AWADDR,
    input [8-1:0]                       S_AXI_AWLEN,
    input [3-1:0]                       S_AXI_AWSIZE,
    input [2-1:0]                       S_AXI_AWBURST,
    input [2-1:0]                       S_AXI_AWLOCK,
    input [4-1:0]                       S_AXI_AWCACHE,
    input [3-1:0]                       S_AXI_AWPROT,
    input [4-1:0]                       S_AXI_AWQOS,
    input [4-1:0]                       S_AXI_AWREGION,
    input [C_AXI_AWUSER_WIDTH-1:0]      S_AXI_AWUSER,
    input                               S_AXI_AWVALID,
    output                              S_AXI_AWREADY,
    input [C_AXI_ID_WIDTH-1:0]          S_AXI_WID,
    input [C_AXI_DATA_WIDTH-1:0]        S_AXI_WDATA,
    input [C_AXI_DATA_WIDTH/8-1:0]      S_AXI_WSTRB,
    input                               S_AXI_WLAST,
    input [C_AXI_WUSER_WIDTH-1:0]       S_AXI_WUSER,
    input                               S_AXI_WVALID,
    output                              S_AXI_WREADY,
    output [C_AXI_ID_WIDTH-1:0]         S_AXI_BID,
    output [2-1:0]                      S_AXI_BRESP,
    output [C_AXI_BUSER_WIDTH-1:0]      S_AXI_BUSER,
    output                              S_AXI_BVALID,
    input                               S_AXI_BREADY,
    
    // AXI Full/Lite Master Write Channel (Read side)
    output [C_AXI_ID_WIDTH-1:0]         M_AXI_AWID,
    output [C_AXI_ADDR_WIDTH-1:0]       M_AXI_AWADDR,
    output [8-1:0]                      M_AXI_AWLEN,
    output [3-1:0]                      M_AXI_AWSIZE,
    output [2-1:0]                      M_AXI_AWBURST,
    output [2-1:0]                      M_AXI_AWLOCK,
    output [4-1:0]                      M_AXI_AWCACHE,
    output [3-1:0]                      M_AXI_AWPROT,
    output [4-1:0]                      M_AXI_AWQOS,
    output [4-1:0]                      M_AXI_AWREGION,
    output [C_AXI_AWUSER_WIDTH-1:0]     M_AXI_AWUSER,
    output                              M_AXI_AWVALID,
    input                               M_AXI_AWREADY,
    output [C_AXI_ID_WIDTH-1:0]         M_AXI_WID,
    output [C_AXI_DATA_WIDTH-1:0]       M_AXI_WDATA,
    output [C_AXI_DATA_WIDTH/8-1:0]     M_AXI_WSTRB,
    output                              M_AXI_WLAST,
    output [C_AXI_WUSER_WIDTH-1:0]      M_AXI_WUSER,
    output                              M_AXI_WVALID,
    input                               M_AXI_WREADY,
    input [C_AXI_ID_WIDTH-1:0]          M_AXI_BID,
    input [2-1:0]                       M_AXI_BRESP,
    input [C_AXI_BUSER_WIDTH-1:0]       M_AXI_BUSER,
    input                               M_AXI_BVALID,
    output                              M_AXI_BREADY,
    
    
    // AXI Full/Lite Slave Read Channel (Write side)
    input [C_AXI_ID_WIDTH-1:0]          S_AXI_ARID,
    input [C_AXI_ADDR_WIDTH-1:0]        S_AXI_ARADDR, 
    input [8-1:0]                       S_AXI_ARLEN,
    input [3-1:0]                       S_AXI_ARSIZE,
    input [2-1:0]                       S_AXI_ARBURST,
    input [2-1:0]                       S_AXI_ARLOCK,
    input [4-1:0]                       S_AXI_ARCACHE,
    input [3-1:0]                       S_AXI_ARPROT,
    input [4-1:0]                       S_AXI_ARQOS,
    input [4-1:0]                       S_AXI_ARREGION,
    input [C_AXI_ARUSER_WIDTH-1:0]      S_AXI_ARUSER,
    input                               S_AXI_ARVALID,
    output                              S_AXI_ARREADY,
    output [C_AXI_ID_WIDTH-1:0]         S_AXI_RID,       
    output [C_AXI_DATA_WIDTH-1:0]       S_AXI_RDATA, 
    output [2-1:0]                      S_AXI_RRESP,
    output                              S_AXI_RLAST,
    output [C_AXI_RUSER_WIDTH-1:0]      S_AXI_RUSER,
    output                              S_AXI_RVALID,
    input                               S_AXI_RREADY,
    
    
    
    // AXI Full/Lite Master Read Channel (Read side)
    output [C_AXI_ID_WIDTH-1:0]         M_AXI_ARID,        
    output [C_AXI_ADDR_WIDTH-1:0]       M_AXI_ARADDR,  
    output [8-1:0]                      M_AXI_ARLEN,
    output [3-1:0]                      M_AXI_ARSIZE,
    output [2-1:0]                      M_AXI_ARBURST,
    output [2-1:0]                      M_AXI_ARLOCK,
    output [4-1:0]                      M_AXI_ARCACHE,
    output [3-1:0]                      M_AXI_ARPROT,
    output [4-1:0]                      M_AXI_ARQOS,
    output [4-1:0]                      M_AXI_ARREGION,
    output [C_AXI_ARUSER_WIDTH-1:0]     M_AXI_ARUSER,
    output                              M_AXI_ARVALID,
    input                               M_AXI_ARREADY,
    input [C_AXI_ID_WIDTH-1:0]          M_AXI_RID,        
    input [C_AXI_DATA_WIDTH-1:0]        M_AXI_RDATA,  
    input [2-1:0]                       M_AXI_RRESP,
    input                               M_AXI_RLAST,
    input [C_AXI_RUSER_WIDTH-1:0]       M_AXI_RUSER,
    input                               M_AXI_RVALID,
    output                              M_AXI_RREADY,
    
    
    // AXI Streaming Slave Signals (Write side)
    input                               S_AXIS_TVALID,
    output                              S_AXIS_TREADY,
    input [C_AXIS_TDATA_WIDTH-1:0]      S_AXIS_TDATA,
    input [C_AXIS_TSTRB_WIDTH-1:0]      S_AXIS_TSTRB,
    input [C_AXIS_TKEEP_WIDTH-1:0]      S_AXIS_TKEEP,
    input                               S_AXIS_TLAST,
    input [C_AXIS_TID_WIDTH-1:0]        S_AXIS_TID,
    input [C_AXIS_TDEST_WIDTH-1:0]      S_AXIS_TDEST,
    input [C_AXIS_TUSER_WIDTH-1:0]      S_AXIS_TUSER,
    
    // AXI Streaming Master Signals (Read side)
    output                              M_AXIS_TVALID,
    input                               M_AXIS_TREADY,
    output [C_AXIS_TDATA_WIDTH-1:0]     M_AXIS_TDATA,
    output [C_AXIS_TSTRB_WIDTH-1:0]     M_AXIS_TSTRB,
    output [C_AXIS_TKEEP_WIDTH-1:0]     M_AXIS_TKEEP,
    output                              M_AXIS_TLAST,
    output [C_AXIS_TID_WIDTH-1:0]       M_AXIS_TID,
    output [C_AXIS_TDEST_WIDTH-1:0]     M_AXIS_TDEST,
    output [C_AXIS_TUSER_WIDTH-1:0]     M_AXIS_TUSER,
    
           
    
    
    // AXI Full/Lite Write Address Channel Signals
    input                               AXI_AW_INJECTSBITERR,
    input                               AXI_AW_INJECTDBITERR,
    input  [C_WR_PNTR_WIDTH_WACH-1:0]   AXI_AW_PROG_FULL_THRESH,
    input  [C_WR_PNTR_WIDTH_WACH-1:0]   AXI_AW_PROG_EMPTY_THRESH,
    output [C_WR_PNTR_WIDTH_WACH:0]     AXI_AW_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_WACH:0]     AXI_AW_WR_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_WACH:0]     AXI_AW_RD_DATA_COUNT,
    output                              AXI_AW_SBITERR,
    output                              AXI_AW_DBITERR,
    output                              AXI_AW_OVERFLOW,
    output                              AXI_AW_UNDERFLOW,
    
    
    // AXI Full/Lite Write Data Channel Signals
    input                               AXI_W_INJECTSBITERR,
    input                               AXI_W_INJECTDBITERR,
    input  [C_WR_PNTR_WIDTH_WDCH-1:0]   AXI_W_PROG_FULL_THRESH,
    input  [C_WR_PNTR_WIDTH_WDCH-1:0]   AXI_W_PROG_EMPTY_THRESH,
    output [C_WR_PNTR_WIDTH_WDCH:0]     AXI_W_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_WDCH:0]     AXI_W_WR_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_WDCH:0]     AXI_W_RD_DATA_COUNT,
    output                              AXI_W_SBITERR,
    output                              AXI_W_DBITERR,
    output                              AXI_W_OVERFLOW,
    output                              AXI_W_UNDERFLOW,
    
    
    // AXI Full/Lite Write Response Channel Signals
    input                               AXI_B_INJECTSBITERR,
    input                               AXI_B_INJECTDBITERR,
    input  [C_WR_PNTR_WIDTH_WRCH-1:0]   AXI_B_PROG_FULL_THRESH,
    input  [C_WR_PNTR_WIDTH_WRCH-1:0]   AXI_B_PROG_EMPTY_THRESH,
    output [C_WR_PNTR_WIDTH_WRCH:0]     AXI_B_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_WRCH:0]     AXI_B_WR_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_WRCH:0]     AXI_B_RD_DATA_COUNT,
    output                              AXI_B_SBITERR,
    output                              AXI_B_DBITERR,
    output                              AXI_B_OVERFLOW,
    output                              AXI_B_UNDERFLOW,
    
    
    
    // AXI Full/Lite Read Address Channel Signals
    input                               AXI_AR_INJECTSBITERR,
    input                               AXI_AR_INJECTDBITERR,
    input  [C_WR_PNTR_WIDTH_RACH-1:0]   AXI_AR_PROG_FULL_THRESH,
    input  [C_WR_PNTR_WIDTH_RACH-1:0]   AXI_AR_PROG_EMPTY_THRESH,
    output [C_WR_PNTR_WIDTH_RACH:0]     AXI_AR_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_RACH:0]     AXI_AR_WR_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_RACH:0]     AXI_AR_RD_DATA_COUNT,
    output                              AXI_AR_SBITERR,
    output                              AXI_AR_DBITERR,
    output                              AXI_AR_OVERFLOW,
    output                              AXI_AR_UNDERFLOW,

    
    // AXI Full/Lite Read Data Channel Signals
    input                               AXI_R_INJECTSBITERR,
    input                               AXI_R_INJECTDBITERR,
    input  [C_WR_PNTR_WIDTH_RDCH-1:0]   AXI_R_PROG_FULL_THRESH,
    input  [C_WR_PNTR_WIDTH_RDCH-1:0]   AXI_R_PROG_EMPTY_THRESH,
    output [C_WR_PNTR_WIDTH_RDCH:0]     AXI_R_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_RDCH:0]     AXI_R_WR_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_RDCH:0]     AXI_R_RD_DATA_COUNT,
    output                              AXI_R_SBITERR,
    output                              AXI_R_DBITERR,
    output                              AXI_R_OVERFLOW,
    output                              AXI_R_UNDERFLOW,
    
    // AXI Streaming FIFO Related Signals
    input                               AXIS_INJECTSBITERR,
    input                               AXIS_INJECTDBITERR,
    input  [C_WR_PNTR_WIDTH_AXIS-1:0]   AXIS_PROG_FULL_THRESH,
    input  [C_WR_PNTR_WIDTH_AXIS-1:0]   AXIS_PROG_EMPTY_THRESH,
    output [C_WR_PNTR_WIDTH_AXIS:0]     AXIS_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_AXIS:0]     AXIS_WR_DATA_COUNT,
    output [C_WR_PNTR_WIDTH_AXIS:0]     AXIS_RD_DATA_COUNT,
    output                              AXIS_SBITERR,
    output                              AXIS_DBITERR,
    output                              AXIS_OVERFLOW,
    output                              AXIS_UNDERFLOW
);
// synthesis attribute GENERATOR_DEFAULT of fifo_generator_v9_2 is "generatecore com.xilinx.ip.fifo_generator_v9_2.fifo_generator_v9_2" 

endmodule
