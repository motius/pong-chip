module pong (input clk,
`ifdef USE_POWER_PINS
            inout vccd1, // User area 1.8V supply
            inout vssd1, // User area 1 digital ground
`endif
            input reset,
            input game_reset,
            inout sda,
            inout scl,
            output hsync,
            output vsync,
            output [3:0] red,
            output [3:0] green,
            output [3:0] blue,
            output wire [15:0] io_oeb
);
    assign io_oeb = 16'h0000;
    wire clk_25;
    wire active_pixels;
    wire [9:0] counter_x;
    wire [9:0] counter_y;
    
    ClockDividerPow #(1) clk25MHz(
        .clk(clk), 
        .clk_out(clk_25)
    );
    
    wire led_clock;
    ClockDividerPow #(20) status_led(
        .clk(clk), 
        .clk_out(led_clock)
    );
    
    HVSync hvsync(
        .clk_vga(clk_25),
        .reset(reset),
        .hsync(hsync),
        .vsync(vsync),
        .counter_x(counter_x),
        .counter_y(counter_y),
        .active_pixels(active_pixels)
    );
    
    wire [9:0] platform_pos;
    wire [15:0] range;
    
    reg set_up_and_run;
    wire error;
    wire max_platform_pos;

    assign platform_pos = ((range - 45)/2) & 10'h3_ff;

    vl53l0x_driver i2c_driver(
        .clk(clk),
        .rst(reset),  
        .setup_and_run(game_reset),        
        .error(error),
        .range(range),
        .sda(sda),
        .scl(scl)
    );

    GameEngine pong(
        .clk(clk),
        .clk_vga(clk_25),
        .clk_input(led_clock),
        .reset(game_reset),
        .active_pixels(active_pixels),
        .counter_x(counter_x),
        .counter_y(counter_y),
        .position(platform_pos),
        .max_platform_pos(max_platform_pos),
        .red(red), 
        .green(green),
        .blue(blue)
    );
    
endmodule