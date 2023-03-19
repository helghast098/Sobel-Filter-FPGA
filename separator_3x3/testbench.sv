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

	 logic [0:0]  error_o; // error output
	 logic [0:0] ready; // ready to check data produced by ready
	 logic [0:0] reset_done = 1'b0; // if reset done
	 wire [width_lp-1:0] DUT_data_o; // Data out from separator 3x3
	 wire [$clog2(16)-1:0] DUT_rd_addr_o; // rd data_o from separator 3x3
	 wire [0:0] DUT_ready_o; // ready out from separator 3x3
	 wire [0:0] DUT_valid_o; // valid out from separator 3x3
	 logic [10:0] itervar; // Iterates my for loop
	 logic [2:0] data_iter; // data iteration of correct dasta
	 logic [width_lp-1:0] correct_data [3:0]; // correct data array
	 logic [width_lp-1:0] correct_d = '0; //  correct d

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
     
     
     /*Instantiating ram module*/
	 wire [3:0] rd_ram_data_o; // data from sync ram
	 ram_1r1w_sync
	 	#(.width_p(4)
		 ,.depth_p(16)
		 ,.filename_p("data.hex"))
	 ram_1r1w_sync_inst
		(.clk_i(clk_i)
		,.reset_i(reset_i)
		,.wr_valid_i(1'b0)
		,.wr_addr_i('0)
		,.wr_data_i('0)
		,.rd_addr_i(DUT_rd_addr_o)
		,.rd_data_o(rd_ram_data_o)
		);

		reg [0:0] ready_for_read; // Tells 3x3 to wait 1 cycle before using read data
   
   
   /*Instantiating separator 3x3*/

   separator_3x3
     #(.horiz_width_p(4)
       ,.vertic_width_p(4)
       )
   dut
     (.clk_i(clk_i)
		,.reset_i(reset_i)

		,.ready_i(ready)
		,.valid_i(ready_for_read)

		,.valid_o(DUT_valid_o)
		,.ready_o(DUT_ready_o)

		,.data_o(DUT_data_o)

		,.rd_data_i(rd_ram_data_o)
		,.rd_address_o(DUT_rd_addr_o)
		 );

// START OF THE INITIAL BLOCK
   initial begin
`ifdef VERILATOR
      $dumpfile("verilator.fst");
`else
      $dumpfile("iverilog.vcd");
`endif
      $dumpvars;

			$display();
			
      $display("Begin Test:");



      // Good Luck!
			correct_data[0] = 36'h1235679AB;
			correct_data[1] = 36'h234678ABC;
			correct_data[2] = 36'h5679ABDEF;
			correct_data[3] = 36'h678ABCEF0;
			itervar = '0;
			data_iter = '0;
			ready = 1;
			error_o = 0;
			@(negedge reset_i); // Waiting for reset to go down
			reset_done = 1'b1; // Reset is done

			while(data_iter != 4) begin
				@(negedge clk_i);
				if (DUT_valid_o) begin
					correct_d = correct_data[data_iter[1:0]];
					data_iter = data_iter + 1;
				end
			end
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			@(posedge clk_i);
			$finish();
   end

	 // Alternating ready for read from separator 3x3
	always_ff @(negedge clk_i) begin
		if (reset_i)
			ready_for_read <= '1;
		else if (ready_for_read & DUT_ready_o)
			ready_for_read <= '0;
		else
			ready_for_read <= 1;
	end
	
	// Checking for correct output	
	always @(posedge clk_i) begin
		if (reset_done) begin
			if (DUT_valid_o & ready) begin
				if (correct_d != DUT_data_o) begin
					error_o = 1;
					$display("ERROR: correct_out %h  does not match DUT_out %h", correct_d, DUT_data_o);
					$finish();
				end
			end
		end
	end



	/*This is where I set the next values in the negedge*/


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
