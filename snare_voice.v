// snare_voice.v
module snare_voice (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trig,
    input  wire        audio_out_allowed,
    output wire [15:0] sample_l,
    output wire [15:0] sample_r,
    output wire        playing
);
    drum_voice #(
        .BASE_ADDR (16'd4096),    // snare sample start
        .SAMPLE_LEN(32'd4096)
    ) u_snare (
        .clk               (clk),
        .rst_n             (rst_n),
        .trig              (trig),
        .audio_out_allowed (audio_out_allowed),
        .sample_l          (sample_l),
        .sample_r          (sample_r),
        .playing           (playing)
    );
endmodule
