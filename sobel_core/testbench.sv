// Do not modify this file!
`timescale 1ns/1ps
`ifndef WIDTH
`define WIDTH 36
`endif
module testbench();
   localparam width_lp = `WIDTH;

   logic [0:0] up_i;
   wire [0:0]  clk_i;
   wire [0:0]  reset_i;
	 logic [$clog2(image_width_lp*image_height_lp):0] data_count; // How many times to write to the file

	 logic [0:0]  error_o; // error output
	 logic [0:0] reset_done = 1'b0; // if reset done
	 logic [10:0] counter_s;

   nonsynth_clock_gen
     #(.cycle_time_p(10))
   cg
     (.clk_o(clk_i));

   nonsynth_reset_gen
     #(.num_clocks_p(1)
      ,.reset_cycles_lo_p(1)
      ,.reset_cycles_hi_p(10))
   rg
     (.clk_i(clk_i)
     ,.async_reset_o(reset_i));




		localparam image_width_lp = 160;  // Change fpr Image width
	 	localparam image_height_lp = 120; // Change for Image Height

	 /*-------------Initializing the sync ram module for reading input image---------------*/
	  wire [3:0] rd_data_o_w; // wire holding rd data from ram
	 	ram_1r1w_sync
	 		#(.width_p(4)
	 		 ,.depth_p(image_width_lp * image_height_lp)
	 		 ,.filename_p("input_image/gray_image.txt")
	 		 )

	 	ram_1r1w_sync_inst_image
	 		(.clk_i(clk_i)
	 		,.reset_i(reset_i)
	 		,.wr_valid_i('0)
	 		,.wr_data_i('0)
	 		,.wr_addr_i('0)
	 		,.rd_addr_i(rd_address_3x3_o_w)
	 		,.rd_data_o(rd_data_o_w)
	 		);

			reg [0:0] valid_o_ram_r; // High when data from ram is valid
			always_ff @(posedge clk_i) begin
				if (reset_i) begin
					valid_o_ram_r <= 1;
				end else if (valid_o_ram_r & ready_sep_3x3_o_w)
					valid_o_ram_r <= 0;
				else
					valid_o_ram_r <= 1;
			end

	  /*-------------------Initializing separator_3x3 module-------------------------*/
		wire [0:0] valid_sep_3x3_o_w; // valid
		wire [0:0] ready_sep_3x3_o_w;
		wire [$clog2(image_width_lp * image_height_lp)-1:0] rd_address_3x3_o_w; // rd address output for 3x3
		wire [35:0] sep_3x3_data_o_w; // 3x3 data
		separator_3x3
			#(.horiz_width_p(image_width_lp)
			 ,.vertic_width_p(image_height_lp)
			 )
		separator_3x3_inst
			(.clk_i(clk_i)
			 ,.reset_i(reset_i)
			 ,.valid_i(valid_o_ram_r)
			 ,.rd_data_i(rd_data_o_w)
			 ,.rd_address_o(rd_address_3x3_o_w)
			 ,.ready_o(ready_sep_3x3_o_w)
			 ,.ready_i(ready_sobelC_o_w)
			 ,.data_o(sep_3x3_data_o_w)
			 ,.valid_o(valid_sep_3x3_o_w)
			 );

		/*---------------Initializing sobel_core -----------------------------------*/
		wire [0:0] ready_sobelC_o_w;
		wire [0:0] valid_sobelC_o_w;
		wire [3:0] data_sobelC_o_w;
		sobel_core
 			#()
 		sobel_core_inst
 			(.clk_i(clk_i)
 			,.reset_i(reset_i)
 			,.data_i(sep_3x3_data_o_w)
 			,.valid_i(valid_sep_3x3_o_w)
 			,.ready_i(1'b1)
 			,.valid_o(valid_sobelC_o_w)
 			,.ready_o(ready_sobelC_o_w)
 			,.data_o(data_sobelC_o_w)
 			);

		// rd address output for 3x3 separaotr
		logic [$clog2(image_width_lp * image_height_lp)-1:0] rd_address_check_l;

		// check Data_o from sobel core
		wire [3:0] check_Data_o;

		// Which address the sobel data_o should go to
		reg [$clog2(image_width_lp * image_height_lp)-1:0] wr_address_sobel_r;

		// Increments wr address of sobel only when data_o is valid
		always_ff @(posedge clk_i) begin
			if (reset_i) begin
				wr_address_sobel_r <= '0;
			end else begin
				if (valid_sobelC_o_w)
					wr_address_sobel_r <=  wr_address_sobel_r + 1;
				end
			end

		/*Initializing second ram module for writing sobel data into */
		ram_1r1w_sync
	 		#(.width_p(4)
	 		 ,.depth_p(image_width_lp * image_height_lp)
			 ,.file_avail_p(0)
	 		 )
	 	ram_1r1w_sync_inst_check
	 		(.clk_i(clk_i)
	 		,.reset_i(reset_i)
	 		,.wr_valid_i(valid_sobelC_o_w)
	 		,.wr_data_i(data_sobelC_o_w)
	 		,.wr_addr_i(wr_address_sobel_r)
	 		,.rd_addr_i(rd_address_check_l)
	 		,.rd_data_o(check_Data_o)
	 		);
	 // Stop initilazing modules
	 int fd; // File where sobel data written into
	 int fd_1; // File where ram data is written into

// START OF THE INITIAL BLOCK
   initial begin
		 rd_address_check_l = 0;
		 fd = $fopen("output_image/image_out.txt", "w");
		 fd_1 = $fopen("output_image/image_check_out.txt", "w");
`ifdef VERILATOR
      $dumpfile("verilator.fst");
`else
      $dumpfile("iverilog.vcd");
`endif
      $dumpvars;

			$display();

			$display();
      $display("Begin Test:");
			error_o = '0;
			data_count ='0;
			@(negedge reset_i); // Waiting for reset to go down
			reset_done = 1'b1; // Reset is done

			while (data_count <= (image_width_lp-2)*(image_height_lp-2)) begin
				@(negedge clk_i);
				if (data_count == (image_width_lp-2)*(image_height_lp-2)) data_count += 1;
				if (valid_sobelC_o_w) begin
					$fdisplayh(fd, data_sobelC_o_w);
					data_count = data_count + 1;
					if (data_count == (image_width_lp-2)*(image_height_lp-2)) begin
						$fclose(fd);
					end

				end
			end
			@(negedge clk_i);
			data_count = 0;
			@(posedge clk_i);
			@(posedge clk_i);
			while (data_count <= (image_width_lp-2)*(image_height_lp-2)) begin
				if (data_count == (image_width_lp-2)*(image_height_lp-2)) data_count += 1;
				else begin
					$fdisplayh(fd_1, check_Data_o);
					data_count += 1;
					rd_address_check_l += 1;
					@(posedge clk_i);
					@(posedge clk_i);
			end
			end
			$display("%d", rd_address_check_l);

			// Adding ram memory to different file
			$fclose(fd_1);
			$finish();
   end

   final begin
      $display("Simulation time is %t", $time);
      if(error_o) begin
	 $display("\033[0;31m    ______                    \033[0m");
	 $display("\033[0;31m   / ____/_____________  _____\033[0m");
	 $display("\033[0;31m  / __/ / ___/ ___/ __ \\/ ___/\033[0m");
	 $display("\033[0;31m / /___/ /  / /  / /_/ / /    \033[0m");
	 $display("\033[0;31m/_____/_/  /_/   \\____/_/     \033[0m");
	 $display();
	 $display("Simulation Failed");

     end else begin
	 $display("\033[0;32m    ____  ___   __________\033[0m");
	 $display("\033[0;32m   / __ \\/   | / ___/ ___/\033[0m");
	 $display("\033[0;32m  / /_/ / /| | \\__ \\\__ \ \033[0m");
	 $display("\033[0;32m / ____/ ___ |___/ /__/ / \033[0m");
	 $display("\033[0;32m/_/   /_/  |_/____/____/  \033[0m");
	 $display();
	 $display("Simulation Succeeded!");
      end
   end

endmodule
