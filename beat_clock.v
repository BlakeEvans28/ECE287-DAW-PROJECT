module beat_clock(
    input  wire        clk,
    input  wire        rst,        // active-high reset
    input  wire        is_playing, // from your play/pause FSM
    input  wire [7:0]  bpm,        // from bpm_logic

    output reg         beat_pulse  // 1-cycle pulse every beat
);

    wire [7:0] safe_bpm = (bpm < 8'd20) ? 8'd20 : bpm;

    // 50MHz * 60 / BPM = ticks per beat
    wire [31:0] ticks_per_beat = (50_000_000 * 60) / safe_bpm;

    reg [31:0] counter;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            counter    <= 32'd0;
            beat_pulse <= 1'b0;
        end else if (!is_playing) begin
            counter    <= 32'd0;
            beat_pulse <= 1'b0;
        end else begin
            if (counter >= ticks_per_beat - 1) begin
                counter    <= 32'd0;
                beat_pulse <= 1'b1;   // single-cycle pulse
            end else begin
                counter    <= counter + 1'b1;
                beat_pulse <= 1'b0;
            end
        end
    end

endmodule
