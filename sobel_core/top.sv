module top
  (input [0:0] clk_12mhz_i
  // n: Negative Polarity (0 when pressed, 1 otherwise)
  // async: Not synchronized to clock
  // unsafe: Not De-Bounced
  ,input [0:0] reset_n_async_unsafe_i
  // async: Not synchronized to clock
  // unsafe: Not De-Bounced

	// clock for the DVI
  ,output [0:0] dvi_clk_o

	// Horizontal sync
  ,output [0:0] dvi_hsync_o

	// Vertical Sync
	,output [0:0] dvi_vsync_o

  // Data enable
  ,output [0:0] dvi_de_o

  // Color Red output
	,output [3:0] dvi_r_o

	// Color Green output
	,output [3:0] dvi_g_o

	// Color Blue output
	,output [3:0] dvi_b_o
	,output [5:1] led_o);

   // These two D Flip Flops form what is known as a Synchronizer. We
   // will learn about these in Week 5, but you can see more here:
   // https://inst.eecs.berkeley.edu/~cs150/sp12/agenda/lec/lec16-synch.pdf
   wire reset_n_sync_r;
   wire reset_sync_r;
   wire reset_r; // Use this as your reset_signal
   localparam image_width_lp = 160;  // Image width in memory
   localparam image_height_lp = 120; // Image height in memory
   localparam conv_img_width_lp = image_width_lp - 2;
   localparam conv_img_height_lp = immage_height_lp -2;
   
   // Reset btn for everymodule connected with new clock
   dff
     #()
   sync_a
     (.clk_i(clk_pix_i)
     ,.reset_i(1'b0)
     ,.d_i(reset_n_async_unsafe_i)
     ,.q_o(reset_n_sync_r));

   inv
     #()
   inv
     (.a_i(reset_n_sync_r)
     ,.b_o(reset_sync_r));

   dff
     #()
   sync_b
     (.clk_i(clk_pix_i)
     ,.reset_i(1'b0)
     ,.d_i(reset_sync_r)
     ,.q_o(reset_r));
     
    


	// Instantiating Clock
	wire [0:0] clk_pix_i;
	wire [0:0] clk_pix_locked_i;
	clock_display
		#()
	clock_display_inst_640x480
		(.clk_12mhz_i(clk_12mhz_i)
		,.reset_i(reset_n_async_unsafe_i)
		,.clk_pix_o(clk_pix_i)
		,.clk_pix_locked_o(clk_pix_locked_i)
		);


	logic [$clog2(image_width_lp * image_height_lp)-1: 0] rd_address_l; // read address for ram

	wire [3:0] rd_data_o_w; // wire holding rd data from ram

	// ---------------INITIALIZING RAM---------------------------
	// First:  Read Data from Ram: 1 cycle delay
	// Second: Do Sobel Operation, write Data into Ram again
	// THird: Use ram for DVI and scale up
	wire [0:0] valid_mem_o_w; // High when data from ram is valid
	sync_valid_mem
		#(.width_p(4)
		 ,.depth_p(image_width_lp * image_height_lp)
		 ,.filename_p("input_image/gray_image.txt")
		 )
	sync_valid_mem_inst_image
		(.clk_i(clk_pix_i)
		,.reset_i(reset_r)
		,.wr_e_i(valid_sobelC_o_w)
		,.wr_data_i(data_sobelC_o_w)
		,.wr_addr_i(wr_address_sobelC_r)
		,.rd_addr_i(rd_address_l)
		,.rd_data_o(rd_data_o_w)
		,.ready_i(ready_sep_3x3_o_w)
		,.valid_o(valid_mem_o_w)
		);

	// -------------INITIALIZING SEPARATOR-------------------------------
	wire [0:0] valid_sep_3x3_o_w; // valid
	wire [0:0] ready_sep_3x3_o_w;
	wire [$clog2(image_width_lp * image_height_lp)-1:0] rd_address_3x3_o_w; // rd address output for 3x3
	wire [35:0] sep_3x3_data_o_w; // 3x3 data

	separator_3x3
		#(.horiz_width_p(image_width_lp)
		 ,.vertic_width_p(image_height_lp)
		 )
	separator_3x3_inst
		(.clk_i(clk_pix_i)
		 ,.reset_i(reset_r)
		 ,.valid_i(valid_mem_o_w)
		 ,.rd_data_i(rd_data_o_w)
		 ,.rd_address_o(rd_address_3x3_o_w)
		 ,.ready_o(ready_sep_3x3_o_w)
		 ,.ready_i(ready_sobelC_o_w)
		 ,.data_o(sep_3x3_data_o_w)
		 ,.valid_o(valid_sep_3x3_o_w)
		 );


	// --------------------------INITIALIZING SOBEL CORE------------------------------
	wire [0:0] ready_sobelC_o_w;
	wire [0:0] valid_sobelC_o_w;
	wire [3:0] data_sobelC_o_w;

	sobel_core
		#()
	sobel_core_inst
		(.clk_i(clk_pix_i)
		,.reset_i(reset_r)
		,.data_i(sep_3x3_data_o_w)
		,.valid_i(valid_sep_3x3_o_w)
		,.ready_i(1'b1)
		,.valid_o(valid_sobelC_o_w)
		,.ready_o(ready_sobelC_o_w)
		,.data_o(data_sobelC_o_w)
		);


	/*---------------------------- This Block Handles the write address for sobel data and whether it is finished with the image -----------------------*/
	reg [$clog2(image_width_lp * image_height_lp)-1:0] wr_address_sobelC_r; // Where should the soble write into the ram
	reg [0:0] finished_sobel_op_r; // True when sobel core is finished with the image: False otherwise
	
	always_ff @(posedge clk_pix_i) begin
		if (reset_r) begin
			finished_sobel_op_r <= '0;  // Sobel core not finished
			wr_address_sobelC_r <= '0; // Initial write address = 0
			
		end else if (valid_sobelC_o_w) // Only increment read address when Sobel Core produces valid data
			wr_address_sobelC_r <= wr_address_sobelC_r + 1;
			
		else begin
			if (wr_address_sobelC_r == ((image_width_lp-2) * (image_height_lp-2))) // If Sobel prdouces last data from image
				finished_sobel_op_r <= 1;
			else
				finished_sobel_op_r <= 0;
		end
	end

	assign led_o = {5{finished_sobel_op_r}};
	/*-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
	
	/*---------------------This Is Where The Display Read Address For Ram Is Initialized And Also The Scaling Of The Image--------------------*/
	
	localparam  scale_lp = 4; // By how much should I scale the height and width of the image
	localparam scale_height_lp = (image_height_lp-2) *scale_lp;
	localparam scale_width_lp = (image_width_lp-2)*scale_lp;

	reg [$clog2(image_width_lp * image_height_lp)-1:0] display_rd_addr_r; // Display Address For Ram
	always_comb begin
		rd_address_l = finished_sobel_op_r ? display_rd_addr_r : rd_address_3x3_o_w; // If Sobel not finished use rd_address of 3x3 sep, else use the Display Addr
	end
	reg [0:0] rd_buff_r;
	

	reg [15:0] line_start_r; // Which line of image should I start reading from
	reg [$clog2(scale_lp)-1:0] scale_x_count_r; // scales in the x direction
	reg [$clog2(scale_lp)-1:0] scale_y_count_r; // Scales in the y direction
	reg [$clog2(image_width_lp * image_height_lp)-1:0] stay_on_address_r;
	always_ff @ (posedge clk_pix_i) begin
		if (reset_r) begin
			line_start_r <= 0; // Initial line address start 0
			scale_x_count_r <= 0; // Current scaling of image in x 0
			display_rd_addr_r <= '0; // Initial rd_addr for display 0
			rd_buff_r <= '0; // 
			stay_on_address_r <= 0;
		end else begin
			if (frame_o_w) begin
				line_start_r <= 0;
				display_rd_addr_r <= 0;
				scale_x_count_r <= 0;
				scale_y_count_r <= 0;
				stay_on_address_r <= 0;
			end else if (paint_area_l) begin
				// Scaling in the x axis
				if (scale_lp-1 != 0) begin
					if (scale_x_count_r == scale_lp-1) begin
						scale_x_count_r <= 0;
					end else if (scale_x_count_r == scale_lp-2) begin
						display_rd_addr_r <= display_rd_addr_r + 1;
						scale_x_count_r <= scale_x_count_r + 1;
					end else begin
						scale_x_count_r <= scale_x_count_r + 1;
					end
				end else begin
					display_rd_addr_r <= display_rd_addr_r + 1;
				end
			end else begin
				if (sx_o_w == scale_width_lp) begin
					if (line_start_r == scale_lp-1) begin
						line_start_r <= 0;
						stay_on_address_r <= display_rd_addr_r;
					end else begin
						display_rd_addr_r <= stay_on_address_r;
						line_start_r <= line_start_r + 1;
					end
				end
			end
		end
	end

	// Section:  Used to assign pixel color to display
	logic [0:0] paint_area_l;
	always_comb begin
		paint_area_l = (sx_o_w >= 0 && sx_o_w < scale_width_lp) & (sy_o_w >= 0 && sy_o_w < scale_height_lp);
	end

	logic [3:0] display_c_l; // Only holds one Color
	always_comb begin
		display_c_l = paint_area_l & finished_sobel_op_r? rd_data_o_w : 4'h5;
	end


	/*---------------------------------Initializing Display Module------------------------------------------------------*/
	wire signed [15:0] sx_o_w, sy_o_w;
	wire [0:0] h_sync_o_w, v_sync_o_w, de_o_w, frame_o_w, line_o_w;
	display_480p
		#()
	display_480p_inst
		(.clk_pix_i(clk_pix_i)
		,.rst_pix_i(!clk_pix_locked_i)
		,.sx_o(sx_o_w)
		,.sy_o(sy_o_w)
		,.hsync_o(h_sync_o_w)
		,.vsync_o(v_sync_o_w)
		,.de_o(de_o_w)
		,.frame_o(frame_o_w)
		,.line_o(line_o_w)
		);
	SB_IO #(
        .PIN_TYPE(6'b010100)  // PIN_OUTPUT_REGISTERED
    ) dvi_signal_io [14:0] (
        .PACKAGE_PIN({dvi_hsync_o, dvi_vsync_o, dvi_de_o, dvi_r_o, dvi_g_o, dvi_b_o}),
        .OUTPUT_CLK(clk_pix_i),
        .D_OUT_0({h_sync_o_w, v_sync_o_w, de_o_w, display_c_l, display_c_l, display_c_l}),
        .D_OUT_1()
    );

    // DVI Pmod clock output: 180° out of phase with other DVI signals
    SB_IO #(
        .PIN_TYPE(6'b010000)  // PIN_OUTPUT_DDR
    ) dvi_clk_io (
        .PACKAGE_PIN(dvi_clk_o),
        .OUTPUT_CLK(clk_pix_i),
        .D_OUT_0(1'b0),
        .D_OUT_1(1'b1)
    );



endmodule
