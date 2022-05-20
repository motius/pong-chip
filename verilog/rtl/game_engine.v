module GameEngine(input clk,
                  input clk_vga,
                  input clk_input,
                  input reset,
                  input active_pixels,
                  input [9:0] counter_x,
                  input [9:0] counter_y,
                  input [9:0] position,
                  output max_platform_pos,
                  output reg [3:0] red,
                  output reg [3:0] green,
                  output reg [3:0] blue);
    
    
    // horizontal timings
    parameter WIDTH    = 640;
    parameter H_FPORCH = 16;
    parameter H_SYNC   = 96;
    parameter H_BPORCH = 48;
    
    // vertical timings
    parameter HEIGHT   = 480;
    parameter V_FPORCH = 10;
    parameter V_SYNC   = 2;
    parameter V_BPORCH = 33;
    
    parameter H_START = H_SYNC + H_BPORCH;
    parameter V_START = V_SYNC + V_BPORCH;
    
    parameter COLOR_BACKGROUND = 12'hFFF;
    parameter COLOR_BORDER     = 12'h40A;
    parameter COLOR_PLATFORM   = 12'hF00;
    parameter COLOR_BALL       = 12'hA09;
    parameter COLOR_LOST       = 12'h0F0;

    parameter BORDER = 10;
    
    parameter P_HEIGHT = 30;
    parameter P_MIN_H = HEIGHT - BORDER - P_HEIGHT;
    parameter P_MAX_H = HEIGHT - BORDER;
    
    parameter P_MIN_X = BORDER;
    parameter P_WIDTH_MAX = 150;
    parameter P_WIDTH_MIN = 20;
    parameter P_REDUCT = 4;

    
    reg[7:0] p_width = P_WIDTH_MAX;    
    assign max_platform_pos = (position + p_width) >= WIDTH - BORDER;

    // BALL PARAMETERS
    parameter B_MAX_Y = P_MIN_H;
    parameter B_MIN_X = BORDER;
    parameter B_MAX_X = WIDTH - BORDER;
    parameter B_SIZE  = 20;
    
    reg [9:0] b_pos_x = B_MIN_X;
    reg [9:0] b_pos_y = BORDER;
    reg [12:0] random_counter;
    
    wire [9:0] pix_x;
    wire [9:0] pix_y;
    
    assign pix_x = counter_x - H_START;
    assign pix_y = counter_y - V_START;

    /// 
    reg b_going_up    = 1;
    reg b_going_right = 1;
    reg in_play = 1;
    reg [3:0] b_speed = 5;

    // Assings for conditions

    wire in_platform;
    wire in_ball;
    wire in_border;

    assign in_platform = pix_x > position && pix_x < position + p_width && pix_y < P_MAX_H && pix_y > P_MIN_H;
    assign in_ball = pix_x > b_pos_x && pix_x < b_pos_x + B_SIZE && pix_y > b_pos_y && pix_y < b_pos_y + B_SIZE;
    assign in_border = pix_x < BORDER || pix_y < BORDER || pix_x > WIDTH - BORDER;

    // This sends the VGA values
    always @(posedge clk_vga) begin
        if (~active_pixels) begin
            {red[3:0], green[3:0], blue[3:0]} <= 0;
        end else if (~in_play) begin
            {red[3:0], green[3:0], blue[3:0]} <= {pix_x[9:6] + random_counter[8:5], pix_x[9:6] + random_counter[9:6], pix_y[9:6] + random_counter[9:6]};
        end else if (in_border) begin
            {red[3:0], green[3:0], blue[3:0]} <= COLOR_BORDER;
        end else if (in_ball) begin
            {red[3:0], green[3:0], blue[3:0]} <= COLOR_BALL;
        end else if (in_platform) begin
            {red[3:0], green[3:0], blue[3:0]} <= COLOR_PLATFORM;
        end else begin
            {red[3:0], green[3:0], blue[3:0]} <= COLOR_BACKGROUND;
        end
    end
    
    parameter P_JUMP = 4;
    
    always @ (posedge clk_input) begin
        random_counter <= random_counter + 1;
        if (reset) begin
            in_play <= 1;
            b_going_up <= 0;
            b_going_right <= 0;
            p_width <= P_WIDTH_MAX;
            b_pos_x <= B_MIN_X + random_counter[7:0];
            b_pos_y <= BORDER + random_counter[7:0];
            b_speed <= 5;
        end else begin
            if (b_going_up) begin
                if (b_pos_y <= B_MAX_Y - b_speed - B_SIZE) begin
                    b_pos_y <= b_pos_y + b_speed;
                end else begin
                    if (position > b_pos_x + B_SIZE || position + p_width < b_pos_x) begin
                        in_play <= 0;
                        b_pos_y <= b_pos_y + b_speed;    
                    end else begin
                        b_going_up <= 0;
                    	b_speed <= b_speed + 1;
                        b_pos_y <= P_MIN_H - B_SIZE;
                        if (p_width > P_WIDTH_MIN) begin
                            p_width <= p_width - P_REDUCT;
                        end
                    end
                    
                end 
            end else begin
                if (b_pos_y > BORDER + b_speed) begin
                    b_pos_y <= b_pos_y - b_speed;
                end else begin
                    b_going_up <= 1;
                    b_pos_y <= BORDER;
                end
            end


            if (b_going_right) begin
                if (b_pos_x <= B_MAX_X - b_speed - B_SIZE) begin
                    b_pos_x <= b_pos_x + b_speed;
                end else begin
                    b_going_right <= 0;
                    b_pos_x <= B_MAX_X - B_SIZE;
                end 
            end else begin
                if (b_pos_x > B_MIN_X + b_speed) begin
                    b_pos_x <= b_pos_x - b_speed;
                    end else begin
                    b_going_right <= 1;
                    b_pos_x <= B_MIN_X;
                end
            end
        end
    end
    
endmodule