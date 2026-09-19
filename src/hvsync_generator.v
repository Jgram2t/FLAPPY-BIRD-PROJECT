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
    // Combinational sync / blanking from the counters (no fudge
    // offsets here - plain, direct comparisons)
    // ============================================================

    wire hsync_comb =
        ~(
            (h_count >= H_DISPLAY + H_FRONT) &&
            (h_count <  H_DISPLAY + H_FRONT + H_SYNC)
        );

    wire vsync_comb =
        ~(
            (v_count >= V_DISPLAY + V_FRONT) &&
            (v_count <  V_DISPLAY + V_FRONT + V_SYNC)
        );

    wire display_on_comb =
        (h_count < H_DISPLAY) &&
        (v_count < V_DISPLAY);


    // ============================================================
    // Register the outputs one clock behind the counters.
    //
    // h_count and v_count update on the SAME edge at the line wrap
    // (h_count 799->0 together with v_count incrementing), so an
    // unregistered vsync can appear to change one cycle "early"
    // relative to how a testbench samples it. Registering every
    // output together (sync, blanking and position) keeps them
    // all self-consistent and gives one single, predictable
    // update point per signal.
    // ============================================================

    reg hsync_r;
    reg vsync_r;
    reg display_on_r;
    reg [9:0] hpos_r;
    reg [9:0] vpos_r;

    always @(posedge clk or posedge reset) begin

        if (reset) begin

            hsync_r      <= 1'b1;
            vsync_r      <= 1'b1;
            display_on_r <= 1'b0;
            hpos_r       <= 10'd0;
            vpos_r       <= 10'd0;

        end else begin

            hsync_r      <= hsync_comb;
            vsync_r      <= vsync_comb;
            display_on_r <= display_on_comb;
            hpos_r       <= h_count;
            vpos_r       <= v_count;

        end

    end

    assign hsync       = hsync_r;
    assign vsync       = vsync_r;
    assign display_on  = display_on_r;
    assign hpos        = hpos_r;
    assign vpos        = vpos_r;

endmodule
