`default_nettype none

module hvsync_generator (
    input wire clk,
    input wire reset,

    output wire hsync,
    output wire vsync,
    output wire display_on,

    output wire [9:0] hpos,
    output wire [9:0] vpos
);

    // 640x480 VGA timing

    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;

    localparam H_TOTAL =
        H_DISPLAY +
        H_FRONT +
        H_SYNC +
        H_BACK;


    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;

    localparam V_TOTAL =
        V_DISPLAY +
        V_FRONT +
        V_SYNC +
        V_BACK;


    reg [9:0] h_count;
    reg [9:0] v_count;


    always @(posedge clk or posedge reset) begin

        if (reset) begin

            h_count <= 0;
            v_count <= 0;

        end else begin

            if (h_count == H_TOTAL - 1) begin

                h_count <= 0;

                if (v_count == V_TOTAL - 1)
                    v_count <= 0;
                else
                    v_count <= v_count + 1;

            end else begin

                h_count <= h_count + 1;

            end

        end

    end


    assign hpos = h_count;
    assign vpos = v_count;


    assign display_on =
        (h_count < H_DISPLAY) &&
        (v_count < V_DISPLAY);


    assign hsync =
        ~(
            (h_count >= H_DISPLAY + H_FRONT) &&
            (h_count <  H_DISPLAY + H_FRONT + H_SYNC)
        );


    assign vsync =
        ~(
            (v_count >= V_DISPLAY + V_FRONT) &&
            (v_count <  V_DISPLAY + V_FRONT + V_SYNC)
        );

endmodule