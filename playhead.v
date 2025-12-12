module playhead (
    input  wire        clk,
    input  wire        rst,
    input  wire        is_playing,
    input  wire [7:0]  bpm,

    input  wire [9:0]  measure_x,
    input  wire [9:0]  measure_w,
    input  wire [9:0]  beat_spacing,

    output reg  [9:0]  playhead_x
);

    wire [7:0] safe_bpm = (bpm < 20) ? 8'd20 : bpm;

    wire [31:0] ticks_per_beat =
        (50_000_000 * 60) / safe_bpm;

    wire [31:0] ticks_per_pixel =
        ticks_per_beat / beat_spacing;

    reg [31:0] tick_counter;

    always @(posedge clk or negedge rst)
    begin
        if (!rst) begin
            playhead_x   <= measure_x;
            tick_counter <= 0;
        end
        else if (!is_playing) begin
            playhead_x   <= measure_x;
            tick_counter <= 0;
        end
        else begin
            if (tick_counter >= ticks_per_pixel) begin
                tick_counter <= 0;

                if (playhead_x < measure_x + measure_w - 1)
                    playhead_x <= playhead_x + 1;
                else
                    playhead_x <= measure_x;
            end
            else begin
                tick_counter <= tick_counter + 1;
            end
        end
    end

endmodule
