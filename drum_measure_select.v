module drum_measure_select (
    input  wire clk,
    input  wire rst,
    input  wire key,    // KEY[5]

    output reg measure1,
    output reg measure2
);

    reg [1:0] S, NS;

    parameter  MEASURE1      = 2'd0,
               MEASURE1_WAIT = 2'd1,
               MEASURE2      = 2'd2,
               MEASURE2_WAIT = 2'd3;

    always @(posedge clk or negedge rst)
    begin
        if (!rst)
            S <= MEASURE1;
        else
            S <= NS;
    end

    always @(*)
    begin
        case (S)

            MEASURE1:
                if (!key)
                    NS = MEASURE1_WAIT;
                else
                    NS = MEASURE1;

            MEASURE1_WAIT:
                if (key)
                    NS = MEASURE2;
                else
                    NS = MEASURE1_WAIT;

            MEASURE2:
                if (!key)
                    NS = MEASURE2_WAIT;
                else
                    NS = MEASURE2;

            MEASURE2_WAIT:
                if (key)
                    NS = MEASURE1;
                else
                    NS = MEASURE2_WAIT;

            default:
                NS = MEASURE1;
        endcase
    end

    always @(posedge clk or negedge rst)
    begin
        if (!rst)
        begin
            measure1 <= 1'b1;
            measure2 <= 1'b0;
        end
        else
        begin
            case (NS)
                MEASURE1:
                begin
                    measure1 <= 1'b1;
                    measure2 <= 1'b0;
                end

                MEASURE2:
                begin
                    measure1 <= 1'b0;
                    measure2 <= 1'b1;
                end

                default:
                begin
                    measure1 <= 1'b1;
                    measure2 <= 1'b0;
                end
            endcase
        end
    end

endmodule
