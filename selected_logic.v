module selected_logic(
    input  clk,
    input  rst,
    input  select_n, // KEY[1]
    input  menu,
    input  drum,
    input  synth,
    input  demo,
    output reg menu_s,
    output reg drum_s,
    output reg synth_s,
    output reg demo_s
);

    reg select_n_d;

    always @(posedge clk or negedge rst) begin
        if (!rst)
            select_n_d <= 1'b1;
        else
            select_n_d <= select_n;
    end

    wire select_press = (select_n_d == 1'b1) && (select_n == 1'b0);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            menu_s  <= 1'b0;
            drum_s  <= 1'b0;
            synth_s <= 1'b0;
            demo_s  <= 1'b0;
        end
        else if (select_press) begin
            menu_s  <= menu;
            drum_s  <= drum;
            synth_s <= synth;
            demo_s  <= demo;
        end
    end

endmodule
