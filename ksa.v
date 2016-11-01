module ksa( CLOCK_50, KEY, SW, LEDR);

input CLOCK_50;
input [3:0] KEY;
input [9:0] SW;
output [9:0] LEDR;


// state names here as you complete your design	

typedef enum {state_init, state_fill, state_readsi, state_donothingsi, state_computejreadsj, state_donothingsj, state_writesi, state_writesj, state_transition,
				state_readsi2, state_donothingsi2, state_computejreadsj2, state_donothingsj2, state_writesi2, state_writesj2, state_reads3, state_donothings3, 
				state_readROM, state_donothingROM, state_writeRAM, state_incrementk, state_add_secret_key, state_done} state_type;
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

reg [23:0] secret_key;
parameter KEY_LENGTH = 3;
assign LEDR = secret_key[21:12];

reg [5:0] k;
parameter MESSAGE_LENGTH = 32;
reg [7:0] f;
reg [7:0] encrypted_input;
reg [7:0] q_m;
reg [4:0] address_m;
reg [4:0] address_d;
reg [7:0] data_d;
reg wren_d;
reg [7:0] q_d;

s_memory u0(address, CLOCK_50, data, wren, q);
rom u1(address_m, CLOCK_50, q_m);
ram u2(address_d, CLOCK_50, data_d, wren_d, q_d);

always_ff @(posedge CLOCK_50, negedge KEY[3])
	if (KEY[3] == 0) begin
		state <= state_init;
		i = 0;
		secret_key = 0;
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
				state <= state_transition;
			end
		end
		state_transition: begin
			i = 0;
			j = 0;
			k = 0;
			state <= state_readsi2;
		end
		state_readsi2: begin
			i = (i + 1)%256;
			wren <= 1'b0;
			address <= i[7:0];
			state <= state_donothingsi2;
		end
		state_donothingsi2: begin
			state <= state_computejreadsj2;
		end
		state_computejreadsj2: begin
			si = q;
			temp = si;
			j = (j + si)%256;
			address <= j[7:0];
			state <= state_donothingsj2;
		end
		state_donothingsj2: begin
			state <= state_writesi2;
		end
		state_writesi2: begin
			sj = q;
			wren <= 1'b1;
			address <= i[7:0];
			data <= sj[7:0];
			state <= state_writesj2;
		end
		state_writesj2: begin
			wren <= 1'b1;
			address <= j[7:0];
			data <= temp[7:0];
			state <= state_reads3;
		end
		state_reads3: begin
			wren <= 1'b0;
			address <= (temp + sj)%256;
			state <= state_donothings3;
		end
		state_donothings3: begin
			state <= state_readROM;
		end
		state_readROM: begin
			f = q;
			address_m <= k[4:0];
			state <= state_donothingROM;
		end
		state_donothingROM: begin
			state <= state_writeRAM;
		end
		state_writeRAM: begin
			encrypted_input = q_m;
			data_d <= f ^ encrypted_input;
			address_d <= k[4:0];
			wren_d <= 1'b1;
			if ((8'b01100001 > (f ^ encrypted_input)) || ((f ^ encrypted_input) > 8'b01111010)) begin
				if ((f^encrypted_input) != 32) begin
					state <= state_add_secret_key;
				end else begin
					state <= state_incrementk;
				end
			end else begin
				state <= state_incrementk;
			end
		end
		state_incrementk: begin
			wren_d <= 1'b0;
			k = k + 1;
			if (k < MESSAGE_LENGTH ) begin
				state <= state_readsi2;
			end else begin
				secret_key = 24'b001000000000000000000000;
				state <= state_done;
			end
		end
		state_add_secret_key: begin
			wren_d <= 1'b0;
			secret_key = secret_key + 1;
			if (secret_key < 24'b010000000000000000000000) begin
				state <= state_init;
			end else begin
				secret_key = 24'b000100000000000000000000;
				state <= state_done;
			end
		end
		state_done: begin
			state <= state_done;
		end
		
	endcase // case

endmodule



