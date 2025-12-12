module select_logic(
	input clk,
	input rst,
	input [3:0] KEY,
	output reg menu,
	output reg drum,
	output reg synth,
	output reg demo
	);
	
	reg[2:0] S, NS;

parameter  IDLE      = 3'd0,
			  DRUM   	= 3'd1,
			  DRUM_WAIT = 3'd2,		
			  SYNTH 		= 3'd3,
			  SYNTH_WAIT = 3'd4,
			  DEMO		= 3'd5,
			  DEMO_WAIT = 3'd6,
			  MENU      = 3'd7;
			  

always @(posedge clk or negedge rst)
begin
	if (!rst)
		S <= IDLE;
	else
		S <= NS;
end

always @(*)
begin
case(S)
	IDLE: if (KEY[2] == 1'b0)
				NS = DRUM;
			else
				NS = IDLE;
	
	DRUM: if (KEY[2] == 1'b1)
				NS = DRUM_WAIT;
			else
				NS = DRUM;
	DRUM_WAIT: if (KEY[2] == 1'b0)
				NS = SYNTH;
			else
				NS = DRUM_WAIT;
	SYNTH: if (KEY[2] == 1'b1)
				NS = SYNTH_WAIT;
			else
				NS = SYNTH;
	SYNTH_WAIT: if (KEY[2] == 1'b0)
						NS = DEMO;
					else
						NS = SYNTH_WAIT;
	DEMO: if (KEY[2] == 1'b1)
				NS = DEMO_WAIT;
			else
				NS = DEMO;
	DEMO_WAIT: if (KEY[2] == 1'b0)
						NS = MENU;
					else
						NS = DEMO_WAIT;
	MENU: if(KEY[2] == 1'b1)
				NS = IDLE;
			else
				NS = MENU;
endcase
end

always @(posedge clk or negedge rst)
begin
	if (!rst)
	begin
		menu <= 1'b1;
		drum <= 1'b0;
		synth <= 1'b0;
		demo <= 1'b0;

	end
	else
		case(S)
			IDLE: begin
				menu <= 1'b1;
				drum <= 1'b0;
				synth <= 1'b0;
				demo <= 1'b0;
				end
			DRUM: begin
				menu <= 1'b0;
				drum <= 1'b1;
				synth <= 1'b0;
				demo <= 1'b0;
				end
			DRUM_WAIT: begin
				menu <= 1'b0;
				drum <= 1'b1;
				synth <= 1'b0;
				demo <= 1'b0;
				end
			SYNTH: begin
				menu <= 1'b0;
				drum <= 1'b0;
				synth <= 1'b1;
				demo <= 1'b0;
				end
			SYNTH_WAIT: begin
				menu <= 1'b0;
				drum <= 1'b0;
				synth <= 1'b1;
				demo <= 1'b0;
				end
			DEMO: begin
				menu <= 1'b0;
				drum <= 1'b0;
				synth <= 1'b0;
				demo <= 1'b1;
				end
			DEMO_WAIT: begin
				menu <= 1'b0;
				drum <= 1'b0;
				synth <= 1'b0;
				demo <= 1'b1;
				end
			MENU: begin
				menu <= 1'b1;
				drum <= 1'b0;
				synth <= 1'b0;
				demo <= 1'b0;
				end
		endcase
end
endmodule