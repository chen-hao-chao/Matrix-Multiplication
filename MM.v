`define IDEL 2'b00
`define READ_SIZE 2'b11
`define READ_MATRIX 2'b10
`define WRITE 2'b01

module MM(clk,i,j,reset,read,write,index,read_data,write_data,finish);
	
	parameter n=20;
	
	input reset,clk;
	input signed [n-1:0]read_data;
	
	output [n-1:0]i,j;
	output read,write,index,finish;
	output signed[2*n-1:0]write_data;

	reg [1:0]state, next_state;
	reg signed [2*n-1:0]sum, next_sum;
	reg [n-1:0]row, next_row, col, next_col;//i, j for matrix A
	reg signed [n-1:0]rA, rB, next_rA, next_rB;//store A and B.
	reg [n-1:0]ma, mb, mc, next_ma, next_mb, next_mc;
	reg [3:0]counter, next_counter;//compute the times machine had read.
	reg idx_con, next_idx_con;//index control
	reg [n-1:0]B_col, next_B_col;

	wire signed [n-1:0]ra, rb;
	wire signed [n*2-1:0]p;

	assign ra = next_rA;
	assign rb = next_rB;
	assign p = ra*rb;

	always@(posedge clk)begin//sequential
		if(reset == 1'd1)begin
			state <= `IDEL;
			sum <= 40'd0;
			row <= 20'd0;
			col <= 20'd0;
			idx_con <= 1'd0;
			counter <= 4'd0;
			B_col <= 20'd0;
			ma <= 20'd0;
			mb <= 20'd0;
			mc <= 20'd0;
			rA <= 20'd0;
			rB <= 20'd0;
		end
		else begin
			state <= next_state;
			sum <= next_sum;
			row <= next_row;
			col <= next_col;
			idx_con <= next_idx_con;
			counter <= next_counter;
			B_col <= next_B_col;
			ma <= next_ma;
			mb <= next_mb;
			mc <= next_mc;
			rA <= next_rA;
			rB <= next_rB;
		end
	end

	always@(*)begin//state
		case(state)
			`IDEL:begin//initialize
				next_state = `READ_SIZE;
			end
			`READ_SIZE:begin
				next_state = (row == 20'd2)? `READ_MATRIX : `READ_SIZE;
			end
			`READ_MATRIX:begin
				next_state = (counter == 2*mb-1)? `WRITE : `READ_MATRIX;
			end
			`WRITE:begin
				next_state = `READ_MATRIX;
			end
			default:begin
				next_state = `IDEL;
			end
		endcase
	end
	always@(*)begin//others
		case(state)
			`IDEL:begin//initialize
				next_sum = 40'd0;
				next_row = 20'd0;
				next_col = 20'd0;
				next_idx_con = 1'd0;
				next_counter = 4'd0;
				next_B_col = 20'd0;
			end
			`READ_SIZE:begin
				next_sum = sum;//0
				next_row = (row == 20'd2)? 20'd0 : row + 20'd1;
				next_col = col;//0
				next_idx_con = idx_con;//0
				next_counter = 4'd0;
				next_B_col = 20'd0;
			end
			`READ_MATRIX:begin
				next_sum = (idx_con == 1'd1)? sum + p : sum;
				next_row = row;
				next_col = (idx_con == 1'd1)? col + 20'd1 : col;
				next_idx_con = (idx_con == 1'd1)? 1'd0 : 1'd1;
				next_counter = (counter == 2*mb-1)? 4'd0 : counter + 4'd1;
				next_B_col = B_col;
			end
			`WRITE:begin
				next_sum = 40'd0;
				next_row = (B_col == mc-1)? row + 20'b1 : row;
				next_col = 20'd0;
				next_idx_con = 1'd0;
				next_counter = 4'd0;
				next_B_col = (B_col == mc-1)? 20'd0 : B_col + 20'd1;
			end
			default:begin
				next_sum = 40'd0;
				next_row = 20'd0;
				next_col = 20'd0;
				next_idx_con = 1'd0;
				next_counter = 4'd0;
				next_B_col = 20'd0;
			end
		endcase
	end
	always@(*)begin
		case(state)
			`IDEL:begin//initialize
				next_ma = 20'd0;
				next_mb = 20'd0;
				next_mc = 20'd0;
				next_rA = 20'd0;
				next_rB = 20'd0;
			end
			`READ_SIZE:begin
				next_ma = (row == 20'd0)? read_data : ma;//size of the matrix
				next_mb = (row == 20'd1)? read_data : mb;
				next_mc = (row == 20'd2)? read_data : mc;
				next_rA = 20'd0;
				next_rB = 20'd0;
			end
			`READ_MATRIX:begin
				next_ma = ma;
				next_mb = mb;
				next_mc = mc;
				next_rA = (idx_con == 1'd0)? read_data : rA;
				next_rB = (idx_con == 1'd1)? read_data : rB;
			end
			`WRITE:begin
				next_ma = ma;
				next_mb = mb;
				next_mc = mc;
				next_rA = 20'd0;
				next_rB = 20'd0;
			end
			default:begin
				next_ma = 20'd0;
				next_mb = 20'd0;
				next_mc = 20'd0;
				next_rA = 20'd0;
				next_rB = 20'd0;
			end
		endcase
	end
	
	assign i = (idx_con == 1'b0)? row : col;
	assign j = (idx_con == 1'b0)? col : B_col;
	assign read = state[1];
	assign write = state[0];
	assign index = idx_con;
	assign finish = (state == `READ_MATRIX  && row == ma)? 1'd1 : 1'd0;
	assign write_data = sum;

endmodule
