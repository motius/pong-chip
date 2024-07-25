// SPDX-FileCopyrightText: 2020 Efabless Corporation
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// SPDX-License-Identifier: Apache-2.0

`default_nettype none

`timescale 1 ns / 1 ps

module i2c_test_tb;
	reg clock;
	reg RSTB;
	reg CSB;
	reg power1, power2;
	reg power3, power4;

	reg game_reset;

	wire gpio;
	wire [37:0] mprj_io;
	wire [1:0] mprj_io_0;

	assign mprj_io[8] = game_reset;
	assign mprj_io_0 = mprj_io[31:30];
	// assign mprj_io_0 = {mprj_io[8:4],mprj_io[2:0]};

	assign mprj_io[3] = (CSB == 1'b1) ? 1'b1 : 1'bz;
	// assign mprj_io[3] = 1'b1;

	// External clock is used by default.  Make this artificially fast for the
	// simulation.  Normally this would be a slow clock and the digital PLL
	// would be the fast clock.


	pullup(mprj_io[30]);
	pullup(mprj_io[31]);

	i2c_s i2c_s(
    .scl(mprj_io[31]),
    .sda(mprj_io[30])
	);

	always #12.5 clock <= (clock === 1'b0);

	initial begin
		clock = 0;
	end

  // Start the game after setup
	initial begin
		game_reset = 1'b0;
		#400000;
		game_reset = 1'b1;
		#40
		game_reset = 1'b0;
	end

	initial begin
		$dumpfile("i2c_test.vcd");
		$dumpvars(0, test_pong_tb);

		// Repeat cycles of 1000 clock edges as needed to complete testbench
		repeat (50) begin
			repeat (1000) @(posedge clock);
			// $display("+1000 cycles");
		end
		$display("%c[1;31m",27);
		`ifdef GL
			$display ("Monitor: Timeout, Test Mega-Project IO Ports (GL) Failed");
		`else
			$display ("Monitor: Timeout, Test Mega-Project IO Ports (RTL) Failed");
		`endif
		$display("%c[0m",27);
		$finish;
	end

	initial begin
		RSTB <= 1'b0;
		CSB  <= 1'b1;		// Force CSB high
		#2000;
		RSTB <= 1'b1;	  // Release reset
		#300000;
		CSB = 1'b0;		  // CSB can be released
	end

	initial begin		  // Power-up sequence
		power1 <= 1'b0;
		power2 <= 1'b0;
		power3 <= 1'b0;
		power4 <= 1'b0;
		#100;
		power1 <= 1'b1;
		#100;
		power2 <= 1'b1;
		#100;
		power3 <= 1'b1;
		#100;
		power4 <= 1'b1;
	end

	always @(mprj_io_0) begin
		$display("MPRJ-IO-30,31 state = %b ", mprj_io_0);
	end

	wire flash_csb;
	wire flash_clk;
	wire flash_io0;
	wire flash_io1;

	wire VDD3V3;
	wire VDD1V8;
	wire VSS;
	
	assign VDD3V3 = power1;
	assign VDD1V8 = power2;
	assign VSS = 1'b0;

	caravel uut (
		.vddio	  (VDD3V3),
		.vddio_2  (VDD3V3),
		.vssio	  (VSS),
		.vssio_2  (VSS),
		.vdda	  (VDD3V3),
		.vssa	  (VSS),
		.vccd	  (VDD1V8),
		.vssd	  (VSS),
		.vdda1    (VDD3V3),
		.vdda1_2  (VDD3V3),
		.vdda2    (VDD3V3),
		.vssa1	  (VSS),
		.vssa1_2  (VSS),
		.vssa2	  (VSS),
		.vccd1	  (VDD1V8),
		.vccd2	  (VDD1V8),
		.vssd1	  (VSS),
		.vssd2	  (VSS),
		.clock    (clock),
		.gpio     (gpio),
		.mprj_io  (mprj_io),
		.flash_csb(flash_csb),
		.flash_clk(flash_clk),
		.flash_io0(flash_io0),
		.flash_io1(flash_io1),
		.resetb	  (RSTB)
	);

	spiflash #(
		.FILENAME("i2c_test.hex")
	) spiflash (
		.csb(flash_csb),
		.clk(flash_clk),
		.io0(flash_io0),
		.io1(flash_io1),
		.io2(),			// not used
		.io3()			// not used
	);

endmodule
`default_nettype wire

module i2c_s (scl, sda);
    parameter I2C_ADR = 7'b010_1001;
    input scl;
    inout sda;

    wire debug = 1'b1;
    genvar i;

    reg [7:0] mem [3:0]; // initiate memory

    initial begin
        mem[0] = 8'd00;
        mem[1] = 8'd01;
        mem[2] = 8'd02;
        mem[3] = 8'd03;
    end

    reg [7:0] mem_adr;   // memory address
    reg [7:0] mem_do;    // memory data output

    reg sta, d_sta;
    reg sto, d_sto;

    reg [7:0] sr;        // 8bit shift register
    reg       rw;        // read/write direction

    wire      my_adr;    
    wire      i2c_reset; // i2c-statemachine reset
    reg [2:0] bit_cnt;   // 3bit downcounter
    wire      acc_done;  // 8bits transfered
    reg       ld;        // load downcounter

    reg       sda_o;     // sda-drive level
    wire      sda_dly;   // delayed version of sda

    // statemachine declaration
    parameter idle        = 3'b000;
    parameter slave_ack   = 3'b001;
    parameter get_mem_adr = 3'b010;
    parameter gma_ack     = 3'b011;
    parameter data        = 3'b100;
    parameter data_ack    = 3'b101;

    reg [2:0] state; // synopsys enum_state

    //
    // module body
    //

    initial
    begin
       sda_o = 1'b1;
       state = idle;
    end

    // generate shift register
    always @(posedge scl)
      sr <= #1 {sr[6:0],sda};

    //detect my_address
    assign my_adr = (sr[7:1] == I2C_ADR);

    //generate bit-counter
    always @(posedge scl)
      if(ld)
        bit_cnt <= #1 3'b111;
      else
        bit_cnt <= #1 bit_cnt - 3'h1;

    //generate access done signal
    assign acc_done = !(|bit_cnt);

    // generate delayed version of sda
    assign #1 sda_dly = sda;


    //detect start condition
    always @(negedge sda)
      if(scl)
        begin
            sta   <= #1 1'b1;
        d_sta <= #1 1'b0;
        sto   <= #1 1'b0;

            if(debug)
              $display("DEBUG i2c_slave; start condition detected at %t", $time);
        end
      else
        sta <= #1 1'b0;

    always @(posedge scl)
      d_sta <= #1 sta;

    // detect stop condition
    always @(posedge sda)
      if(scl)
        begin
           sta <= #1 1'b0;
           sto <= #1 1'b1;

           if(debug)
             $display("DEBUG i2c_slave; stop condition detected at %t", $time);
        end
      else
        sto <= #1 1'b0;

    //generate i2c_reset signal
    assign i2c_reset = sta || sto;

    // generate statemachine
    always @(negedge scl or posedge sto)
      if (sto || (sta && !d_sta) )
        begin
            state <= #1 idle; // reset statemachine

            sda_o <= #1 1'b1;
            ld    <= #1 1'b1;
        end
      else
        begin
            // initial settings
            sda_o <= #1 1'b1;
            ld    <= #1 1'b0;

            case(state) // synopsys full_case parallel_case
                idle: // idle state
                  if (acc_done && my_adr)
                    begin
                        state <= #1 slave_ack;
                        rw <= #1 sr[0];
                        sda_o <= #1 1'b0; // generate i2c_ack

                        #2;
                        if(debug && rw)
                          $display("DEBUG i2c_slave; command byte received (read) at %t", $time);
                        if(debug && !rw)
                          $display("DEBUG i2c_slave; command byte received (write) at %t", $time);

                        if(rw)
                          begin
                              mem_do <= #1 mem[mem_adr];

                              if(debug)
                                begin
                                    #2 $display("DEBUG i2c_slave; data block read %x from address %x (1)", mem_do, mem_adr);
                                    #2 $display("DEBUG i2c_slave; memcheck [0]=%x, [1]=%x, [2]=%x", mem[4'h0], mem[4'h1], mem[4'h2]);
                                end
                          end
                    end

                slave_ack:
                  begin
                      if(rw)
                        begin
                            state <= #1 data;
                            sda_o <= #1 mem_do[7];
                        end
                      else
                        state <= #1 get_mem_adr;

                      ld    <= #1 1'b1;
                  end

                get_mem_adr: // wait for memory address
                  if(acc_done)
                    begin
                        state <= #1 gma_ack;
                        mem_adr <= #1 sr; // store memory address
                        sda_o <=  #1 !(sr <= 15); // generate i2c_ack, for valid address

                        if(debug)
                          #1 $display("DEBUG i2c_slave; address received. adr=%x, ack=%b", sr, sda_o);
                    end

                gma_ack:
                  begin
                      state <= #1 data;
                      ld    <= #1 1'b1;
                  end

                data: // receive or drive data
                  begin
                      if(rw)
                        sda_o <= #1 mem_do[7];

                      if(acc_done)
                        begin
                            state <= #1 data_ack;
                            mem_adr <= #2 mem_adr + 8'h1;
                            sda_o <= #1 (rw && (mem_adr <= 15) ); // send ack on write, receive ack on read

                            if(rw)
                              begin
                                  #3 mem_do <= mem[mem_adr];

                                  if(debug)
                                    #5 $display("DEBUG i2c_slave; data block read %x from address %x (2)", mem_do, mem_adr);
                              end

                            if(!rw)
                              begin
                                  mem[ mem_adr[3:0] ] <= #1 sr; // store data in memory

                                  if(debug)
                                    #2 $display("DEBUG i2c_slave; data block write %x to address %x", sr, mem_adr);
                              end
                        end
                  end

                data_ack:
                  begin
                      ld <= #1 1'b1;

                      if(rw)
                        if(sr[0]) // read operation && master send NACK
                          begin
                              state <= #1 idle;
                              sda_o <= #1 1'b1;
                          end
                        else
                          begin
                              state <= #1 data;
                              sda_o <= #1 mem_do[7];
                          end
                      else
                        begin
                            state <= #1 data;
                            sda_o <= #1 1'b1;
                        end
                  end

            endcase
        end

    // read data from memory
    always @(posedge scl)
      if(!acc_done && rw)
        mem_do <= #1 {mem_do[6:0], 1'b1}; // insert 1'b1 for host ack generation

    // generate tri-states
    assign sda = sda_o ? 1'bz : 1'b0;


    //
    // Timing checks
    //

    wire tst_sto = sto;
    wire tst_sta = sta;

    specify
      specparam normal_scl_low  = 4700,
                normal_scl_high = 4000,
                normal_tsu_sta  = 4700,
                normal_thd_sta  = 4000,
                normal_tsu_sto  = 4000,
                normal_tbuf     = 4700,

                fast_scl_low  = 1300,
                fast_scl_high =  600,
                fast_tsu_sta  = 1300,
                fast_thd_sta  =  600,
                fast_tsu_sto  =  600,
                fast_tbuf     = 1300;

      $width(negedge scl, normal_scl_low);  // scl low time
      $width(posedge scl, normal_scl_high); // scl high time

      $setup(posedge scl, negedge sda &&& scl, normal_tsu_sta); // setup start
      $setup(negedge sda &&& scl, negedge scl, normal_thd_sta); // hold start
      $setup(posedge scl, posedge sda &&& scl, normal_tsu_sto); // setup stop

      $setup(posedge tst_sta, posedge tst_sto, normal_tbuf); // stop to start time
    endspecify

endmodule
