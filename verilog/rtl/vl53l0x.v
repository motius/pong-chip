`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kevin Bello
// 
// Create Date: 31.03.2022 09:27:10
// Design Name: 
// Module Name: vl53l0x Driver
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vl53l0x_driver(

    input clk,
    input rst,
    
    input setup_and_run,        
    output reg error,
    output [15:0] range,
    inout sda,
    inout scl

    );
    
    
    localparam I2C_READ         = 1'b1;
    localparam I2C_WRITE        = 1'b0;
    
    localparam V_IDLE           = 8'h00;
    localparam V_SETUP_AND_CONT = 8'h01;
    
    
    localparam I_IDLE           = 8'h02;
    localparam I_START          = 8'h03;
    localparam I_READY          = 8'h04;
    localparam I_BUSY           = 8'h05;
    localparam I_ERROR          = 8'h06;
    
    
    //VL53L0X Parameters
    
    localparam ADDRESS_DEFAULT                             = 7'b010_1001; 
    localparam SYSRANGE_START                              = 8'h00;    
    localparam SYSTEM_THRESH_HIGH                          = 8'h0C;
    localparam SYSTEM_THRESH_LOW                           = 8'h0E;    
    localparam SYSTEM_SEQUENCE_CONFIG                      = 8'h01;
    localparam SYSTEM_RANGE_CONFIG                         = 8'h09;
    localparam SYSTEM_INTERMEASUREMENT_PERIOD              = 8'h04;    
    localparam SYSTEM_INTERRUPT_CONFIG_GPIO                = 8'h0A;    
    localparam GPIO_HV_MUX_ACTIVE_HIGH                     = 8'h84;    
    localparam SYSTEM_INTERRUPT_CLEAR                      = 8'h0B;    
    localparam RESULT_INTERRUPT_STATUS                     = 8'h13;
    localparam RESULT_RANGE_STATUS                         = 8'h14;    
    localparam RESULT_CORE_AMBIENT_WINDOW_EVENTS_RTN       = 8'hBC;
    localparam RESULT_CORE_RANGING_TOTAL_EVENTS_RTN        = 8'hC0;
    localparam RESULT_CORE_AMBIENT_WINDOW_EVENTS_REF       = 8'hD0;
    localparam RESULT_CORE_RANGING_TOTAL_EVENTS_REF        = 8'hD4;
    localparam RESULT_PEAK_SIGNAL_RATE_REF                 = 8'hB6;    
    localparam ALGO_PART_TO_PART_RANGE_OFFSET_MM           = 8'h28;    
    localparam I2C_SLAVE_DEVICE_ADDRESS                    = 8'h8A;    
    localparam MSRC_CONFIG_CONTROL                         = 8'h60;    
    localparam PRE_RANGE_CONFIG_MIN_SNR                    = 8'h27;
    localparam PRE_RANGE_CONFIG_VALID_PHASE_LOW            = 8'h56;
    localparam PRE_RANGE_CONFIG_VALID_PHASE_HIGH           = 8'h57;
    localparam PRE_RANGE_MIN_COUNT_RATE_RTN_LIMIT          = 8'h64;    
    localparam FINAL_RANGE_CONFIG_MIN_SNR                  = 8'h67;
    localparam FINAL_RANGE_CONFIG_VALID_PHASE_LOW          = 8'h47;
    localparam FINAL_RANGE_CONFIG_VALID_PHASE_HIGH         = 8'h48;
    localparam FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT = 8'h44;    
    localparam PRE_RANGE_CONFIG_SIGMA_THRESH_HI            = 8'h61;
    localparam PRE_RANGE_CONFIG_SIGMA_THRESH_LO            = 8'h62;    
    localparam PRE_RANGE_CONFIG_VCSEL_PERIOD               = 8'h50;
    localparam PRE_RANGE_CONFIG_TIMEOUT_MACROP_HI          = 8'h51;
    localparam PRE_RANGE_CONFIG_TIMEOUT_MACROP_LO          = 8'h52;    
    localparam SYSTEM_HISTOGRAM_BIN                        = 8'h81;
    localparam HISTOGRAM_CONFIG_INITIAL_PHASE_SELECT       = 8'h33;
    localparam HISTOGRAM_CONFIG_READOUT_CTRL               = 8'h55;    
    localparam FINAL_RANGE_CONFIG_VCSEL_PERIOD             = 8'h70;
    localparam FINAL_RANGE_CONFIG_TIMEOUT_MACROP_HI        = 8'h71;
    localparam FINAL_RANGE_CONFIG_TIMEOUT_MACROP_LO        = 8'h72;
    localparam CROSSTALK_COMPENSATION_PEAK_RATE_MCPS       = 8'h20;    
    localparam MSRC_CONFIG_TIMEOUT_MACROP                  = 8'h46;    
    localparam SOFT_RESET_GO2_SOFT_RESET_N                 = 8'hBF;
    localparam IDENTIFICATION_MODEL_ID                     = 8'hC0;
    localparam IDENTIFICATION_REVISION_ID                  = 8'hC2;    
    localparam OSC_CALIBRATE_VAL                           = 8'hF8;    
    localparam GLOBAL_CONFIG_VCSEL_WIDTH                   = 8'h32;
    localparam GLOBAL_CONFIG_SPAD_ENABLES_REF_0            = 8'hB0;
    localparam GLOBAL_CONFIG_SPAD_ENABLES_REF_1            = 8'hB1;
    localparam GLOBAL_CONFIG_SPAD_ENABLES_REF_2            = 8'hB2;
    localparam GLOBAL_CONFIG_SPAD_ENABLES_REF_3            = 8'hB3;
    localparam GLOBAL_CONFIG_SPAD_ENABLES_REF_4            = 8'hB4;
    localparam GLOBAL_CONFIG_SPAD_ENABLES_REF_5            = 8'hB5;    
    localparam GLOBAL_CONFIG_REF_EN_START_SELECT           = 8'hB6;
    localparam DYNAMIC_SPAD_NUM_REQUESTED_REF_SPAD         = 8'h4E;
    localparam DYNAMIC_SPAD_REF_EN_START_OFFSET            = 8'h4F;
    localparam POWER_MANAGEMENT_GO1_POWER_FORCE            = 8'h80;    
    localparam VHV_CONFIG_PAD_SCL_SDA__EXTSUP_HV           = 8'h89;    
    localparam ALGO_PHASECAL_LIM                           = 8'h30;
    localparam ALGO_PHASECAL_CONFIG_TIMEOUT                = 8'h30;
    
    
    //I2C Variables
	reg enable = 0;
	reg rw = 0;
	reg [7:0] reg_addr = 0;
    reg [6:0] device_addr = ADDRESS_DEFAULT;
    reg [15:0] divider = 16'h00F9;         
    wire [7:0] miso;
    reg [7:0] mosi = 0;
    wire busy;
    reg ready = 0;
    reg  [7:0] data_reg; 
    reg  [3:0] range_conversion;
//    assign bar = range_conversion;
    
    reg  [15:0] range_reg; 
    assign range = range_reg;
    
    
    i2c_master #(.DATA_WIDTH(8),.REG_WIDTH(8),.ADDR_WIDTH(7)) 
        i2c_master_inst(
            .i_clk(clk),
            .i_rst(rst),
            .i_enable(enable),
            .i_rw(rw),
            .i_mosi_data(mosi),
            .i_reg_addr(reg_addr),
            .i_device_addr(device_addr),
            .i_divider(divider),
            .o_miso_data(miso),
            .o_busy(busy),
            .io_sda(sda),
            .io_scl(scl)
    );
    
    reg [7:0] i2c_state = V_IDLE;
    reg [7:0] in_i2c_state = I_IDLE;
    reg [7:0] in_i2c_counter = 0;
    
    reg counter = 0;
    reg [7:0] auxi = (0.25 * (1 << 7));    
    reg [7:0] stop_variable = 0;
    
    always@(posedge clk) begin
        if(rst) begin
            i2c_state           <= V_IDLE;
            in_i2c_state        <= I_IDLE;
            in_i2c_counter      <= 0;
            ready               <= 0;
            error               <= 0;
            data_reg            <= 0;
            range_reg           <= 0;
            range_conversion    <= 0;
        end 
        else begin
        
            case(i2c_state) 
            
                V_IDLE: begin
                    
                    if (setup_and_run == 1'b1) begin
                        ready <= 0;
                        i2c_state <= V_SETUP_AND_CONT;
                    end
                    
                    
                end
                
                V_SETUP_AND_CONT: begin
                
                    case(in_i2c_state)
                        
                        
                        I_ERROR: begin                        
                            error <= 1;                     
                        end
                        
                        I_IDLE: begin               
                            in_i2c_state <= I_START;
                        end
                        
                        I_START: begin                        
                            case(in_i2c_counter)
                            //-------------------------------------------------DATA INIT
                                //Read -> IDENTIFICATION_MODEL_ID
                                0:begin                  
                                    ready               <= 0;        
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= IDENTIFICATION_MODEL_ID;
                                    in_i2c_state        <= I_READY;
                                end
                                //switch to 2V8 mode
                                //Read -> VHV_CONFIG_PAD_SCL_SDA__EXTSUP_HV 
                                1:begin                        
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= VHV_CONFIG_PAD_SCL_SDA__EXTSUP_HV;
                                    in_i2c_state        <= I_READY;
                                end
                                //Write -> VHV_CONFIG_PAD_SCL_SDA__EXTSUP_HV
                                2:begin            
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= (data_reg | 8'h01);
                                    reg_addr            <= VHV_CONFIG_PAD_SCL_SDA__EXTSUP_HV;
                                    in_i2c_state        <= I_READY;
                                end 
                                //Set I2C standard mode
                                3:begin            
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= 8'h88;
                                    in_i2c_state        <= I_READY;
                                end  
                                4:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= 8'h80;
                                    in_i2c_state        <= I_READY;
                                end
                                5:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= 8'hFF;
                                    in_i2c_state        <= I_READY;
                                end
                                6:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= 8'h00;
                                    in_i2c_state        <= I_READY;
                                end
                                7:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= 8'h91;
                                    in_i2c_state        <= I_READY;
                                end
                                8:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= 8'h00;
                                    in_i2c_state        <= I_READY;
                                end
                                9:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= 8'hFF;
                                    in_i2c_state        <= I_READY;
                                end
                                10:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= 8'h80;
                                    in_i2c_state        <= I_READY;
                                end
                                
                                // disable SIGNAL_RATE_MSRC (bit 1) and SIGNAL_RATE_PRE_RANGE (bit 4) limit checks
                                //Read -> MSRC_CONFIG_CONTROL
                                11:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= MSRC_CONFIG_CONTROL;
                                    in_i2c_state        <= I_READY;
                                end                                
                                //Write -> MSRC_CONFIG_CONTROL
                                12:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= (data_reg | 8'h12);
                                    reg_addr            <= MSRC_CONFIG_CONTROL;
                                    in_i2c_state        <= I_READY;                                
                                end
                                // set final range signal rate limit to 0.25 MCPS (million counts per second)
                                // Write -> FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT 
                                13:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= ((auxi >> 8) & 8'hFF);
                                    reg_addr            <= FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT;
                                    in_i2c_state        <= I_READY;                                 
                                end                                
                                // Write -> FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT 
                                14:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= (auxi & 8'hFF);
                                    reg_addr            <= FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT + 1;
                                    in_i2c_state        <= I_READY; 
                                
                                end                                
                                // Write -> SYSTEM_SEQUENCE_CONFIG 
                                15:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'hFF;
                                    reg_addr            <= SYSTEM_SEQUENCE_CONFIG;
                                    in_i2c_state        <= I_READY;                                 
                                end
                                
                            //-------------------------------------------------------
                              
                                /*
                                
                                POSSIBILITY TO INSERT STATIC INT!
                                
                                */
                                // Set interrupt config to new sample ready
                                // Write -> SYSTEM_INTERRUPT_CONFIG_GPIO
                                16:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h04;
                                    reg_addr            <= SYSTEM_INTERRUPT_CONFIG_GPIO;
                                    in_i2c_state        <= I_READY;                                
                                end
                                // READ -> GPIO_HV_MUX_ACTIVE_HIGH
                                17:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= GPIO_HV_MUX_ACTIVE_HIGH;
                                    in_i2c_state        <= I_READY;                                
                                end
                                // Write -> GPIO_HV_MUX_ACTIVE_HIGH
                                18:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= (data_reg & ~(8'h10));
                                    reg_addr            <= GPIO_HV_MUX_ACTIVE_HIGH;
                                    in_i2c_state        <= I_READY;                                
                                end
                                // Write -> SYSTEM_INTERRUPT_CLEAR
                                19:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= SYSTEM_INTERRUPT_CLEAR;
                                    in_i2c_state        <= I_READY;                                
                                end
                                // Write -> SYSTEM_SEQUENCE_CONFIG (SetSequenceStepEnable)
                                20:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'hE8;
                                    reg_addr            <= SYSTEM_SEQUENCE_CONFIG;
                                    in_i2c_state        <= I_READY;                                
                                end
                            
                            //------------------------------------PERFORM CALIBRATION
                                
                                // Write -> SYSTEM_SEQUENCE_CONFIG (vhv_calibration)
                                21:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= SYSTEM_SEQUENCE_CONFIG;
                                    in_i2c_state        <= I_READY;                                
                                end                                
                                // Write -> SYSRANGE_START
                                22:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= (8'h01 | 8'h40);
                                    reg_addr            <= SYSRANGE_START;
                                    in_i2c_state        <= I_READY;
                                
                                end
                                // Read -> RESULT_INTERRUPT_STATUS
                                23:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= RESULT_INTERRUPT_STATUS;
                                    in_i2c_state        <= I_READY;                                
                                end
                                // Write -> SYSTEM_INTERRUPT_CLEAR                                
                                24:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= SYSTEM_INTERRUPT_CLEAR;
                                    in_i2c_state        <= I_READY;
                                
                                end
                                // Write -> SYSRANGE_START                                
                                25:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= SYSRANGE_START;
                                    in_i2c_state        <= I_READY;                                
                                end
                                // Write -> SYSTEM_SEQUENCE_CONFIG (phase_calibration)
                                26:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h02;
                                    reg_addr            <= SYSTEM_SEQUENCE_CONFIG;
                                    in_i2c_state        <= I_READY;                                 
                                end      
                                // Write -> SYSRANGE_START
                                27:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= (8'h01 | 8'h00);
                                    reg_addr            <= SYSRANGE_START;
                                    in_i2c_state        <= I_READY;
                                end
                                // Read -> RESULT_INTERRUPT_STATUS
                                28:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= RESULT_INTERRUPT_STATUS;
                                    in_i2c_state        <= I_READY; 
                                end
                                // Write -> SYSTEM_INTERRUPT_CLEAR  
                                29:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= SYSTEM_INTERRUPT_CLEAR;
                                    in_i2c_state        <= I_READY;
                                end
                                // Write -> SYSRANGE_START
                                30:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= SYSRANGE_START;
                                    in_i2c_state        <= I_READY;  
                                end
                                // Write -> SYSTEM_SEQUENCE_CONFIG (restore the previous Sequence Config)
                                31:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'hE8;
                                    reg_addr            <= SYSTEM_SEQUENCE_CONFIG;
                                    in_i2c_state        <= I_READY;
                                end
                                
                            //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>START CONTINUOUS MODE!
                            
                                //I2C 
                                32:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= 8'h80;
                                    in_i2c_state        <= I_READY;
                                end
                                33:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= 8'hFF;
                                    in_i2c_state        <= I_READY;
                                end
                                34:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= 8'h00;
                                    in_i2c_state        <= I_READY;
                                end
                                35:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= stop_variable;
                                    reg_addr            <= 8'h91;
                                    in_i2c_state        <= I_READY;
                                end
                                36:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= 8'h00;
                                    in_i2c_state        <= I_READY;
                                end
                                37:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= 8'hFF;
                                    in_i2c_state        <= I_READY;
                                end
                                38:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h00;
                                    reg_addr            <= 8'h80;
                                    in_i2c_state        <= I_READY;
                                end
                            
                                // Write -> SYSRANGE_START (VL53L0X_REG_SYSRANGE_MODE_BACKTOBACK)
                                39:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h02;
                                    reg_addr            <= SYSRANGE_START;
                                    in_i2c_state        <= I_READY; 
                                end
                                // Read -> RESULT_INTERRUPT_STATUS
                                40:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= RESULT_INTERRUPT_STATUS;
                                    in_i2c_state        <= I_READY;
                                end
                                // assumptions: - Linearity Corrective Gain is 1000 (default);
                                //              - fractional ranging is not enabled
                                // Read -> RESULT_RANGE_STATUS + 10
                                41:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= (RESULT_RANGE_STATUS + 10);
                                    in_i2c_state        <= I_READY;
                                end
                                // Read -> RESULT_RANGE_STATUS + 11
                                42:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_READ;
                                    mosi                <= 0;
                                    reg_addr            <= (RESULT_RANGE_STATUS + 11);
                                    in_i2c_state        <= I_READY;
                                end
                                // Write -> SYSTEM_INTERRUPT_CLEAR
                                43:begin
                                    ready               <= 0;            
                                    rw                  <= I2C_WRITE;
                                    mosi                <= 8'h01;
                                    reg_addr            <= SYSTEM_INTERRUPT_CLEAR;
                                    in_i2c_state        <= I_READY;
                                end
                           
                                
                                
                            //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                            endcase
                        end
                        
                        I_READY: begin                        
                            if (!busy && enable == 0) begin
                                enable <= 1;
                            end else if (busy && enable == 1) begin
                                enable <= 0;
                                in_i2c_state <= I_BUSY;
                            end       
                        end
                        
                        I_BUSY: begin                     

                            case(in_i2c_counter)
                            //-------------------------------------------------DATA INIT                            
                                //Read -> IDENTIFICATION_MODEL_ID
                                0:begin                       
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= miso[7:0];
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        if (miso[7:0] != 8'hEE) begin
                                            in_i2c_state <= I_ERROR;                                            
                                        end else begin
                                            in_i2c_state <= I_START;
                                        end
                                    end
                                end
                                //switch to 2V8 mode
                                //Read -> VHV_CONFIG_PAD_SCL_SDA__EXTSUP_HV 
                                1:begin                        
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= miso[7:0];
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                //Write -> VHV_CONFIG_PAD_SCL_SDA__EXTSUP_HV
                                2:begin                 
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end    
                                //Set I2C standard mode
                                3:begin                
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                4:begin                
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                5:begin                
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                6:begin               
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                7:begin                       
                                    if (!busy) begin
                                        ready <= 1;
                                        stop_variable <= miso[7:0];
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                8:begin             
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                9:begin             
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                10:begin             
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end                         
                                // disable SIGNAL_RATE_MSRC (bit 1) and SIGNAL_RATE_PRE_RANGE (bit 4) limit checks
                                //Read -> MSRC_CONFIG_CONTROL
                                11:begin                     
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= miso[7:0];
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                //Write -> MSRC_CONFIG_CONTROL                                
                                12:begin                
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end                                
                                end
                                // set final range signal rate limit to 0.25 MCPS (million counts per second)
                                // Write -> FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT                                
                                13:begin                                              
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end   
                                end                                
                                // Write -> FINAL_RANGE_CONFIG_MIN_COUNT_RATE_RTN_LIMIT 
                                14:begin              
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end                                   
                                end
                                // Write -> SYSTEM_SEQUENCE_CONFIG                                 
                                15:begin           
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end                                  
                                end
                            //-------------------------------------------------------
                            
                                /*
                                
                                POSSIBILITY TO INSERT STATIC INT!
                                
                                */
                                
                                
                                
                                
                                
                                // Set interrupt config to new sample ready
                                // Write -> SYSTEM_INTERRUPT_CONFIG_GPIO
                                16:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end 
                                end
                                // READ -> GPIO_HV_MUX_ACTIVE_HIGH
                                17:begin          
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= miso[7:0];
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end 
                                // Write -> GPIO_HV_MUX_ACTIVE_HIGH
                                18:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end 
                                end
                                // Write -> SYSTEM_INTERRUPT_CLEAR
                                19:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end 
                                end
                                // Write -> SYSTEM_SEQUENCE_CONFIG (SetSequenceStepEnable)
                                20:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end  
                                end
                            
                            //------------------------------------PERFORM CALIBRATION
                                
                                // Write -> SYSTEM_SEQUENCE_CONFIG (vhv_calibration)
                                21:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end                                  
                                end                                
                                // Write -> SYSRANGE_START
                                22:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end                                   
                                end                                
                                // Read -> RESULT_INTERRUPT_STATUS
                                23:begin                     
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= miso[7:0];
                                        if ((miso[7:0] & 8'h07) == 8'h00) begin
                                            // we could write a timeout here!   
                                            in_i2c_state <= I_START;                                         
                                        end else begin
                                            in_i2c_counter <= in_i2c_counter + 1;
                                            in_i2c_state <= I_START;
                                        end
                                    end                                
                                end     
                                // Write -> SYSTEM_INTERRUPT_CLEAR                            
                                24:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                // Write -> SYSRANGE_START                                  
                                25:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end                                
                                end
                                // Write -> SYSTEM_SEQUENCE_CONFIG (phase_calibration)
                                26:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end  
                                end       
                                // Write -> SYSRANGE_START
                                27:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end                                  
                                end
                                // Read -> RESULT_INTERRUPT_STATUS
                                28:begin                    
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= miso[7:0];
                                        if ((miso[7:0] & 8'h07) == 8'h00) begin
                                            // we could write a timeout here! 
                                            in_i2c_state <= I_START;                             
                                        end else begin
                                            in_i2c_counter <= in_i2c_counter + 1;
                                            in_i2c_state <= I_START;
                                        end
                                    end 
                                end
                                // Write -> SYSTEM_INTERRUPT_CLEAR  
                                29:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                // Write -> SYSRANGE_START
                                30:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end  
                                end
                                // Write -> SYSTEM_SEQUENCE_CONFIG (restore the previous Sequence Config)
                                31:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end  
                                end
                            //-------------------------------------------------------
                            
                            //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>START CONTINUOUS MODE!
                            
                            //Set I2C standard mode
                               32:begin                
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                33:begin                
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                34:begin               
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                35:begin               
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                36:begin             
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                37:begin             
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                38:begin                
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                            
                            
                                // Write -> SYSRANGE_START (VL53L0X_REG_SYSRANGE_MODE_BACKTOBACK)
                                39:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end 
                                end
                                // Read -> RESULT_INTERRUPT_STATUS
                                40:begin                  
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= miso[7:0];
                                        if ((miso[7:0] & 8'h07) == 8'h00) begin
                                            // we could write a timeout here! 
                                            in_i2c_state <= I_START;                                                       
                                        end else begin
                                            in_i2c_counter <= in_i2c_counter + 1;
                                            in_i2c_state <= I_START;
                                        end
                                    end 
                                end
                                // assumptions: - Linearity Corrective Gain is 1000 (default);
                                //              - fractional ranging is not enabled
                                // Read -> RESULT_RANGE_STATUS + 10
                                41:begin         
                                    if (!busy) begin
                                        ready <= 1;
                                        range_reg[15:8]<= miso[7:0];
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                // Read -> RESULT_RANGE_STATUS + 11
                                42:begin        
                                    if (!busy) begin
                                        ready <= 1;
                                        range_reg[7:0]<= miso[7:0];
                                        in_i2c_counter <= in_i2c_counter + 1;
                                        in_i2c_state <= I_START;
                                    end
                                end
                                // Write -> SYSTEM_INTERRUPT_CLEAR
                                43:begin
                                    if (!busy) begin
                                        ready <= 1;
                                        data_reg <= 0;
                                        in_i2c_counter <= 32;
                                        in_i2c_state <= I_START;
                                    end 
                                end
                                
                            //>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
                                
                            endcase 
                        end
                    endcase
                
                
                
                end
            
            endcase
        
        
        end
    
    
        /*
        //Conversion to 4 leds
        
        if((range_reg > 900) && (range_reg < 1200)) begin
            range_conversion <= 4'b1111;
        end else if ((range_reg > 600) && (range_reg < 900)) begin
            range_conversion <= 4'b0111;
        end else if ((range_reg > 300) && (range_reg < 600)) begin
            range_conversion <= 4'b0011;
        end else if (range_reg < 300)begin
            range_conversion <= 4'b0001;
        end else begin
            range_conversion <= 4'b0000;
        end
        */
    end
    
endmodule