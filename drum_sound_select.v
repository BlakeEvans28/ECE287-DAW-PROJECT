module drum_sound_select (
    input  wire clk,
    input  wire rst,
    input  wire key,    // KEY[7]

    output reg kick,
    output reg snare,
    output reg hat,
    output reg chip
);

    reg [2:0] S, NS;

    parameter  KICK       = 3'd0,
               KICK_WAIT  = 3'd1,
               SNARE      = 3'd2,
               SNARE_WAIT = 3'd3,
               HAT        = 3'd4,
               HAT_WAIT   = 3'd5,
               CHIP       = 3'd6,
               CHIP_WAIT  = 3'd7;


    always @(posedge clk or negedge rst)
    begin
        if (!rst)
            S <= KICK;
        else
            S <= NS;
    end


    always @(*)
    begin
        case (S)
            KICK:
                if (!key)
                    NS = KICK_WAIT;
                else
                    NS = KICK;

            KICK_WAIT:
                if (key)
                    NS = SNARE;
                else
                    NS = KICK_WAIT;

            SNARE:
                if (!key)
                    NS = SNARE_WAIT;
                else
                    NS = SNARE;

            SNARE_WAIT:
                if (key)
                    NS = HAT;
                else
                    NS = SNARE_WAIT;

            HAT:
                if (!key)
                    NS = HAT_WAIT;
                else
                    NS = HAT;

            HAT_WAIT:
                if (key)
                    NS = CHIP;
                else
                    NS = HAT_WAIT;

            CHIP:
                if (!key)
                    NS = CHIP_WAIT;
                else
                    NS = CHIP;

            CHIP_WAIT:
                if (key)
                    NS = KICK;
                else
                    NS = CHIP_WAIT;

            default:
                NS = KICK;
        endcase
    end

    always @(posedge clk or negedge rst)
    begin
        if (!rst)
        begin
            kick  <= 1'b1;
            snare <= 1'b0;
            hat   <= 1'b0;
            chip  <= 1'b0;
        end
        else
        begin
            case (NS)
                KICK_WAIT:
                begin
                    kick  <= 1'b1;
                    snare <= 1'b0;
                    hat   <= 1'b0;
                    chip  <= 1'b0;
                end

                SNARE_WAIT:
                begin
                    kick  <= 1'b0;
                    snare <= 1'b1;
                    hat   <= 1'b0;
                    chip  <= 1'b0;
                end

                HAT_WAIT:
                begin
                    kick  <= 1'b0;
                    snare <= 1'b0;
                    hat   <= 1'b1;
                    chip  <= 1'b0;
                end

                CHIP_WAIT:
                begin
                    kick  <= 1'b0;
                    snare <= 1'b0;
                    hat   <= 1'b0;
                    chip  <= 1'b1;
                end
            endcase
        end
    end

endmodule
