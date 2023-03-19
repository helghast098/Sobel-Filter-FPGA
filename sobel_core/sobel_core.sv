module sobel_core
	 (input [0:0] clk_i
	 ,input [0:0] reset_i
	 ,input [35:0] data_i
	 ,input [0:0] valid_i
	 ,input [0:0] ready_i
	 ,output [0:0] valid_o
	 ,output [0:0] ready_o
	 ,output [3:0] data_o
	 );

	assign ready_o = (~valid_o | ready_i) & ~computing_r; // setting the ready_o signal
	assign valid_o = valid_o_r;
	assign data_o = data_o_r;

	reg [3:0] A_r, B_r, C_r, D_r, E_r, F_r, G_r, H_r, I_r; // Holds the numbers from separator_3x3 module

	// : ) Always FF Assigning register values used in addition -----FF
	always_ff @ (posedge clk_i) begin
		if (reset_i) begin
			{A_r, B_r, C_r, D_r, E_r, F_r, G_r, H_r, I_r} <= '0;
		end else if (ready_o & valid_i) begin
			{A_r, B_r, C_r, D_r, E_r, F_r, G_r, H_r, I_r} <= (valid_i & ready_o) ? data_i : {A_r, B_r, C_r, D_r, E_r, F_r, G_r, H_r, I_r};
		end
	end
	//------------------------------------------------------

	reg [7:0] sub_1_1_r, sub_2_1_r, sub_3_1_r, sub_1_2_r, sub_2_2_r, sub_3_2_r; // Holds my initiial sub values
	logic [7:0] sub_1_1_n, sub_2_1_n, sub_3_1_n, sub_1_2_n, sub_2_2_n, sub_3_2_n;

	// : ) Always FF Assigning sub values first computation -----FF
	always_ff @ (posedge clk_i) begin
		if (reset_i) begin
			 {sub_1_1_r, sub_2_1_r, sub_3_1_r, sub_1_2_r, sub_2_2_r, sub_3_2_r} <= '0;
		end else begin
			sub_1_1_r <= sub_1_1_n;
			sub_2_1_r <= sub_2_1_n;
			sub_3_1_r <= sub_3_1_n;
			sub_1_2_r <= sub_1_2_n;
			sub_2_2_r <= sub_2_2_n;
			sub_3_2_r <= sub_3_2_n;
		end
	end
	//-------------------------------------------------------------

	reg [3:0] data_o_r, data_o_n;
	reg [7:0] addition_1_r, addition_2_r;
	logic [7:0] addition_1_n, addition_2_n;
	reg [7:0] max_r, min_r, max_n, min_n;
	reg [17:0] max_comp_r, max_comp_n, min_comp_r, min_comp_n;
	reg [17:0] final_result_r, final_result_n;

	// : ) Always FF Assigning addition values computation -----FF
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			data_o_r <= '0;
			addition_1_r <= '0;
			addition_2_r <= '0;
			max_r <= '0;
			min_r <= '0;
			max_comp_r <= '0;
			min_comp_r <= '0;
			final_result_r <= '0;
		end else begin
			data_o_r <= data_o_n;
			addition_1_r <= addition_1_n;
			addition_2_r <= addition_2_n;
			max_r <= max_n;
			min_r <= min_n;
			max_comp_r <= max_comp_n;
			min_comp_r <= min_comp_n;
			final_result_r <= final_result_n;
		end
	end
	//------------------------------------------------------------

	reg [0:0] computing_r, computing_n; // High when computing, low when not computing.
	enum logic [3:0] {state_init_s = 4'b0000,
										state_comp_1_s = 4'b0001, // Getting components of Gx and Gy
										state_comp_2_s = 4'b0010, // Getting result of Gx and Gy
										state_comp_3_s = 4'b0011, // Finding the absolute value of Gx and Gy
										state_comp_4_s = 4'b0100, // Finding result of |GX| + |Gy|
										state_comp_5_s = 4'b0101, // Getting min and max
										state_comp_6_s = 4'b0110, // getting max and min comp
										state_comp_7_s = 4'b0111, // adding max comp and left shifting by 8
										state_finish_s = 4'b1000 // Have data, waiting for ready_o
									 }
						module_state_r,
						module_state_n;

	// : ) Always FF block for state transition and computing -----FF
	reg [0:0] valid_o_r, valid_o_n;
	always_ff @(posedge clk_i) begin
		if (reset_i) begin
			valid_o_r <= '0;
			computing_r <= '0;
			module_state_r <= state_init_s;
		end else begin
			valid_o_r <= valid_o_n;
			computing_r <= computing_n;
			module_state_r <= module_state_n;
		end
	end
 //--------------------------------------------------------------

	always_comb begin
		case(module_state_r)
			// Initial state waiting for valid_i
			state_init_s: begin
				if (ready_o & valid_i) begin
					computing_n = '1;
					module_state_n = state_comp_1_s;
				end else begin // Stay in same state
					computing_n = computing_r;
					module_state_n = module_state_r;
				end

				// Only adding to stop latch warning
				valid_o_n = valid_o_r;
				data_o_n = data_o_r;
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				addition_1_n = addition_1_r;
				addition_2_n = addition_2_r;
				max_n = max_r;
				min_n = min_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;
				final_result_n = final_result_r;
				
			end

			// Computing state 1
			state_comp_1_s: begin
				// Computation for Gx
				sub_1_1_n = {4'h0, C_r} - {4'h0, A_r}; //  C - A
				sub_2_1_n = ({4'h0, F_r} - {4'h0, D_r}) << 1; // 2 * (F-D)
				sub_3_1_n = {4'h0, I_r} - {4'h0, G_r}; // I - G

				// Computing for Gy
				sub_1_2_n = {4'h0, G_r} - {4'h0, A_r}; // G - A
				sub_2_2_n = ({4'h0, H_r} - {4'h0, B_r}) << 1; // 2 * (H-B)
				sub_3_2_n = {4'h0, I_r} - {4'h0, C_r}; // I - C

				// go to next state
				module_state_n = state_comp_2_s;

				// Only adding to stop latch warning
				valid_o_n = valid_o_r;
				computing_n = computing_r; // reset to init state
				data_o_n = data_o_r;;
				addition_1_n = addition_1_r;
				addition_2_n = addition_2_r;
				max_n = max_r;
				min_n = min_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;
				final_result_n = final_result_r;
			end

			// Computing state 2
			state_comp_2_s: begin
				addition_1_n = sub_1_1_r + sub_2_1_r + sub_3_1_r; // Gx
				addition_2_n = sub_1_2_r + sub_2_2_r + sub_3_2_r; // Gy

				// go to next state
				module_state_n = state_comp_3_s;

				// Only adding to stop lint warning
				valid_o_n = valid_o_r;
				computing_n = computing_r;
				data_o_n = data_o_r;
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				max_n = max_r;
				min_n = min_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;
				final_result_n = final_result_r;
			end

			// Computing state_3 // Converting values to absolute value
			state_comp_3_s: begin
				// Taking absolute value of addition 1
				if (addition_1_r[7])
					addition_1_n = -addition_1_r;
				else
					addition_1_n = addition_1_r;

				if (addition_2_r[7])
					addition_2_n = -addition_2_r;
				else
					addition_2_n = addition_2_r;

				// go to next state
				module_state_n = state_comp_4_s;

				// Only adding to stop latch warning
				valid_o_n = valid_o_r;
				computing_n = computing_r;
				data_o_n = data_o_r;
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				max_n = max_r;
				min_n = min_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;
				final_result_n = final_result_r;
			end

			// Computing state_4 // Final adding of results
			state_comp_4_s: begin
				module_state_n = state_comp_5_s;
				
				if (addition_1_r < addition_2_r) begin
					max_n = addition_2_r;
					min_n = addition_1_r;
				end else begin
					max_n = addition_1_r;
					min_n = addition_2_r;
				end

				// Only adding to stop latch warning
				valid_o_n = valid_o_r;
				computing_n = computing_r; // reset to init state
				data_o_n = data_o_r;
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				addition_1_n = addition_1_r;
				addition_2_n = addition_2_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;
				final_result_n = final_result_r;
			end
			
			state_comp_5_s: begin
				max_comp_n = ({{10{1'b0}}, max_r} << 8) + ({{10{1'b0}}, max_r} << 3) - ({{10{1'b0}}, max_r} << 4) - ({{10{1'b0}}, max_r} << 1);
				min_comp_n = ({{10{1'b0}}, min_r} << 7) - ({{10{1'b0}}, min_r} << 5) + ({{10{1'b0}}, min_r} << 3) - ({{10{1'b0}}, min_r} << 1);
				module_state_n = state_comp_6_s;
				
				// Only adding to stop latch warning
				valid_o_n = valid_o_r;
				computing_n = computing_r; // reset to init state
				data_o_n = data_o_r;
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				addition_1_n = addition_1_r;
				addition_2_n = addition_2_r;
				max_n = max_r;
				min_n = min_r;
				final_result_n = final_result_r;
				
				
			end
			
			state_comp_6_s: begin
				final_result_n = (max_comp_r + min_comp_r) >> 8;
				module_state_n = state_comp_7_s;
				
				
				// Only adding to stop lint warning
				valid_o_n = valid_o_r;
				computing_n = computing_r; // reset to init state
				data_o_n = data_o_r;
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				addition_1_n = addition_1_r;
				addition_2_n = addition_2_r;
				max_n = max_r;
				min_n = min_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;	
			
			end
			// Final Addition
			state_comp_7_s: begin
				if (final_result_r < 18'd15) begin
					data_o_n = final_result_r[3:0];
				end else begin
					data_o_n = 4'hF;
				end

				valid_o_n = 1'b1; // Set valid high
				computing_n = 1'b0; // Set compute low
				module_state_n = state_finish_s;


				// Only adding here to stop latch warning
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				addition_1_n = addition_1_r;
				addition_2_n = addition_2_r;
				max_n = max_r;
				min_n = min_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;	
				final_result_n = final_result_r;
			end

			// This is the state where I transmit the data
			state_finish_s: begin
				// If data ready to be sent out
				data_o_n = data_o_r;
				if (ready_i) begin
					valid_o_n = 1'b0; // setting valid low
					if (valid_i) begin
						computing_n = 1'b1;
						module_state_n = state_comp_1_s; // go to compute state
					end else begin
						computing_n = computing_r;
						module_state_n = state_init_s;
					end

				// Stay in same state
				end else begin
					valid_o_n = valid_o_r;// holds same valid state
					computing_n = computing_r;
					module_state_n = module_state_r; // Stay in same state
				end

				// Only including here to remove latch warning
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				addition_1_n = addition_1_r;
				addition_2_n = addition_2_r;
				max_n = max_r;
				min_n = min_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;	
				final_result_n = final_result_r;

			end

			// Default case
			default: begin
				valid_o_n = valid_o_r;
				computing_n = computing_r; // reset to init state
				data_o_n = data_o_r;
				sub_1_1_n = sub_1_1_r;
				sub_2_1_n = sub_2_1_r;
				sub_3_1_n = sub_3_1_r;
				sub_1_2_n = sub_1_2_r;
				sub_2_2_n = sub_2_2_r;
				sub_3_2_n = sub_3_2_r;
				addition_1_n = addition_1_r;
				addition_2_n = addition_2_r;
				module_state_n = module_state_r;
				max_n = max_r;
				min_n = min_r;
				max_comp_n = max_comp_r;
				min_comp_n = min_comp_r;
				final_result_n = final_result_r;
			end
		endcase
	end
endmodule
