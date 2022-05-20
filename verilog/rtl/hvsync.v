module HVSync (input clk_vga,
               input reset,
               output hsync,
               output vsync,
               output active_pixels,
               output reg [9:0] counter_x,
               output reg [9:0] counter_y);
    
    // horizontal timings
    parameter WIDTH    = 640;
    parameter H_FPORCH = 16;
    parameter H_SYNC   = 96;
    parameter H_BPORCH = 48;
    
    parameter H_TOTAL      = WIDTH + H_FPORCH + H_SYNC + H_BPORCH;
    parameter H_MIN_ACTIVE = H_SYNC + H_BPORCH;
    parameter H_MAX_ACTIVE = H_SYNC + H_BPORCH + WIDTH;
    
    // vertical timings
    parameter HEIGHT = 480;
    parameter V_FPORCH = 10;
    parameter V_SYNC   = 2;
    parameter V_BPORCH = 33;
    
    parameter V_TOTAL  = HEIGHT + V_FPORCH + V_SYNC + V_BPORCH;
    
    parameter V_MIN_ACTIVE = V_SYNC + V_BPORCH;
    parameter V_MAX_ACTIVE = V_SYNC + V_BPORCH + HEIGHT;
    
    wire res_counter_x = reset || (counter_x == H_TOTAL - 1);
    wire res_counter_y = reset || (counter_y == V_TOTAL - 1);
    
    
    always @(posedge clk_vga)
        if (res_counter_x)
            counter_x <= 0;
        else
            counter_x <= counter_x + 1;
    
    always @(posedge clk_vga)
    begin
        if (res_counter_x)
        begin
            if (res_counter_y)
                counter_y <= 0;
            else
                counter_y <= counter_y + 1;
        end
    end
    
    assign hsync       = (counter_x >= H_SYNC);
    assign vsync       = (counter_y >= V_SYNC);
    assign active_pixels = (counter_x >= H_MIN_ACTIVE && counter_x < H_MAX_ACTIVE) && (counter_y >= V_MIN_ACTIVE && counter_y < V_MAX_ACTIVE);
    
    
endmodule