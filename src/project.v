`default_nettype none

module tt_um_dice_roller (
    input wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input wire ena,
    input wire clk,
    input wire rst_n
);
    // Disable unused bidirectional pins
    assign uio_out = 8'b0;
    assign uio_oe = 8'b0;

    // 2-Stage Button Synchronizer (prevents metastability)
    reg btn_sync_0, btn_sync_1;
    always @(posedge clk) begin
        if (!rst_n) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= ui_in[0];
            btn_sync_1 <= btn_sync_0;
        end
    end
    wire roll_btn = btn_sync_1;

    // 8-Bit LFSR for pseudo-randomness in "dice rolling"
    // using function x^8 + x^6 + x^5 + x^4 + 1
    reg [7:0] lfsr;
    always @(posedge clk) begin
        if (!rst_n)
            lfsr <= 8'hA5;
        else
            lfsr <= {lfsr[6:0], lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3]};
    end

    // Roll slowdown timer and chime sound effects
    reg [19:0] step_timer;
    reg [19:0] step_threshold;
    reg [2:0] dice_val;
    reg [17:0] sound_timer;
    reg [15:0] tone_period;

    localparam STATE_IDLE = 2'd0;
    localparam STATE_ROLLING = 2'd1;
    localparam STATE_LANDED = 2'd2;
    reg [1:0] state;

    always @(posedge clk) begin
        if (!rst_n) begin
            step_timer <= 20'd0;
            step_threshold <= 20'hFFFFF;
            dice_val <= 3'd1;
            sound_timer <= 18'd0;
            tone_period <= 16'd10_000;
            state <= STATE_IDLE;
        end else begin
            if (sound_timer > 18'd0)
                sound_timer <= sound_timer - 18'd1;
            if (roll_btn) begin // if button held fast spin and arcarde blip
                state <= STATE_ROLLING;
                step_threshold <= 20'd40_000;
                step_timer <= step_timer + 20'd1;

                if (step_timer >= 20'd40_000) begin
                    step_timer <= 20'd0;
                    dice_val <= (lfsr[2:0] >= 3'd6) ? (lfsr[2:0] - 3'd5) : (lfsr[2:0] + 3'd1);
                    sound_timer <= 18'd120_000;
                    tone_period <= 16'd12_000;
                end
            end else if (state == STATE_ROLLING) begin
                // When button released, expoential slowdown (+25% delay per step)
                if (step_threshold < 20'hE0000) begin
                    step_timer <= step_timer + 20'd1;
                    if (step_timer >= step_threshold) begin
                        step_timer <= 20'd0;
                        dice_val <= (lfsr[2:0] >= 3'd6) ? (lfsr[2:0] - 3'd5) : (lfsr[2:0] + 3'd1);
                        step_threshold <= step_threshold + (step_threshold >> 2);
                        sound_timer <= 18'd150_000;
                        tone_period <= tone_period + 16'd1_500;
                    end
                end else begin
                    // After stopping "rolling" play high-pitcher landing chime (~880 Hz at 10 MHz)
                    state <= STATE_LANDED;
                    sound_timer <= 18'd250_000;
                    tone_period <= 16'd5_680;
                end
            end
        end
    end

    // Square-wave buzzer tone generator
    reg [15:0] tone_counter;
    reg buzzer_out;

    always @(posedge clk) begin
        if (!rst_n || sound_timer == 18'd0) begin
            tone_counter <= 16'd0;
            buzzer_out <= 1'b0;
        end else if (tone_counter >= tone_period) begin
            tone_counter <= 16'd0;
            buzzer_out <= ~buzzer_out;
        end else begin
            tone_counter <= tone_counter + 16'd1;
        end
    end

    // 7-Segemnt display decoder (ie f. e. d. c. b. a)
    reg [6:0] seg;
    always @(*) begin
        case (dice_val)
            3'd1: seg = 7'b0000110;
            3'd2: seg = 7'b1011011;
            3'd3: seg = 7'b1001111;
            3'd4: seg = 7'b1100110;
            3'd5: seg = 7'b1101101;
            3'd6: seg = 7'b1111101;
            default: seg = 7'b0000000;
        endcase
    end

    // Map buzzer to bit 7 and 7-segment display to bits 6:0
    assign uo_out = {buzzer_out, seg};

    // Suppress unused input lint warnings
    wire _unused = &{ena, ui_in[7:1], uio_in, 1'b0};

endmodule
            
                    
                  
                    
                    
                
    






    
            
