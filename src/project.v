`default_nettype none

module tt_um_vga_example (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire ena,
    input  wire clk,
    input  wire rst_n
);

    // ============================================================
    // VGA SIGNALS
    // ============================================================

    wire hsync;
    wire vsync;
    wire display_on;

    wire [9:0] hpos;
    wire [9:0] vpos;

    hvsync_generator hvsync_gen (
        .clk(clk),
        .reset(~rst_n),
        .hsync(hsync),
        .vsync(vsync),
        .display_on(display_on),
        .hpos(hpos),
        .vpos(vpos)
    );


    // ============================================================
    // INPUT
    // ui_in[0] = FLAP / JUMP
    // ============================================================

    wire flap = ui_in[0];

    reg flap_previous;
    reg flap_pending;

    wire flap_pressed;

    assign flap_pressed = flap & ~flap_previous;


    // ============================================================
    // GAME VARIABLES
    // ============================================================

    reg signed [10:0] bird_y;
    reg signed [7:0] bird_velocity;

    reg signed [10:0] pipe_x;

    reg [9:0] pipe_gap_y;

    reg game_over;


    // ============================================================
    // GAME CONSTANTS
    // ============================================================

    localparam BIRD_X = 120;

    localparam BIRD_SIZE = 12;

    localparam PIPE_WIDTH = 50;

    localparam PIPE_GAP = 150;

    localparam SCREEN_TOP = 0;
    localparam SCREEN_BOTTOM = 479;

    localparam GROUND_Y = 440;


    // ============================================================
    // INPUT LATCH
    //
    // A quick tap on ui_in[0] is remembered using flap_pending.
    // This prevents the tap from being missed between frames.
    // ============================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            flap_previous <= 1'b0;
            flap_pending <= 1'b0;

        end else begin

            flap_previous <= flap;

            // Detect a new tap
            if (flap_pressed)
                flap_pending <= 1'b1;

            // Consume the tap when the game updates
            if ((hpos == 10'd0) && (vpos == 10'd0))
                if (flap_pending)
                    flap_pending <= 1'b0;

        end

    end


    // ============================================================
    // GAME LOGIC
    // ============================================================

    always @(posedge clk or negedge rst_n) begin

        if (!rst_n) begin

            bird_y <= 220;
            bird_velocity <= 0;

            pipe_x <= 600;

            pipe_gap_y <= 220;

            game_over <= 1'b0;

        end else begin

            // Update game once every frame
            if ((hpos == 10'd0) && (vpos == 10'd0)) begin

                // ==================================================
                // GAME OVER
                // ==================================================

                if (game_over) begin

                    // Tap Input 0 to restart
                    if (flap_pending) begin

                        bird_y <= 220;
                        bird_velocity <= 0;

                        pipe_x <= 600;

                        pipe_gap_y <= 220;

                        game_over <= 1'b0;

                    end

                end else begin

                    // ==============================================
                    // FLAP
                    // ==============================================

                    if (flap_pending) begin

                        bird_velocity <= -8;

                    end else begin

                        // ==========================================
                        // GRAVITY
                        // ==========================================

                        if (bird_velocity < 7)
                            bird_velocity <= bird_velocity + 1;

                    end


                    // ==============================================
                    // BIRD MOVEMENT
                    // ==============================================

                    bird_y <= bird_y + bird_velocity;


                    // ==============================================
                    // PIPE MOVEMENT
                    // ==============================================

                    pipe_x <= pipe_x - 3;


                    // ==============================================
                    // RESET PIPE
                    // ==============================================

                    if (pipe_x < -50) begin

                        pipe_x <= 640;

                        // Simple repeating pipe positions
                        if (pipe_gap_y > 300)
                            pipe_gap_y <= 180;
                        else
                            pipe_gap_y <= pipe_gap_y + 60;

                    end


                    // ==============================================
                    // CEILING COLLISION
                    // ==============================================

                    if (bird_y <= SCREEN_TOP) begin

                        bird_y <= SCREEN_TOP;

                        game_over <= 1'b1;

                    end


                    // ==============================================
                    // GROUND COLLISION
                    // ==============================================

                    if (bird_y + BIRD_SIZE >= GROUND_Y) begin

                        bird_y <= GROUND_Y - BIRD_SIZE;

                        game_over <= 1'b1;

                    end


                    // ==============================================
                    // PIPE COLLISION
                    // ==============================================

                    if (
                        (BIRD_X + BIRD_SIZE > pipe_x) &&
                        (BIRD_X < pipe_x + PIPE_WIDTH) &&
                        (
                            (bird_y < pipe_gap_y) ||
                            (bird_y + BIRD_SIZE > pipe_gap_y + PIPE_GAP)
                        )
                    ) begin

                        game_over <= 1'b1;

                    end

                end

            end

        end

    end


    // ============================================================
    // VGA RGB
    // ============================================================

    reg [1:0] r_out;
    reg [1:0] g_out;
    reg [1:0] b_out;


    always @(*) begin

        // Default background
        r_out = 2'b00;
        g_out = 2'b10;
        b_out = 2'b11;


        if (display_on) begin

            // ====================================================
            // SKY
            // ====================================================

            r_out = 2'b00;
            g_out = 2'b10;
            b_out = 2'b11;


            // ====================================================
            // CLOUD 1
            // ====================================================

            if (
                ((hpos >= 80) && (hpos < 140) &&
                 (vpos >= 80) && (vpos < 100)) ||

                ((hpos >= 100) && (hpos < 125) &&
                 (vpos >= 65) && (vpos < 100))
            ) begin

                r_out = 2'b11;
                g_out = 2'b11;
                b_out = 2'b11;

            end


            // ====================================================
            // CLOUD 2
            // ====================================================

            if (
                ((hpos >= 400) && (hpos < 470) &&
                 (vpos >= 130) && (vpos < 150)) ||

                ((hpos >= 420) && (hpos < 450) &&
                 (vpos >= 115) && (vpos < 150))
            ) begin

                r_out = 2'b11;
                g_out = 2'b11;
                b_out = 2'b11;

            end


            // ====================================================
            // TOP PIPE
            // ====================================================

            if (
                (hpos >= pipe_x) &&
                (hpos < pipe_x + PIPE_WIDTH) &&
                (vpos < pipe_gap_y)
            ) begin

                r_out = 2'b00;
                g_out = 2'b11;
                b_out = 2'b00;

            end


            // ====================================================
            // BOTTOM PIPE
            // ====================================================

            if (
                (hpos >= pipe_x) &&
                (hpos < pipe_x + PIPE_WIDTH) &&
                (vpos >= pipe_gap_y + PIPE_GAP) &&
                (vpos < GROUND_Y)
            ) begin

                r_out = 2'b00;
                g_out = 2'b11;
                b_out = 2'b00;

            end


            // ====================================================
            // PIPE CAPS
            // ====================================================

            if (
                (hpos >= pipe_x - 5) &&
                (hpos < pipe_x + PIPE_WIDTH + 5) &&
                (vpos >= pipe_gap_y - 15) &&
                (vpos < pipe_gap_y)
            ) begin

                r_out = 2'b00;
                g_out = 2'b11;
                b_out = 2'b00;

            end


            if (
                (hpos >= pipe_x - 5) &&
                (hpos < pipe_x + PIPE_WIDTH + 5) &&
                (vpos >= pipe_gap_y + PIPE_GAP) &&
                (vpos < pipe_gap_y + PIPE_GAP + 15)
            ) begin

                r_out = 2'b00;
                g_out = 2'b11;
                b_out = 2'b00;

            end


            // ====================================================
            // BIRD BODY
            // ====================================================

            if (
                (hpos >= BIRD_X) &&
                (hpos < BIRD_X + BIRD_SIZE) &&
                (vpos >= bird_y) &&
                (vpos < bird_y + BIRD_SIZE)
            ) begin

                r_out = 2'b11;
                g_out = 2'b11;
                b_out = 2'b00;

            end


            // ====================================================
            // BIRD EYE
            // ====================================================

            if (
                (hpos >= BIRD_X + 7) &&
                (hpos < BIRD_X + 10) &&
                (vpos >= bird_y + 2) &&
                (vpos < bird_y + 5)
            ) begin

                r_out = 2'b11;
                g_out = 2'b11;
                b_out = 2'b11;

            end


            // ====================================================
            // BIRD BEAK
            // ====================================================

            if (
                (hpos >= BIRD_X + BIRD_SIZE) &&
                (hpos < BIRD_X + BIRD_SIZE + 6) &&
                (vpos >= bird_y + 5) &&
                (vpos < bird_y + 9)
            ) begin

                r_out = 2'b11;
                g_out = 2'b01;
                b_out = 2'b00;

            end


            // ====================================================
            // GROUND
            // ====================================================

            if (vpos >= GROUND_Y) begin

                r_out = 2'b11;
                g_out = 2'b10;
                b_out = 2'b00;

            end


            // ====================================================
            // GAME OVER SCREEN
            // ====================================================

            if (game_over) begin

                // Red box
                if (
                    (hpos >= 210) &&
                    (hpos < 430) &&
                    (vpos >= 200) &&
                    (vpos < 280)
                ) begin

                    r_out = 2'b11;
                    g_out = 2'b00;
                    b_out = 2'b00;

                end

                // White center
                if (
                    (hpos >= 240) &&
                    (hpos < 400) &&
                    (vpos >= 220) &&
                    (vpos < 260)
                ) begin

                    r_out = 2'b11;
                    g_out = 2'b11;
                    b_out = 2'b11;

                end

            end

        end else begin

            // Outside visible VGA area
            r_out = 2'b00;
            g_out = 2'b00;
            b_out = 2'b00;

        end

    end


    // ============================================================
    // VGA OUTPUT
    // RGB222
    // ============================================================

    assign uo_out[0] = r_out[1];
    assign uo_out[4] = r_out[0];

    assign uo_out[1] = g_out[1];
    assign uo_out[5] = g_out[0];

    assign uo_out[2] = b_out[1];
    assign uo_out[6] = b_out[0];

    assign uo_out[3] = vsync;
    assign uo_out[7] = hsync;


    // ============================================================
    // UNUSED IO
    // ============================================================

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

endmodule