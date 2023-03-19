module separator_3x3
	#(parameter [31:0] horiz_width_p = 4
	 ,parameter [31:0] vertic_width_p = 4
	 ,parameter [31:0] color_channel_width_p = 4
	 )
	 (input [0:0] clk_i
	 ,input [0:0] reset_i
	 ,input [0:0] ready_i
	 ,output [$clog2(horiz_width_p * vertic_width_p)-1:0] rd_address_o
	 ,input [color_channel_width_p-1:0] rd_data_i
	 ,input [0:0] valid_i
	 ,output [0:0] ready_o
	 ,output [0:0] valid_o
	 ,output [35:0] data_o
	 );

	/*Assign to outputs*/
	assign ready_o = (~valid_o | ready_i) & ~finished_r;
	assign rd_address_o = rd_address_r;
	assign valid_o = valid_r;
	assign data_o = {data_o_1_r, data_o_2_r, data_o_3_r, data_o_4_r, data_o_5_r, data_o_6_r, data_o_7_r, data_o_8_r, data_o_9_r};
 /*-----------------*/

	reg [$clog2(horiz_width_p * vertic_width_p)-1:0] rd_address_r; // rd_address

	/*Initializing registers*/
	localparam [31:0] row_index_lp = horiz_width_p - 3;
	localparam [31:0] col_index_lp = vertic_width_p - 3;

	reg [0:0] finished_r; // Checks if I finished looking over ram
	reg [0:0] valid_r; // Holds the valid

	reg [3:0] data_o_1_r, // data register which holds the 3x3 matrix
	 					data_o_2_r,
						data_o_3_r,
						data_o_4_r,
						data_o_5_r,
						data_o_6_r,
						data_o_7_r,
						data_o_8_r,
						data_o_9_r;

	reg [1:0] column_index_r, row_index_r; // Keeps track of row and column index. EX 0,1,2
	reg [$clog2(horiz_width_p-2)-1:0] horiz_3x3_col_index_r; // Holds how many horiz 3x3 I encountered
	reg [$clog2(vertic_width_p-2)-1:0] vertic_3x3_row_index_r; // Holds How many vertical 3x3 I encountered
	reg [$clog2(horiz_width_p * vertic_width_p)-1:0] current_row_start_r; // Holds which row I prev started
	reg [$clog2(horiz_width_p * vertic_width_p)-1:0] next_3x3_start_r; // Holds which next 3x3 to start finding

	wire [3:0] row_col_w = {row_index_r, column_index_r}; // Tells which row and column I am in

	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			{data_o_1_r, data_o_2_r, data_o_3_r, data_o_4_r, data_o_5_r, data_o_6_r, data_o_7_r, data_o_8_r, data_o_9_r} <= '0;
			finished_r <= '0; // Setting finished to 0
			rd_address_r <= '0; // Setting the read address to zero
			valid_r <= '0;  // set valid to 0
			column_index_r <= '0; // column index to zero
			row_index_r <= '0; // row index to zero
			horiz_3x3_col_index_r <= '0; // 3x3 column index to zero
			vertic_3x3_row_index_r <= '0; // 3x3 row index to zero
			current_row_start_r <= '0; // Holds which row I started at
			next_3x3_start_r <= 1; // Holds which next 3x3 I should start finding which is 1 initially

		end else begin
			if (~valid_o && ~finished_r && ~(valid_i & ready_o)) begin
				case (row_col_w)
					// row 0 column 0 # 1
					4'b0000: begin
						column_index_r <= column_index_r + 1; // next column: 1
						data_o_1_r <= rd_data_i; //element 0x0 stored
						rd_address_r <= rd_address_r + 1; // go to element 0x1
					end

					// row 0 column 1 # 2
					4'b0001: begin
						column_index_r <= column_index_r + 1; // next column: 2
						data_o_2_r <= rd_data_i;
						rd_address_r <= rd_address_r + 1; // go to element 0x2
					end

					// row 0 column 2 # 3
					4'b0010: begin
						column_index_r <= '0; // resetting column index to 0
						row_index_r <= row_index_r + 1; // next row: 1
						data_o_3_r <= rd_data_i;
						rd_address_r <= current_row_start_r + horiz_width_p[$clog2(horiz_width_p * vertic_width_p)-1:0]; // Go to next row element 0x4
						current_row_start_r <= current_row_start_r + horiz_width_p[$clog2(horiz_width_p * vertic_width_p)-1:0]; // Set new row_start to new read_address
					end

					// row 1 column 0 # 4
					4'b0100: begin
						column_index_r <= column_index_r + 1; // next column: 1
						data_o_4_r <= rd_data_i;
						rd_address_r <= rd_address_r + 1; // go to element 0x5
					end

					// row 1 column 1 # 5
					4'b0101: begin
						column_index_r <= column_index_r + 1; // next column: 2
						data_o_5_r <= rd_data_i;
						rd_address_r <= rd_address_r + 1; // go to element 0x6
					end

					// row 1 column 2 # 6
					4'b0110: begin
						column_index_r <= '0; // resetting column index to 0
						row_index_r <= row_index_r + 1; // next row: 2
						data_o_6_r <= rd_data_i;
						rd_address_r <= current_row_start_r + horiz_width_p[$clog2(horiz_width_p * vertic_width_p)-1:0]; // Go to next row element 0x7
						current_row_start_r <= current_row_start_r + horiz_width_p[$clog2(horiz_width_p * vertic_width_p)-1:0];; // Set new row_start to new read_address
					end

					// row 2 column 0 # 7
					4'b1000: begin
						column_index_r <= column_index_r + 1; // next column: 1
						data_o_7_r <= rd_data_i;
						rd_address_r <= rd_address_r + 1; // go to element 0x8
					end

					// row 2 column 1 # 8
					4'b1001: begin
						column_index_r <= column_index_r + 1; // next column: 2
						data_o_8_r <= rd_data_i;
						rd_address_r <= rd_address_r + 1; // go to element 0x9
					end

					// row 2 column 2 # 9
					4'b1010: begin
						column_index_r <= '0; // resetting column index to 0
						row_index_r <= '0; // resetting row index to 0
						data_o_9_r <= rd_data_i;
						valid_r <= 1; // set valid High

						// If I am at the end of the getting all possible 3x3 matrices
						if ((horiz_3x3_col_index_r == row_index_lp[$clog2(horiz_width_p-2)-1:0]) && (vertic_3x3_row_index_r == col_index_lp[$clog2(vertic_width_p-2)-1:0]))
							finished_r <= '1; // Setting finished to 1

						else if (horiz_3x3_col_index_r == row_index_lp[$clog2(horiz_width_p-2)-1:0]) begin
							horiz_3x3_col_index_r <= '0; // Reseting 3x3 column index
							vertic_3x3_row_index_r <= vertic_3x3_row_index_r + 1; // incrementing 3x3 row index
							next_3x3_start_r <= next_3x3_start_r + 3;
							current_row_start_r <= next_3x3_start_r + 2;
							rd_address_r <= next_3x3_start_r + 2;

						end else begin
							horiz_3x3_col_index_r <= horiz_3x3_col_index_r + 1; // incrementing 3x3 col index
							next_3x3_start_r <= next_3x3_start_r + 1; // incrementing next start by 1
							current_row_start_r <= next_3x3_start_r; // setting current start to next_3x3_start
							rd_address_r <= next_3x3_start_r;
					  end
					end

					default: ;
				endcase
			end else if (valid_o) begin
				if (ready_i)
					valid_r <= '0;
			end
		end
	end

endmodule
