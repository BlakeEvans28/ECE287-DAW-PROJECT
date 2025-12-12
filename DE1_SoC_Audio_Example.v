module DE1_SoC_Audio_Example (

    	//////////// ADC //////////
	//output		          		ADC_CONVST,
	//output		          		ADC_DIN,
	//input 		          		ADC_DOUT,
	//output		          		ADC_SCLK,

	//////////// Audio //////////
	input 		          		AUD_ADCDAT,
	inout 		          		AUD_ADCLRCK,
	inout 		          		AUD_BCLK,
	output		          		AUD_DACDAT,
	inout 		          		AUD_DACLRCK,
	output		          		AUD_XCK,

	//////////// CLOCK //////////
	input 		          		CLOCK_50,

	//////////// I2C for Audio and Video-In //////////
	output		          		FPGA_I2C_SCLK,
	inout 		          		FPGA_I2C_SDAT,

	//////////// SEG7 //////////
	output		     [6:0]		HEX0,
	output		     [6:0]		HEX1,
	output		     [6:0]		HEX2,
	output		     [6:0]		HEX3,
	output		     [6:0]		HEX4,
	output		     [6:0]		HEX5,

	//////////// KEY //////////
	input 		     [3:0]		KEY,

	//////////// LED //////////
	output		     [9:0]		LEDR,

	//////////// SW //////////
	input 		     [9:0]		SW
);

// Turn off all 7-seg displays.
assign	HEX0		=	7'd0;
assign	HEX1		=	7'd0;
assign	HEX2		=	7'd0;
assign	HEX3		=	7'd0;
assign	HEX4		=	7'd0;
assign	HEX5		=	7'd0;

/*****************************************************************************
 *                 Internal Wires and Registers Declarations                 *
 *****************************************************************************/
wire clk  = CLOCK_50;
wire rst  = KEY[0];   // active-high reset

// Audio controller wires
wire				audio_in_available;
wire		[15:0]	left_channel_audio_in;
wire		[15:0]	right_channel_audio_in;

wire				audio_out_allowed;
wire		[15:0]	left_channel_audio_out;
wire		[15:0]	right_channel_audio_out;

reg                 write_audio_out;
reg                 read_audio_in;

// Sample selection base address
reg [15:0] sample_base;

// Memory (ROM) interface
reg  [15:0] mem_address;
reg  [31:0] idx;
wire [15:0] left_sample_q;
wire [15:0] right_sample_q;
reg         playing;
reg [31:0]  last_sample_q;

// FSM
reg [7:0] S;
reg [7:0] NS;

assign LEDR[7:0] = S;

/*****************************************************************************
 *                           Parameter Declarations                          *
 *****************************************************************************/

parameter SAMPLE_SOUND_SIZE = 32'd4096; // each sample length in words

// State encoding
parameter
		START                = 8'd0,
		WAIT_STATE           = 8'd1,
		TO_PLAY              = 8'h0b,
		PLAY                 = 8'h0c,
		LOAD_SAMPLE          = 8'h0d,
		LOAD_SAMPLE_2        = 8'h0e,
		LOAD_SAMPLE_3        = 8'h0f,
		INCREMENT_MEM_READ   = 8'h10,
		WAIT_COMPLETE_OUT_1  = 8'h11,
		WAIT_COMPLETE_OUT_2  = 8'h12,
		ERROR                = 8'hFF;

/*****************************************************************************
 *                            Combinational Logic                            *
 *****************************************************************************/

// WHEN SW[0] == 1: play from ROM
// WHEN SW[0] == 0: passthrough input
assign left_channel_audio_out  =
	(SW[0] && playing) ? last_sample_q[31:16] : left_channel_audio_in;

assign right_channel_audio_out =
	(SW[0] && playing) ? last_sample_q[15:0]  : right_channel_audio_in;

// Select which sample to play based on switches SW[2:1]
// 00 = sample 0 (hi-hat)
// 01 = sample 1 (snare)
// 10 = sample 2 (kick)
// 11 = sample 3 (clap)
always @(*) begin
    case (SW[2:1])
        2'b00: sample_base = 16'd0;        // sample 0 start
        2'b01: sample_base = 16'd4096;     // sample 1 start
        2'b10: sample_base = 16'd8192;     // sample 2 start
        2'b11: sample_base = 16'd12288;    // sample 3 start
        default: sample_base = 16'd0;
    endcase
end

// FSM next-state logic
always @(*) begin
	case (S)
		START: NS = WAIT_STATE;

		// Idle state:
		//  - SW[0] == 0 → passthrough mode
		//  - SW[0] == 1 & KEY[2] pressed → go to TO_PLAY
		WAIT_STATE:
			if (SW[0] && (KEY[2] == 1'b0))
				NS = TO_PLAY;
			else
				NS = WAIT_STATE;

		// Wait for KEY[2] release to avoid multiple triggers
		TO_PLAY:
			if (KEY[2] == 1'b1)
				NS = PLAY;
			else
				NS = TO_PLAY;

		// Main playback state: wait for audio_out_allowed and not finished
		PLAY:
			if (idx >= SAMPLE_SOUND_SIZE)
				NS = WAIT_STATE;
			else if (audio_out_allowed)
				NS = LOAD_SAMPLE;
			else
				NS = PLAY;

		LOAD_SAMPLE:         NS = LOAD_SAMPLE_2;
		LOAD_SAMPLE_2:       NS = LOAD_SAMPLE_3;
		LOAD_SAMPLE_3:       NS = INCREMENT_MEM_READ;
		INCREMENT_MEM_READ:  NS = WAIT_COMPLETE_OUT_1;
		WAIT_COMPLETE_OUT_1: NS = WAIT_COMPLETE_OUT_2;
		WAIT_COMPLETE_OUT_2: NS = PLAY;

		default: NS = ERROR;
	endcase
end

/*****************************************************************************
 *                             Sequential Logic                              *
 *****************************************************************************/

always @(posedge clk or negedge rst)
	if (rst == 1'b0)
	begin
		S               <= START;
		mem_address     <= 16'd0;
		idx             <= 32'd0;
		playing         <= 1'b0;
		last_sample_q   <= 32'd0;
		write_audio_out <= 1'b0;
		read_audio_in   <= 1'b0;
	end
	else
	begin
		S <= NS;

		case (S)
			// Idle / wait
			WAIT_STATE:
			begin
				playing     <= 1'b0;
				idx         <= 32'd0;
				mem_address <= 16'd0;

				if (SW[0] == 1'b0) begin
					// Passthrough: feed input to output
					read_audio_in   <= audio_in_available & audio_out_allowed;
					write_audio_out <= audio_in_available & audio_out_allowed;
				end
				else begin
					// Playback mode idle: don't read/write audio buffers yet
					read_audio_in   <= 1'b0;
					write_audio_out <= 1'b0;
				end
			end

			// Start of playback
			PLAY:
			begin
				playing <= 1'b1;
				// idx is advanced in INCREMENT_MEM_READ
			end

			// Actual memory read and output staging
			INCREMENT_MEM_READ:
			begin
				write_audio_out <= 1'b1;
				last_sample_q   <= {left_sample_q, right_sample_q};

				if (idx == 32'd0)
					mem_address <= sample_base;    // first sample: jump to chosen sound
				else
					mem_address <= mem_address + 1'b1;

				idx <= idx + 1'b1;
			end

			WAIT_COMPLETE_OUT_2:
			begin
				write_audio_out <= 1'b0;
			end

			default: ;
		endcase
	end

/*****************************************************************************
 *                              Internal Modules                             *
 *****************************************************************************/

Audio_Controller Audio_Controllers (
	// Inputs
	.CLOCK_50					(clk),
	.reset						(~rst),

	.clear_audio_in_memory		(),
	.read_audio_in				(read_audio_in),
	
	.clear_audio_out_memory		(),
	.left_channel_audio_out		(left_channel_audio_out),
	.right_channel_audio_out	(right_channel_audio_out),
	.write_audio_out			(write_audio_out),

	.AUD_ADCDAT					(AUD_ADCDAT),

	// Bidirectionals
	.AUD_BCLK					(AUD_BCLK),
	.AUD_ADCLRCK				(AUD_ADCLRCK),
	.AUD_DACLRCK				(AUD_DACLRCK),

	// Outputs
	.audio_in_available			(audio_in_available),
	.left_channel_audio_in		(left_channel_audio_in),
	.right_channel_audio_in		(right_channel_audio_in),

	.audio_out_allowed			(audio_out_allowed),

	.AUD_XCK					(AUD_XCK),
	.AUD_DACDAT					(AUD_DACDAT)
);

avconf #(.USE_MIC_INPUT(1)) avc (
	.FPGA_I2C_SCLK				(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT				(FPGA_I2C_SDAT),
	.CLOCK_50					(clk),
	.reset						(~rst)
);
	
// Memory 64 bits wide for L and R with 64K (65536) spots
// Used purely as ROM (wren tied low)
mem64K mem1(
	.address	(mem_address),
	.clock		(clk),
	.data		({left_channel_audio_in, right_channel_audio_in}), // unused for ROM
	.wren		(1'b0),  // no recording
	.q			({left_sample_q, right_sample_q})
	);

endmodule
