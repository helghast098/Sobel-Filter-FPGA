// Project F Library - 640x480p60 Display
// (C)2022 Will Green, open source hardware released under the MIT License
// Learn more at https://projectf.io
//
// Changed the format of the code to make it easier to read and also comply to our style used in class
module display_480p #(
	  parameter CORDW_p = 16
   ,parameter H_RES_ACTIVE_AREA_p = 640   // horizontal resolution (pixels)
   ,parameter V_RES_ACTIVE_AREA_p = 480   // vertical resolution (lines)
   ,parameter H_FRONT_PORCH_p = 16    // horizontal front porch
   ,parameter H_SYNC_p = 96   // horizontal sync
   ,parameter H_BACK_PORCH_p = 48     // horizontal back porch
   ,parameter V_FRONT_PORCH_p = 10     // vertical front porch
   ,parameter V_SYNC_p = 2    // vertical sync
   ,parameter V_BACK_PORCH_p = 33     // vertical back porch
   ,parameter H_POLARITY_p = 0     // horizontal sync polarity (0:neg, 1:pos)
   ,parameter V_POLARITY_p = 0      // vertical sync polarity (0:neg, 1:pos)
    ) (
    input  wire logic clk_pix_i,  // pixel clock
    input  wire logic rst_pix_i,  // reset in pixel clock domain
    output      logic hsync_o,    // horizontal sync
    output      logic vsync_o,    // vertical sync
    output      logic de_o,       // data enable (low in blanking interval)
    output      logic frame_o,    // high at start of frame
    output      logic line_o,     // high at start of line
    output      logic signed [CORDW_p-1:0] sx_o,  // horizontal screen position
    output      logic signed [CORDW_p-1:0] sy_o   // vertical screen position
    );

    // horizontal timings
  localparam signed H_STA_lp  = 0 - H_FRONT_PORCH_p - H_SYNC_p - H_BACK_PORCH_p; // horizontal start no active area
  localparam signed HS_STA_lp = H_STA_lp + H_FRONT_PORCH_p;  // Horizontal sync start
  localparam signed HS_END_lp = HS_STA_lp + H_SYNC_p;          // Horizontal sync end
  localparam signed HA_STA_lp = 0;                           // active start
  localparam signed HA_END_lp = H_RES_ACTIVE_AREA_p - 1;                   // active end

	 // vertical timings
	localparam signed V_STA_lp  = 0 - V_FRONT_PORCH_p - V_SYNC_p - V_BACK_PORCH_p;    // vertical start
	localparam signed VS_STA_lp = V_STA_lp + V_FRONT_PORCH_p;               // vertical sync start
  localparam signed VS_END_lp = VS_STA_lp + V_SYNC_p;             // vertical sync end
  localparam signed VA_STA_lp = 0;                           // active start
  localparam signed VA_END_lp = V_RES_ACTIVE_AREA_p - 1;                   // active end

    logic signed [CORDW_p-1:0] x_r;  // screen position x
		logic signed [CORDW_p-1:0] y_r;  // screen position y

    // generate horizontal and vertical sync with correct polarity
    always_ff @(posedge clk_pix_i) begin
        hsync_o <= H_POLARITY_p ? (x_r > HS_STA_lp && x_r <= HS_END_lp) : ~(x_r > HS_STA_lp && x_r <= HS_END_lp);
        vsync_o <= V_POLARITY_p ? (y_r > VS_STA_lp && y_r <= VS_END_lp) : ~(y_r > VS_STA_lp && y_r <= VS_END_lp);
        if (rst_pix_i) begin
            hsync_o <= H_POLARITY_p ? 0 : 1;
            vsync_o <= V_POLARITY_p ? 0 : 1;
        end
    end

    // control signals
    always_ff @(posedge clk_pix_i) begin
        de_o    <= (y_r >= VA_STA_lp && x_r >= HA_STA_lp);
        frame_o <= (y_r == V_STA_lp  && x_r == H_STA_lp);
        line_o  <= (x_r == H_STA_lp);
        if (rst_pix_i) begin
            de_o <= 0;
            frame_o <= 0;
            line_o <= 0;
        end
    end

    // calculate horizontal and vertical screen position
    always_ff @(posedge clk_pix_i) begin
        if (x_r == HA_END_lp) begin  // last pixel on line?
            x_r <= H_STA_lp;
            y_r <= (y_r == VA_END_lp) ? V_STA_lp : y_r + 1;  // last line on screen?
        end else begin
            x_r <= x_r + 1;
        end
        if (rst_pix_i) begin
            x_r <= H_STA_lp;
            y_r <= V_STA_lp;
        end
    end

    // delay screen position to match sync and control signals
    always_ff @ (posedge clk_pix_i) begin
        sx_o <= x_r;
        sy_o <= y_r;
        if (rst_pix_i) begin
            sx_o <= H_STA_lp;
            sy_o <= V_STA_lp;
        end
    end
endmodule
