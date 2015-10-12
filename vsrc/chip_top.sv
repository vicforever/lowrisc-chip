// See LICENSE for license details.

`include "config.vh"
`include "consts.DefaultConfig.vh"

module chip_top
  (
`ifdef FPGA
   // DDRAM3
   inout [63:0]  ddr3_dq,
   inout [7:0]   ddr3_dqs_n,
   inout [7:0]   ddr3_dqs_p,
   output [13:0] ddr3_addr,
   output [2:0]  ddr3_ba,
   output        ddr3_ras_n,
   output        ddr3_cas_n,
   output        ddr3_we_n,
   output        ddr3_reset_n,
   output        ddr3_ck_p,
   output        ddr3_ck_n,
   output        ddr3_cke,
   output        ddr3_cs_n,
   output [7:0]  ddr3_dm,
   output        ddr3_odt,
   
   // UART
   input         rxd,
   output        txd,

   // SPI for SD-card
   inout         spi_cs,
   inout         spi_sclk,
   inout         spi_mosi,
   inout         spi_miso,
`endif

   // clock and reset
   input         clk_p,
   input         clk_n,
   input         rst_top
   );

   // internal clock and reset signals
   logic  clk, rst, rstn;

   // the NASTI bus for cached memory
   nasti_channel mem_nasti();

   defparam mem_nasti.ID_WIDTH = `MEM_TAG_WIDTH + 1;
   defparam mem_nasti.ADDR_WIDTH = `PADDR_WIDTH;
   defparam mem_nasti.DATA_WIDTH = `MEM_DAT_WIDTH;
   assign mem_nasti.aw_id[0][`MEM_TAG_WIDTH] = 1'b0; // differentiate Memory from IO
   assign mem_nasti.ar_id[0][`MEM_TAG_WIDTH] = 1'b0;
   
   // the NASTI-Lite bus for IO space
   nasti_channel io_nasti();
   defparam io_nasti.ID_WIDTH = `MEM_TAG_WIDTH + 1;
   defparam io_nasti.ADDR_WIDTH = `PADDR_WIDTH;
   defparam io_nasti.DATA_WIDTH = `IO_DAT_WIDTH;
   assign io_nasti.aw_id[0][`MEM_TAG_WIDTH] = 1'b1;
   assign io_nasti.ar_id[0][`MEM_TAG_WIDTH] = 1'b1;

   // host interface
   logic  host_req_valid, host_req_ready, host_resp_valid, host_resp_ready;
   logic [$clog2(`NTILES)-1:0] host_req_id, host_resp_id;
   logic [63:0]                host_req_data, host_resp_data;
   
   // the Rocket chip
   Top Rocket
     (
      .clk                           ( clk                                    ),
      .reset                         ( rst                                    ),
      .io_nasti_aw_valid             ( mem_nasti.aw_valid                     ),
      .io_nasti_aw_ready             ( mem_nasti.aw_ready                     ),
      .io_nasti_aw_bits_id           ( mem_nasti.aw_id[0][`MEM_TAG_WIDTH-1:0] ),
      .io_nasti_aw_bits_addr         ( mem_nasti.aw_addr                      ),
      .io_nasti_aw_bits_len          ( mem_nasti.aw_len                       ),
      .io_nasti_aw_bits_size         ( mem_nasti.aw_size                      ),
      .io_nasti_aw_bits_burst        ( mem_nasti.aw_burst                     ),
      .io_nasti_aw_bits_lock         ( mem_nasti.aw_lock                      ),
      .io_nasti_aw_bits_cache        ( mem_nasti.aw_cache                     ),
      .io_nasti_aw_bits_prot         ( mem_nasti.aw_prot                      ),
      .io_nasti_aw_bits_qos          ( mem_nasti.aw_qos                       ),
      .io_nasti_aw_bits_region       ( mem_nasti.aw_region                    ),
      .io_nasti_aw_bits_user         ( mem_nasti.aw_user                      ),
      .io_nasti_w_valid              ( mem_nasti.w_valid                      ),
      .io_nasti_w_ready              ( mem_nasti.w_ready                      ),
      .io_nasti_w_bits_data          ( mem_nasti.w_data                       ),
      .io_nasti_w_bits_strb          ( mem_nasti.w_strb                       ),
      .io_nasti_w_bits_last          ( mem_nasti.w_last                       ),
      .io_nasti_w_bits_user          ( mem_nasti.w_user                       ),
      .io_nasti_b_valid              ( mem_nasti.b_valid                      ),
      .io_nasti_b_ready              ( mem_nasti.b_ready                      ),
      .io_nasti_b_bits_id            ( mem_nasti.b_id[0][`MEM_TAG_WIDTH-1:0]  ),
      .io_nasti_b_bits_resp          ( mem_nasti.b_resp                       ),
      .io_nasti_b_bits_user          ( mem_nasti.b_user                       ),
      .io_nasti_ar_valid             ( mem_nasti.ar_valid                     ),
      .io_nasti_ar_ready             ( mem_nasti.ar_ready                     ),
      .io_nasti_ar_bits_id           ( mem_nasti.ar_id[0][`MEM_TAG_WIDTH-1:0] ),
      .io_nasti_ar_bits_addr         ( mem_nasti.ar_addr                      ),
      .io_nasti_ar_bits_len          ( mem_nasti.ar_len                       ),
      .io_nasti_ar_bits_size         ( mem_nasti.ar_size                      ),
      .io_nasti_ar_bits_burst        ( mem_nasti.ar_burst                     ),
      .io_nasti_ar_bits_lock         ( mem_nasti.ar_lock                      ),
      .io_nasti_ar_bits_cache        ( mem_nasti.ar_cache                     ),
      .io_nasti_ar_bits_prot         ( mem_nasti.ar_prot                      ),
      .io_nasti_ar_bits_qos          ( mem_nasti.ar_qos                       ),
      .io_nasti_ar_bits_region       ( mem_nasti.ar_region                    ),
      .io_nasti_ar_bits_user         ( mem_nasti.ar_user                      ),
      .io_nasti_r_valid              ( mem_nasti.r_valid                      ),
      .io_nasti_r_ready              ( mem_nasti.r_ready                      ),
      .io_nasti_r_bits_id            ( mem_nasti.r_id[0][`MEM_TAG_WIDTH-1:0]  ),
      .io_nasti_r_bits_data          ( mem_nasti.r_data                       ),
      .io_nasti_r_bits_resp          ( mem_nasti.r_resp                       ),
      .io_nasti_r_bits_last          ( mem_nasti.r_last                       ),
      .io_nasti_r_bits_user          ( mem_nasti.r_user                       ),
      .io_nasti_lite_aw_valid        ( io_nasti.aw_valid                      ),
      .io_nasti_lite_aw_ready        ( io_nasti.aw_ready                      ),
      .io_nasti_lite_aw_bits_id      ( io_nasti.aw_id[0][`MEM_TAG_WIDTH-1:0]  ),
      .io_nasti_lite_aw_bits_addr    ( io_nasti.aw_addr                       ),
      .io_nasti_lite_aw_bits_prot    ( io_nasti.aw_prot                       ),
      .io_nasti_lite_aw_bits_qos     ( io_nasti.aw_qos                        ),
      .io_nasti_lite_aw_bits_region  ( io_nasti.aw_region                     ),
      .io_nasti_lite_aw_bits_user    ( io_nasti.aw_user                       ),
      .io_nasti_lite_w_valid         ( io_nasti.w_valid                       ),
      .io_nasti_lite_w_ready         ( io_nasti.w_ready                       ),
      .io_nasti_lite_w_bits_data     ( io_nasti.w_data                        ),
      .io_nasti_lite_w_bits_strb     ( io_nasti.w_strb                        ),
      .io_nasti_lite_w_bits_user     ( io_nasti.w_user                        ),
      .io_nasti_lite_b_valid         ( io_nasti.b_valid                       ),
      .io_nasti_lite_b_ready         ( io_nasti.b_ready                       ),
      .io_nasti_lite_b_bits_id       ( io_nasti.b_id[0][`MEM_TAG_WIDTH-1:0]   ),
      .io_nasti_lite_b_bits_resp     ( io_nasti.b_resp                        ),
      .io_nasti_lite_b_bits_user     ( io_nasti.b_user                        ),
      .io_nasti_lite_ar_valid        ( io_nasti.ar_valid                      ),
      .io_nasti_lite_ar_ready        ( io_nasti.ar_ready                      ),
      .io_nasti_lite_ar_bits_id      ( io_nasti.ar_id[0][`MEM_TAG_WIDTH-1:0]  ),
      .io_nasti_lite_ar_bits_addr    ( io_nasti.ar_addr                       ),
      .io_nasti_lite_ar_bits_prot    ( io_nasti.ar_prot                       ),
      .io_nasti_lite_ar_bits_qos     ( io_nasti.ar_qos                        ),
      .io_nasti_lite_ar_bits_region  ( io_nasti.ar_region                     ),
      .io_nasti_lite_ar_bits_user    ( io_nasti.ar_user                       ),
      .io_nasti_lite_r_valid         ( io_nasti.r_valid                       ),
      .io_nasti_lite_r_ready         ( io_nasti.r_ready                       ),
      .io_nasti_lite_r_bits_id       ( io_nasti.r_id[0][`MEM_TAG_WIDTH-1:0]   ),
      .io_nasti_lite_r_bits_data     ( io_nasti.r_data                        ),
      .io_nasti_lite_r_bits_resp     ( io_nasti.r_resp                        ),
      .io_nasti_lite_r_bits_user     ( io_nasti.r_user                        ),
      .io_host_req_ready             ( host_req_ready                         ),
      .io_host_req_valid             ( host_req_valid                         ),
      .io_host_req_bits_id           ( host_req_id                            ),
      .io_host_req_bits_data         ( host_req_data                          ),
      .io_host_resp_ready            ( host_resp_ready                        ),
      .io_host_resp_valid            ( host_resp_valid                        ),
      .io_host_resp_bits_id          ( host_resp_id                           ),
      .io_host_resp_bits_data        ( host_resp_data                         )
      );

   // the memory contoller
`ifdef FPGA

   // host interface is not used
   assign host_req_ready = 1'b0;
   assign host_resp_id = 0;
   assign host_resp_data = 0;
   assign host_resp_valid = 1'b0;
   
   // combined bram/dram channel
   nasti_channel combined_mem_nasti();
   defparam combined_mem_nasti.N_PORT = 2;
   defparam combined_mem_nasti.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam combined_mem_nasti.ADDR_WIDTH = `PADDR_WIDTH;
   defparam combined_mem_nasti.DATA_WIDTH = `MEM_DAT_WIDTH;

   // the NASTI crossbar for BRAM and DRAM controllers
   nasti_crossbar
     #(
       .ADDR_WIDTH   ( `PADDR_WIDTH   ),
       .DATA_WIDTH   ( `MEM_DAT_WIDTH ),
       .ID_WIDTH     ( `MEM_TAG_WIDTH )
       )
   nasti_cb_mem
     (
      .*,
      .s   ( mem_nasti          ),
      .m   ( combined_mem_nasti )
      );

   localparam MEM_DATA_WIDTH = 128;
   localparam BRAM_ADDR_WIDTH = 16;     // 64 KB
   localparam BRAM_LINE = 2 ** BRAM_ADDR_WIDTH  * 8 / MEM_DATA_WIDTH;
   localparam BRAM_LINE_OFFSET = $clog2(MEM_DATA_WIDTH/8);
   localparam DRAM_ADDR_WIDTH = 30;     // 1 GB

   // the NASTI bus for on-FPGA block memory
   nasti_channel bram_nasti();

   defparam bram_nasti.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam bram_nasti.ADDR_WIDTH = BRAM_ADDR_WIDTH;
   defparam bram_nasti.DATA_WIDTH = `MEM_DAT_WIDTH;


   // the NASTI bus for off-FPGA DRAM
   nasti_channel dram_nasti();

   defparam dram_nasti.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam dram_nasti.ADDR_WIDTH = DRAM_ADDR_WIDTH;
   defparam dram_nasti.DATA_WIDTH = `MEM_DAT_WIDTH;

   nasti_channel_slicer #(2)
   mem_slicer (
               .s   ( combined_mem_nasti  ),
               .m0  ( bram_nasti          ),
               .m1  ( dram_nasti          )
               );
   
   // BRAM controller
   logic ram_clk, ram_rst, ram_en;
   logic [MEM_DATA_WIDTH/8-1:0] ram_we;
   logic [BRAM_ADDR_WIDTH-1:0] ram_addr;
   logic [MEM_DATA_WIDTH-1:0] ram_wrdata, ram_rddata;

   axi_bram_ctrl_top #(.ADDR_WIDTH(BRAM_ADDR_WIDTH), .DATA_WIDTH(MEM_DATA_WIDTH)) 
   BramCtl
     (
      .clk          ( clk         ),
      .rstn         ( rstn        ),
      .nasti        ( bram_nasti  ),
      .ram_rst      ( ram_rst     ),
      .ram_clk      ( ram_clk     ),
      .ram_en       ( ram_en      ),
      .ram_addr     ( ram_addr    ),
      .ram_wrdata   ( ram_wrdata  ),
      .ram_we       ( ram_we      ),
      .ram_rddata   ( ram_rddata  )
      );

   // the inferred BRAMs
   reg [MEM_DATA_WIDTH-1:0] ram [0 : BRAM_LINE-1];
   reg [BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET] ram_addr_dly;
   
   always_ff @(posedge ram_clk)
     if(ram_en) begin
        ram_addr_dly <= ram_addr[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET];
        foreach (ram_we[i])
          if(ram_we[i]) ram[ram_addr[BRAM_ADDR_WIDTH-1:BRAM_LINE_OFFSET]][i*8 +:8] <= ram_wrdata[i*8 +: 8];
     end

   assign ram_rddata = ram[ram_addr_dly];

   initial $readmemh("boot.mem", ram);

   // the NASTI bus for off-FPGA DRAM, converted to High frequency
   nasti_channel mig_nasti();

   defparam mig_nasti.ID_WIDTH = `MEM_TAG_WIDTH;
   defparam mig_nasti.ADDR_WIDTH = DRAM_ADDR_WIDTH;
   defparam mig_nasti.DATA_WIDTH = `MEM_DAT_WIDTH;

   // MIG clock
   logic mig_clk, mig_rst, mig_rstn;
   always_ff @(posedge mig_clk)
     mig_rstn <= !mig_rst;

   // clock converter
   axi_clock_converter_0 clk_conv
     (
      .s_axi_aclk           ( clk                   ),
      .s_axi_aresetn        ( rstn                  ),
      .s_axi_awid           ( dram_nasti.aw_id      ),
      .s_axi_awaddr         ( dram_nasti.aw_addr    ),
      .s_axi_awlen          ( dram_nasti.aw_len     ),
      .s_axi_awsize         ( dram_nasti.aw_size    ),
      .s_axi_awburst        ( dram_nasti.aw_burst   ),
      .s_axi_awlock         ( 1'b0                  ), // not supported in AXI4
      .s_axi_awcache        ( dram_nasti.aw_cache   ),
      .s_axi_awprot         ( dram_nasti.aw_prot    ),
      .s_axi_awqos          ( dram_nasti.aw_qos     ),
      .s_axi_awregion       ( dram_nasti.aw_region  ),
      .s_axi_awvalid        ( dram_nasti.aw_valid   ),
      .s_axi_awready        ( dram_nasti.aw_ready   ),
      .s_axi_wdata          ( dram_nasti.w_data     ),
      .s_axi_wstrb          ( dram_nasti.w_strb     ),
      .s_axi_wlast          ( dram_nasti.w_last     ),
      .s_axi_wvalid         ( dram_nasti.w_valid    ),
      .s_axi_wready         ( dram_nasti.w_ready    ),
      .s_axi_bid            ( dram_nasti.b_id       ),
      .s_axi_bresp          ( dram_nasti.b_resp     ),
      .s_axi_bvalid         ( dram_nasti.b_valid    ),
      .s_axi_bready         ( dram_nasti.b_ready    ),
      .s_axi_arid           ( dram_nasti.ar_id      ),
      .s_axi_araddr         ( dram_nasti.ar_addr    ),
      .s_axi_arlen          ( dram_nasti.ar_len     ),
      .s_axi_arsize         ( dram_nasti.ar_size    ),
      .s_axi_arburst        ( dram_nasti.ar_burst   ),
      .s_axi_arlock         ( 1'b0                  ), // not supported in AXI4
      .s_axi_arcache        ( dram_nasti.ar_cache   ),
      .s_axi_arprot         ( dram_nasti.ar_prot    ),
      .s_axi_arqos          ( dram_nasti.ar_qos     ),
      .s_axi_arregion       ( dram_nasti.ar_region  ),
      .s_axi_arvalid        ( dram_nasti.ar_valid   ),
      .s_axi_arready        ( dram_nasti.ar_ready   ),
      .s_axi_rid            ( dram_nasti.r_id       ),
      .s_axi_rdata          ( dram_nasti.r_data     ),
      .s_axi_rresp          ( dram_nasti.r_resp     ),
      .s_axi_rlast          ( dram_nasti.r_last     ),
      .s_axi_rvalid         ( dram_nasti.r_valid    ),
      .s_axi_rready         ( dram_nasti.r_ready    ),
      .m_axi_aclk           ( mig_clk               ),
      .m_axi_aresetn        ( mig_rstn              ),
      .m_axi_awid           ( mig_nasti.aw_id       ),
      .m_axi_awaddr         ( mig_nasti.aw_addr     ),
      .m_axi_awlen          ( mig_nasti.aw_len      ),
      .m_axi_awsize         ( mig_nasti.aw_size     ),
      .m_axi_awburst        ( mig_nasti.aw_burst    ),
      .m_axi_awlock         (                       ), // not supported in AXI4
      .m_axi_awcache        ( mig_nasti.aw_cache    ),
      .m_axi_awprot         ( mig_nasti.aw_prot     ),
      .m_axi_awqos          ( mig_nasti.aw_qos      ),
      .m_axi_awregion       ( mig_nasti.aw_region   ),
      .m_axi_awvalid        ( mig_nasti.aw_valid    ),
      .m_axi_awready        ( mig_nasti.aw_ready    ),
      .m_axi_wdata          ( mig_nasti.w_data      ),
      .m_axi_wstrb          ( mig_nasti.w_strb      ),
      .m_axi_wlast          ( mig_nasti.w_last      ),
      .m_axi_wvalid         ( mig_nasti.w_valid     ),
      .m_axi_wready         ( mig_nasti.w_ready     ),
      .m_axi_bid            ( mig_nasti.b_id        ),
      .m_axi_bresp          ( mig_nasti.b_resp      ),
      .m_axi_bvalid         ( mig_nasti.b_valid     ),
      .m_axi_bready         ( mig_nasti.b_ready     ),
      .m_axi_arid           ( mig_nasti.ar_id       ),
      .m_axi_araddr         ( mig_nasti.ar_addr     ),
      .m_axi_arlen          ( mig_nasti.ar_len      ),
      .m_axi_arsize         ( mig_nasti.ar_size     ),
      .m_axi_arburst        ( mig_nasti.ar_burst    ),
      .m_axi_arlock         (                       ), // not supported in AXI4
      .m_axi_arcache        ( mig_nasti.ar_cache    ),
      .m_axi_arprot         ( mig_nasti.ar_prot     ),
      .m_axi_arqos          ( mig_nasti.ar_qos      ),
      .m_axi_arregion       ( mig_nasti.ar_region   ),
      .m_axi_arvalid        ( mig_nasti.ar_valid    ),
      .m_axi_arready        ( mig_nasti.ar_ready    ),
      .m_axi_rid            ( mig_nasti.r_id        ),
      .m_axi_rdata          ( mig_nasti.r_data      ),
      .m_axi_rresp          ( mig_nasti.r_resp      ),
      .m_axi_rlast          ( mig_nasti.r_last      ),
      .m_axi_rvalid         ( mig_nasti.r_valid     ),
      .m_axi_rready         ( mig_nasti.r_ready     )
      );

   // DRAM controller
   mig_7series_0 dram_ctl
     (
      .sys_clk_p            ( clk_p                 ),
      .sys_clk_n            ( clk_n                 ),
      .sys_rst              ( rst_top               ),
      .ddr3_dq              ( ddr3_dq               ),
      .ddr3_dqs_n           ( ddr3_dqs_n            ),
      .ddr3_dqs_p           ( ddr3_dqs_p            ),
      .ddr3_addr            ( ddr3_addr             ),
      .ddr3_ba              ( ddr3_ba               ),
      .ddr3_ras_n           ( ddr3_ras_n            ),
      .ddr3_cas_n           ( ddr3_cas_n            ),
      .ddr3_we_n            ( ddr3_we_n             ),
      .ddr3_reset_n         ( ddr3_reset_n          ),
      .ddr3_ck_p            ( ddr3_ck_p             ),
      .ddr3_ck_n            ( ddr3_ck_n             ),
      .ddr3_cke             ( ddr3_cke              ),
      .ddr3_cs_n            ( ddr3_cs_n             ),
      .ddr3_dm              ( ddr3_dm               ),
      .ddr3_odt             ( ddr3_odt              ),
      .ui_clk               ( mig_clk               ),
      .ui_clk_sync_rst      ( mig_rst               ),
      .ui_addn_clk_0        ( clk                   ),
      .mmcm_locked          ( rstn                  ),
      .aresetn              ( rstn                  ), // AXI reset
      .app_sr_req           ( 1'b0                  ),
      .app_ref_req          ( 1'b0                  ),
      .app_zq_req           ( 1'b0                  ),
      .s_axi_awid           ( mig_nasti.aw_id       ),
      .s_axi_awaddr         ( mig_nasti.aw_addr     ),
      .s_axi_awlen          ( mig_nasti.aw_len      ),
      .s_axi_awsize         ( mig_nasti.aw_size     ),
      .s_axi_awburst        ( mig_nasti.aw_burst    ),
      .s_axi_awlock         ( 1'b0                  ), // not supported in AXI4
      .s_axi_awcache        ( mig_nasti.aw_cache    ),
      .s_axi_awprot         ( mig_nasti.aw_prot     ),
      .s_axi_awqos          ( mig_nasti.aw_qos      ),
      .s_axi_awvalid        ( mig_nasti.aw_valid    ),
      .s_axi_awready        ( mig_nasti.aw_ready    ),
      .s_axi_wdata          ( mig_nasti.w_data      ),
      .s_axi_wstrb          ( mig_nasti.w_strb      ),
      .s_axi_wlast          ( mig_nasti.w_last      ),
      .s_axi_wvalid         ( mig_nasti.w_valid     ),
      .s_axi_wready         ( mig_nasti.w_ready     ),
      .s_axi_bid            ( mig_nasti.b_id        ),
      .s_axi_bresp          ( mig_nasti.b_resp      ),
      .s_axi_bvalid         ( mig_nasti.b_valid     ),
      .s_axi_bready         ( mig_nasti.b_ready     ),
      .s_axi_arid           ( mig_nasti.ar_id       ),
      .s_axi_araddr         ( mig_nasti.ar_addr     ),
      .s_axi_arlen          ( mig_nasti.ar_len      ),
      .s_axi_arsize         ( mig_nasti.ar_size     ),
      .s_axi_arburst        ( mig_nasti.ar_burst    ),
      .s_axi_arlock         ( 1'b0                  ), // not supported in AXI4
      .s_axi_arcache        ( mig_nasti.ar_cache    ),
      .s_axi_arprot         ( mig_nasti.ar_prot     ),
      .s_axi_arqos          ( mig_nasti.ar_qos      ),
      .s_axi_arvalid        ( mig_nasti.ar_valid    ),
      .s_axi_arready        ( mig_nasti.ar_ready    ),
      .s_axi_rid            ( mig_nasti.r_id        ),
      .s_axi_rdata          ( mig_nasti.r_data      ),
      .s_axi_rresp          ( mig_nasti.r_resp      ),
      .s_axi_rlast          ( mig_nasti.r_last      ),
      .s_axi_rvalid         ( mig_nasti.r_valid     ),
      .s_axi_rready         ( mig_nasti.r_ready     )
      );

   assign rst = !rstn;

   // combined IO nasti channels
   nasti_channel combined_io_nasti();

   defparam combined_io_nasti.N_PORT = 2;
   defparam combined_io_nasti.ADDR_WIDTH = IO_ADDR_WIDTH;
   defparam combined_io_nasti.DATA_WIDTH = `IO_DAT_WIDTH;

    // the NASTI-Lite bus for UART
   nasti_channel uart_nasti();

   defparam uart_nasti.ADDR_WIDTH = IO_ADDR_WIDTH;
   defparam uart_nasti.DATA_WIDTH = `IO_DAT_WIDTH;

   // the NASTI-Lite bus for SPI (SD-card)
   nasti_channel spi_nasti();

   defparam spi_nasti.ADDR_WIDTH = IO_ADDR_WIDTH;
   defparam spi_nasti.DATA_WIDTH = `IO_DAT_WIDTH;
   
   // the NASTI crossbar for IO peripherals
   nasti_crossbar
     #(
       .ADDR_WIDTH   ( IO_ADDR_WIDTH  ),
       .DATA_WIDTH   ( `IO_DAT_WIDTH  )
       )
   nasti_cb_io
     (
      .*,
      .s    ( io_nasti          ),
      .m    ( combined_io_nasti )
      );

   nasti_channel_slicer #(2)
   io_slicer (
              .s   ( combined_io_nasti  ),
              .m0  ( uart_nasti         ),
              .m1  ( spi_nasti          )
             );

   // Xilinx UART IP
   axi_uart16550_0 uart_i
     (
      .s_axi_aclk      ( clk                 ),
      .s_axi_aresetn   ( rstn                ),
      .s_axi_araddr    ( uart_nasti.ar_addr  ),
      .s_axi_arready   ( uart_nasti.ar_ready ),
      .s_axi_arvalid   ( uart_nasti.ar_valid ),
      .s_axi_awaddr    ( uart_nasti.aw_addr  ),
      .s_axi_awready   ( uart_nasti.aw_ready ),
      .s_axi_awvalid   ( uart_nasti.aw_valid ),
      .s_axi_bready    ( uart_nasti.b_ready  ),
      .s_axi_bresp     ( uart_nasti.b_resp   ),
      .s_axi_bvalid    ( uart_nasti.b_valid  ),
      .s_axi_rdata     ( uart_nasti.r_data   ),
      .s_axi_rready    ( uart_nasti.r_ready  ),
      .s_axi_rresp     ( uart_nasti.r_resp   ),
      .s_axi_rvalid    ( uart_nasti.r_valid  ),
      .s_axi_wdata     ( uart_nasti.w_data   ),
      .s_axi_wready    ( uart_nasti.w_ready  ),
      .s_axi_wstrb     ( uart_nasti.w_strb   ),
      .s_axi_wvalid    ( uart_nasti.w_valid  ),
      .freeze          ( 1'b0                ),
      .rin             ( 1'b1                ),
      .dcdn            ( 1'b1                ),
      .dsrn            ( 1'b1                ),
      .sin             ( rxd                 ),
      .sout            ( txd                 ),
      .ctsn            ( 1'b1                ),
      .rtsn            (                     )
      );

   // Xilinx SPI IP
   wire  spi_cs_i, spi_cs_o, spi_cs_t;
   wire  spi_sclk_i, spi_sclk_o, spi_sclk_t;
   wire  spi_miso_i, spi_miso_o, spi_miso_t;
   wire  spi_mosi_i, spi_mosi_o, spi_mosi_t;
   
   axi_quad_spi_0 spi_i
     (
      .ext_spi_clk     ( clk                ),
      .s_axi_aclk      ( clk                ),
      .s_axi_aresetn   ( rstn               ),
      .s_axi_araddr    ( spi_nasti.ar_addr  ),
      .s_axi_arready   ( spi_nasti.ar_ready ),
      .s_axi_arvalid   ( spi_nasti.ar_valid ),
      .s_axi_awaddr    ( spi_nasti.aw_addr  ),
      .s_axi_awready   ( spi_nasti.aw_ready ),
      .s_axi_awvalid   ( spi_nasti.aw_valid ),
      .s_axi_bready    ( spi_nasti.b_ready  ),
      .s_axi_bresp     ( spi_nasti.b_resp   ),
      .s_axi_bvalid    ( spi_nasti.b_valid  ),
      .s_axi_rdata     ( spi_nasti.r_data   ),
      .s_axi_rready    ( spi_nasti.r_ready  ),
      .s_axi_rresp     ( spi_nasti.r_resp   ),
      .s_axi_rvalid    ( spi_nasti.r_valid  ),
      .s_axi_wdata     ( spi_nasti.w_data   ),
      .s_axi_wready    ( spi_nasti.w_ready  ),
      .s_axi_wstrb     ( spi_nasti.w_strb   ),
      .s_axi_wvalid    ( spi_nasti.w_valid  ),
      .io0_i           ( spi_mosi_i         ),
      .io0_o           ( spi_mosi_o         ),
      .io0_t           ( spi_mosi_t         ),
      .io1_i           ( spi_miso_i         ),
      .io1_o           ( spi_miso_o         ),
      .io1_t           ( spi_miso_t         ),
      .sck_i           ( spi_sclk_i         ),
      .sck_o           ( spi_sclk_o         ),
      .sck_t           ( spi_sclk_t         ),
      .ss_i            ( spi_cs_i           ),
      .ss_o            ( spi_cs_o           ),
      .ss_t            ( spi_cs_t           ),
      .ip2intc_irpt    (                    )  // polling for now
      );

   // tri-state gate to protect SPI IOs
   assign spi_mosi = !spi_mosi_t ? spi_mosi_o : 1'bz;
   assign spi_mosi_i = 1'b1;    // always in master mode

   assign spi_miso = !spi_miso_t ? spi_miso_o : 1'bz;
   assign spi_miso_i = spi_miso;

   assign spi_sclk = !spi_sclk_t ? spi_sclk_o : 1'bz;
   assign spi_sclk_i = 1'b1;    // always in master mode

   assign spi_cs = !spi_cs_t ? spi_cs_o : 1'bz;
   assign spi_cs_i = 1'b1;;     // always in master mode

`elsif SIMULATION

   assign clk = clk_p;
   assign rst = rst_top;
   assign rstn = !rst_top;

   // converted nasti channel for io_nasti
   nasti_channel io_nasti_full();
   defparam io_nasti_full.ID_WIDTH = `MEM_TAG_WIDTH + 1;
   defparam io_nasti_full.ADDR_WIDTH = `PADDR_WIDTH;
   defparam io_nasti_full.DATA_WIDTH = `MEM_DAT_WIDTH;

   // nasti channel to behavioural ram
   nasti_channel ram_nasti();
   defparam ram_nasti.ID_WIDTH = `MEM_TAG_WIDTH + 1;
   defparam ram_nasti.ADDR_WIDTH = `PADDR_WIDTH;
   defparam ram_nasti.DATA_WIDTH = `MEM_DAT_WIDTH;

   // combined mem and IO nasti
   nasti_channel mem_io_nasti();
   defparam mem_io_nasti.N_PORT = 2;
   defparam mem_io_nasti.ID_WIDTH = `MEM_TAG_WIDTH + 1;
   defparam mem_io_nasti.ADDR_WIDTH = `PADDR_WIDTH;
   defparam mem_io_nasti.DATA_WIDTH = `MEM_DAT_WIDTH;

   // convert nasti-lite io_nasti to full nasti io_nasti_full
   lite_nasti_bridge
     #(
       .ID_WIDTH          ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH        ( `PADDR_WIDTH       ),
       .NASTI_DATA_WIDTH  ( `MEM_DAT_WIDTH     ),
       .LITE_DATA_WIDTH   ( `IO_DAT_WIDTH      )
       )
   io_nasti_conv
     (
      .*,
      .lite_s  ( io_nasti      ),
      .nasti_m ( io_nasti_full )
      );

   // crossbar to merge memory and IO to the behaviour dram
   nasti_crossbar
     #(
       .N_INPUT    ( 2                  ),
       .N_OUTPUT   ( 1                  ),
       .IB_DEPTH   ( 3                  ),
       .OB_DEPTH   ( 3                  ),
       .W_MAX      ( 4                  ),
       .R_MAX      ( 4                  ),
       .ID_WIDTH   ( `MEM_TAG_WIDTH + 1 ),
       .ADDR_WIDTH ( `PADDR_WIDTH       ),
       .DATA_WIDTH ( `MEM_DAT_WIDTH     ),
       .BASE0      ( 0                  ),
       .BASE1      ( 32'hffffffff       )
       )
   mem_crossbar
     (
      .*,
      .s ( mem_io_nasti  ),
      .m ( ram_nasti     )
      );

   host_behav #(.nCores(`NTILES))
   host
     (
      .*,
      .req_valid    ( host_req_valid   ),
      .req_ready    ( host_req_ready   ),
      .req_id       ( host_req_id      ),
      .req          ( host_req_data    ),
      .resp_valid   ( host_resp_valid  ),
      .resp_ready   ( host_resp_ready  ),
      .resp_id      ( host_resp_id     ),
      .resp         ( host_resp_data   )
      );

   nasti_ram_behav
     #(
       .ID_WIDTH     ( `MEM_TAG_WIDTH+1 ),
       .ADDR_WIDTH   ( `PADDR_WIDTH     ),
       .DATA_WIDTH   ( `MEM_DAT_WIDTH   ),
       .USER_WIDTH   ( 1                )
       )
   ram_behav
     (
      .clk           ( clk              ),
      .rstn          ( rstn             ),
      .nasti         ( ram_nasti        )
      );

`endif

endmodule // chip_top
