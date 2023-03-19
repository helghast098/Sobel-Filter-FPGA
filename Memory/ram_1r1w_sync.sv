module ram_1r1w_sync
  #(parameter [31:0] width_p = 8
    ,parameter [31:0] depth_p = 128
    ,parameter  filename_p = "memory_init_file.hex"
		,parameter  file_avail_p = 1) // 1: Use file 0: Don't use file
   (input [0:0] clk_i
    ,input [0:0] reset_i

    ,input [0:0] wr_valid_i
    ,input [width_p-1:0] wr_data_i
    ,input [$clog2(depth_p) - 1 : 0] wr_addr_i

    ,input [$clog2(depth_p) - 1 : 0] rd_addr_i
    ,output [width_p-1:0] rd_data_o
    );

		logic [width_p-1: 0] read_data_r; // read address register holder

		reg [width_p-1:0] mem_1R1W_sync [depth_p-1:0]; // memory array

		assign rd_data_o = read_data_r; // output read data

		always_ff @ (posedge clk_i) begin
			if (wr_valid_i & (~reset_i)) begin
				mem_1R1W_sync[wr_addr_i] <= wr_data_i; // write address
			end

			read_data_r <= mem_1R1W_sync[rd_addr_i];
		end


		initial begin
			if (file_avail_p == 1) $readmemh(filename_p, mem_1R1W_sync);
		end
endmodule
