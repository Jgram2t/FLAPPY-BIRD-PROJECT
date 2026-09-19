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

    // ============================================================
    // 640 x 480 VGA @ approximately 60 Hz
    // ============================================================

    localparam H_DISPLAY = 640;
    localparam H_FRONT   = 16;
    localparam H_SYNC    = 96;
    localparam H_BACK    = 48;

    localparam H_TOTAL   = 800;

    localparam V_DISPLAY = 480;
    localparam V_FRONT   = 10;
    localparam V_SYNC    = 2;
    localparam V_BACK    = 33;

    localparam V_TOTAL   = 525;


    // ============================================================
    // Counters
    // ============================================================

    reg [9:0] h_count;
    reg [9:0] v_count;


    always @(posedge clk or posedge reset) begin

        if (reset) begin

            h_count <= 10'd0;
            v_count <= 10'd0;

        end else begin

            if (h_count == 10'd799) begin

                h_count <= 10'd0;

                if (v_count == 10'd524)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;

            end else begin

                h_count <= h_count + 10'd1;

            end

        end

    end


    // ============================================================
    // Current pixel position
    // ============================================================

    assign hpos = h_count;
    assign vpos = v_count;


    // ============================================================
    // Visible area
    // ============================================================

    assign display_on =
        (h_count < H_DISPLAY) &&
        (v_count < V_DISPLAY);


    // ============================================================
    // Horizontal sync
    //
    // 640 visible
    // 16 front porch
    // 96 sync
    // 48 back porch
    //
    // Sync is active LOW.
    // ============================================================

    assign hsync =
        !(
            (h_count >= 10'd656) &&
            (h_count <  10'd752)
        );


    // ============================================================
    // Vertical sync
    //
    // 480 visible
    // 10 front porch
    // 2 sync
    // 33 back porch
    //
    // Sync is active LOW.
    // ============================================================

    assign vsync =
        !(
            (v_count >= 10'd490) &&
            (v_count <  10'd492)
        );

endmodule
