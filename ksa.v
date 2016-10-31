module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;


// state names here as you complete your design	

typedef enum {state_init, state_fill, state_readsi, state_donothingsi, state_computejreadsj, state_donothingsj, state_writesi, state_writesj, state_done} state_type;
state_type state;

// these are signals that connect to the memory

reg [7:0] address, data, q;
reg wren;

// include S memory structurally

reg [8:0] i;
reg [8:0] j;
reg [7:0] si;
reg [7:0] sj;
reg [7:0] temp;

wire [23:0] secret_key;
assign secret_key[23:10] = 1'b0;
assign secret_key[9:0] = SW;
parameter KEY_LENGTH = 3;

s_memory u0(address, CLOCK_50, data, wren, q);

always_ff @(posedge CLOCK_50, negedge KEY[3])
	if (KEY[3] == 0) begin
		state <= state_init;
		i = 0;
	end else
	case (state)
		state_init: begin
			i = 0;
			state <= state_fill;
			wren <= 1'b1;
		end // case state_init
		state_fill: begin
			address <= i[7:0];
			data <= i[7:0];
			wren <= 1'b1;
			i = i + 1;
			if (i == 256) begin
				i = 0;
				j = 0;
				state <= state_readsi;
			end // if
		end // case state_fill
		state_readsi: begin
			wren <= 1'b0;
			address <= i[7:0];
			state <= state_donothingsi;
		end
		state_donothingsi: begin
			state <= state_computejreadsj;
		end
		state_computejreadsj: begin
			si = q;
			case(i%KEY_LENGTH) 
				0: j = (j + si + secret_key[23:16])%256;
				1: j = (j + si + secret_key[15:8])%256;
				2: j = (j + si + secret_key[7:0])%256;
			endcase
			temp = si;
			address <= j[7:0];
			state <= state_donothingsj;
		end
		state_donothingsj: begin
			state <= state_writesi;
		end
		state_writesi: begin
			sj = q;
			wren <= 1'b1;
			address <= i[7:0];
			data <= sj[7:0];
			state <= state_writesj;
		end
		state_writesj: begin
			wren <= 1'b1;
			address <= j[7:0];
			data <= temp[7:0];
			i = i + 1;
			if (i < 256) begin
				state <= state_readsi;
			end else begin 
				state <= state_done;
			end
		end
		state_done: begin
			wren <= 1'b0;
			state <= state_done;
		end
	endcase // case

endmodule



