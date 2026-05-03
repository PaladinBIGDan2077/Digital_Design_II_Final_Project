/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Sound Chip I2C Controller Module
// Filename:                        i2c_controller.sv
// Version:                         3
// Author:                          Daniel J. Lomis 
// Date:                            4/20/2025  
// Location:                        Blacksburg, Virginia 
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering 
// Course:                          ECE 4514 - Digital Design II 
// Instructor:                      Professor Jason Thweatt 
//  
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)  
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
// 
// Description:                     Configures the WM8731 over I2C (2-wire, 100 kHz) on power-up.
//                                  Runs on 50 MHz sysclock.
//
//                                  I2C transaction format for WM8731:
//                                      [START] [0x34 (device addr, R/W=0)] [ACK] [B15:B8] [ACK] [B7:B0] [ACK] [STOP]
//                                      where B[15:9] = register address, B[8:0] = register data.
//
//                                  The controller steps through CONFIG_REGS[] automatically from reset.
//                                  config_done goes high and stays high once all registers are written.
//
//                                  Date        By   Version  Change Description  
//                                  ============================================  
//                                  4/20/2025   DJL  1        Original Code
//                                  
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module wm8731_i2c_config
(
    input                                   logic                                           clock,
    input                                   logic                                           reset_active_low,
    output                                  logic                                           i2c_sclk,
    output                                  logic                                           i2c_sdat
);
    // Local Parameters
    localparam          int                 CLK_FREQ                                        = 50_000_000;
    localparam          int                 I2C_FREQ                                        = 100_000;
    localparam          int                 PHASE_LEN                                       = CLK_FREQ / I2C_FREQ / 4;
    // Typedef Enum Structs
    typedef             enum                logic               [3:0]                       {
        S_IDLE,
        S_START,
        S_SEND_BIT,
        S_SCL_HIGH,
        S_SCL_LOW,
        S_ACK_RELEASE,
        S_ACK_PULSE,
        S_ACK_CHECK,
        S_STOP_SDA_LOW,
        S_STOP_SCL_HIGH,
        S_STOP_SDA_HIGH,
        S_DONE
    }   state_t;

        state_t   state;

    typedef                                 logic               [15:0]                      reg16_t;

    localparam          reg16_t             CONFIG_REGS         [0:6]                       = '{
        16'h1E00,   // R15: reset
        16'h0C67,   // R6:  power down (ADC/MIC/LINEIN off, DAC+OUT on, OSC/CLKOUT off)
        16'h0812,   // R4:  analog path
        16'h0A00,   // R5:  digital path (unmute DAC)
        16'h0E02,   // R7:  I2S 16-bit slave
        16'h100C,   // R8:  8 kHz sampling
        16'h1201    // R9:  activate
    };

    // Internal Register-driven Connections
                                            logic                                           config_done;
                                            logic               [3:0]                       reg_idx;
                                            logic               [4:0]                       bit_idx;
                                            logic               [23:0]                      payload;
                                            logic                                           sda_out;
                                            logic                                           sda_oe;
                                            logic                                           scl_out;
                                            logic               [$clog2(PHASE_LEN)-1:0]     phase_cnt;
                                            logic               [1:0]                       phase;
                                            logic                                           phase_tick;

    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            phase_cnt <= '0;
            phase <= 2'd0;
        end 
        else begin
            if (phase_cnt == PHASE_LEN - 1) begin
                phase_cnt <= '0;
                phase <= phase + 1'b1;
            end
            else begin
                phase_cnt <= phase_cnt + 1'b1;
            end
        end
    end

    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            state <= S_IDLE;
            reg_idx <= '0;
            bit_idx <= '0;
            payload <= '0;
            scl_out <= 1'b1;
            sda_out <= 1'b1;
            sda_oe <= 1'b1;
            config_done <= 1'b0;
        end 
        else if (phase_tick) begin
            case (state)
                S_IDLE: begin
                    scl_out <= 1'b1;
                    sda_out <= 1'b1;
                    sda_oe <= 1'b1;
                    if (!config_done) begin
                        payload <= {8'h34, CONFIG_REGS[reg_idx]};
                        bit_idx <= '0;
                        state <= S_START;
                    end
                end

                S_START: begin
                    if (phase == 2'd1) begin
                        sda_out <= 1'b0;
                        scl_out <= 1'b1;
                    end 
                    else if (phase == 2'd3) begin
                        scl_out <= 1'b0;
                        state <= S_SEND_BIT;
                    end
                end

                S_SEND_BIT: begin
                    sda_oe <= 1'b1;
                    sda_out <= payload[23];
                    scl_out <= 1'b0;
                    state <= S_SCL_HIGH;
                end

                S_SCL_HIGH: begin
                    scl_out <= 1'b1;
                    state <= S_SCL_LOW;
                end

                S_SCL_LOW: begin
                    scl_out <= 1'b0;
                    payload <= {payload[22:0], 1'b0};
                    bit_idx <= bit_idx + 1'b1;
                    if (bit_idx == 7 || bit_idx == 15 || bit_idx == 23) begin
                        state <= S_ACK_RELEASE;
                    end 
                    else begin
                        state <= S_SEND_BIT;
                    end
                end

                S_ACK_RELEASE: begin
                    sda_oe <= 1'b0;
                    scl_out <= 1'b0;
                    state <= S_ACK_PULSE;
                end

                S_ACK_PULSE: begin
                    scl_out <= 1'b1;
                    state <= S_ACK_CHECK;
                end

                S_ACK_CHECK: begin
                    scl_out <= 1'b0;
                    sda_oe <= 1'b1;
                    if (bit_idx == 24) begin
                        state <= S_STOP_SDA_LOW;
                    end 
                    else begin
                        state <= S_SEND_BIT;
                    end
                end

                S_STOP_SDA_LOW: begin
                    sda_out <= 1'b0;
                    scl_out <= 1'b0;
                    state <= S_STOP_SCL_HIGH;
                end

                S_STOP_SCL_HIGH: begin
                    scl_out <= 1'b1;
                    state <= S_STOP_SDA_HIGH;
                end

                S_STOP_SDA_HIGH: begin
                    sda_out <= 1'b1;
                    scl_out <= 1'b1;
                    if (reg_idx == 6) begin
                        state <= S_DONE;
                    end 
                    else begin
                        reg_idx <= reg_idx + 1'b1;
                        state <= S_IDLE;
                    end
                end

                S_DONE: begin
                    config_done <= 1'b1;
                    scl_out <= 1'b1;
                    sda_out <= 1'b1;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

    // Continous Assignments
    assign                                  i2c_sclk                                = scl_out;
    assign                                  i2c_sdat                                = sda_oe ? sda_out : 1'bz;
    assign                                  phase_tick                              = (phase_cnt == PHASE_LEN - 1);

endmodule