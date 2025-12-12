module bpm_logic(
    input clk,
    input rst,
    input toggle, // SW[1]
    input inc,    // KEY[0]
    output reg [7:0] bpm // up to 256 BPM
);

    reg [1:0] S, NS;

    parameter IDLE  = 2'd0,
              PRESS = 2'd1,
              WAIT  = 2'd2;

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
            IDLE:
                if (inc == 1'b0)
                    NS = PRESS;
                else
                    NS = IDLE;

            PRESS:
                NS = WAIT;

            WAIT:
                if (inc == 1'b1)
                    NS = IDLE;
                else
                    NS = WAIT;
        endcase
    end
	 
reg initialized = 1'b0;

always @(posedge clk)
begin
    // One-time init
    if (!initialized) begin
        bpm <= 8'd120;
        initialized <= 1'b1;
    end
    else begin
        case (S)
            IDLE: bpm <= bpm;

            PRESS:
                if (toggle == 1'b1) begin
                    if (bpm < 8'd200)
                        bpm <= bpm + 8'd5;
                end else begin
                    if (bpm > 8'd5)
                        bpm <= bpm - 8'd5;
                end

            WAIT: bpm <= bpm;
        endcase
    end
end


endmodule
