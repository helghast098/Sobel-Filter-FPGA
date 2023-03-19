module sync_valid_mem
	#(parameter width_p = 4
	 ,parameter depth_p = 4
	 ,parameter filename_p = "unknown.txt")
	 (input [0:0] clk_i
	 ,input [0:0] reset_i
	 ,input [0:0] ready_i
	 ,output [0:0] valid_o

	 ,input [$clog2(depth_p)-1:0] rd_addr_i
	 ,output [width_p-1:0] rd_data_o

	 ,input [0:0] wr_e_i
	 ,input [width_p-1:0] wr_data_i
	 ,input [$clog2(depth_p)-1:0] wr_addr_i
	 );

	ram_1r1w_sync
 		#(.width_p(width_p)
 		 ,.depth_p(depth_p)
 		 ,.filename_p(filename_p)
 		 )
 	ram_1r1w_sync_inst
 		(.clk_i(clk_i)
 		,.reset_i(reset_i)
 		,.wr_valid_i(wr_e_i)
 		,.wr_data_i(wr_data_i)
 		,.wr_addr_i(wr_addr_i)
 		,.rd_addr_i(rd_addr_i)
 		,.rd_data_o(rd_data_o)
 		);

	reg [0:0] valid_o_ram_r; // High when data from ram is valid which is one cycle after the read
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			valid_o_ram_r <= 1;
		end else if (valid_o_ram_r & ready_i)
			valid_o_ram_r <= 0;
		else
			valid_o_ram_r <= 1;
	end
	assign valid_o = valid_o_ram_r;
endmodule
