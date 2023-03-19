// Project F Library - 640x480p60 Clock Generation (iCE40)
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io

// Generates 25.125 MHz (640x480 59.8 Hz) with 12 MHz input clock
// iCE40 PLLs are documented in Lattice TN1251 and ICE Technology Library

module clock_display
 	// Initial setup for 640x480
	#(parameter DIVR_p = 4'b0000
	  ,parameter DIF_p = 7'b1000010
	  ,parameter DIVQ_p = 3'b101
	  ,parameter Filter_Range_p = 3'b001
	  ,parameter Feedback_Path_p = "SIMPLE"
	 )
	 (
    input  [0:0] clk_12mhz_i,          // input clock (12 MHz)
    input  [0:0] reset_i,                  // reset
    output [0:0] clk_pix_o,             // pixel clock
    output logic clk_pix_locked_o  // pixel clock locked?
    );

		localparam FEEDBACK_PATH="SIMPLE";
    localparam DIVR=4'b0000;
    localparam DIVF=7'b1000010;
    localparam DIVQ=3'b101;
    localparam FILTER_RANGE=3'b001;

    logic [0:0] locked;
		SB_PLL40_PAD #(
        .FEEDBACK_PATH(FEEDBACK_PATH),
        .DIVR(DIVR),
        .DIVF(DIVF),
        .DIVQ(DIVQ),
        .FILTER_RANGE(FILTER_RANGE)
    )
    SB_PLL40_PAD_inst (
        .PACKAGEPIN(clk_12mhz_i),
        .PLLOUTGLOBAL(clk_pix_o),  // use global clock network
        .RESETB(reset_i),
        .BYPASS(1'b0),
        .LOCK(locked)
    );

    // ensure clock lock is synced with pixel clock

    logic [0:0] locked_sync_r;
    always_ff @(posedge clk_pix_o) begin
        locked_sync_r <= locked;
        clk_pix_locked_o <= locked_sync_r;
    end
endmodule
