module ClockDividerPow(input clk,
                       output clk_out);
    parameter POW2DIV = 2;

    reg [POW2DIV:0] counter = 0;
    
    always @ (posedge clk)
    begin
        counter <= counter + 1;
    end
    
    assign clk_out = counter[POW2DIV];
    
endmodule
