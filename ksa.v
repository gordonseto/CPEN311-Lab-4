module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;


// state names here as you complete your design	

typedef enum {state_init, state_fill, state_done} state_type;
state_type state;

// these are signals that connect to the memory

reg [7:0] address, data, q;
reg wren;

// include S memory structurally

reg [7:0] i;

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
				state <= state_done;
			end // if
		end // case state_fill
		state_done: state <= state_done;
	endcase // case

endmodule



