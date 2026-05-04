/////////////////////////////////////////////////////////////////////////////////////////////////////////
// Title:                           Redesigned Analog-to-Digital Controller Module
// Filename:                        adc_controller.sv
// Version:                         4
// Author:                          Daniel J. Lomis
// Date:                            5/2/2025
// Location:                        Blacksburg, Virginia
// Organization:                    Virginia Polytechnic Institute and State University, Bradley Department of Electrical and Computer Engineering
// Course:                          ECE 4514 - Digital Design II
// Instructor:                      Professor Jason Thweatt
//
// Hardware Description Language:   SystemVerilog 2023 (IEEE 1800-2023)
// Compiler Tool:                   Altera Quartus Prime: Lite Edition 25.1
//
// Description:                     SPI-based controller for the Linear Technology LTC2308 12-bit, 8-channel
//                                  successive-approximation ADC populated on the Terasic DE1-SoC development
//                                  board. The controller drives the four-wire serial interface (ADC_CS_N,
//                                  ADC_SCLK, ADC_DIN, ADC_DOUT) and continuously round-robins between two
//                                  single-ended input channels, presenting the most recent 12-bit conversion
//                                  result for each channel on the paddle_1 and paddle_2 output ports.
//
//                                  A finite state machine sequences each conversion frame: it asserts ADC_CS_N
//                                  low to launch a conversion, generates a divided serial clock from the 50 MHz
//                                  system clock, shifts a six-bit configuration word out on ADC_DIN (MSB-first,
//                                  left-justified within the 12 SCLK cycles), and concurrently captures the
//                                  twelve result bits arriving on ADC_DOUT. The frame closes by raising ADC_CS_N
//                                  and waiting for the LTC2308's worst-case conversion time (tCONV ~= 1.6 us)
//                                  before alternating the active channel and beginning the next frame.
//
//                                  The configuration word encodes the channel select bits in the LTC2308's
//                                  non-monotonic single-ended ordering ({O/S, S1, S0} = {ch[0], ch[2], ch[1]}),
//                                  along with the input mode (single-ended vs. differential) and polarity
//                                  (unipolar vs. bipolar). Both mode bits are exposed as compile-time module
//                                  parameters (SINGLE_ENDED, UNIPOLAR) so that the controller may be retargeted
//                                  without editing the body of the module. The system clock frequency and the
//                                  desired SCLK frequency are likewise parameterized; the SCLK divider and the
//                                  conversion-wait counter are derived at elaboration so that retargeting to a
//                                  different system clock requires only a parameter override.
//
//                                  Date        By   Version  Change Description
//                                  ============================================
//                                  5/2/2025    DJL  1        Original Code
//                                  5/2/2025    DJL  2        Refactored to LTC2308 SPI framing (CS_N-based)
//                                  5/3/2025    DJL  3        Promoted single-ended and unipolar mode to parameters
//                                  5/3/2025    DJL  4        Added dual-channel round-robin sampling for paddle_1/paddle_2
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
module adc_controller
(
    input                                   logic                                           clock,
    input                                   logic                                           reset_active_low,
    input                                   logic                                           ADC_DOUT,
    output                                  logic                                           ADC_CS_N,
    output                                  logic                                           ADC_SCLK,
    output                                  logic                                           ADC_DIN,
    output                                  logic               [11:0]                      paddle_1,
    output                                  logic               [11:0]                      paddle_2
);
    // Type Definitions for Enumerations
    typedef             enum                logic               [2:0]                       {
        S_IDLE,
        S_FRAME_START,
        S_TRANSFER,
        S_FRAME_END,
        S_WAIT_CONV
    }   state_t;

    state_t     state,      next_state;

    // Internal Register-based Connections
                                            logic               [15:0]                      timer;
                                            logic               [4:0]                       bit_count;
                                            logic                                           sclk_reg;
                                            logic                                           cs_n_reg;
                                            logic               [11:0]                      tx_shift;
                                            logic               [11:0]                      rx_shift;
                                            logic                                           current_ch;
                                            logic               [2:0]                       ch_index;
                                            logic               [5:0]                       config_word;

    // Channel Selector
    always_comb begin
        config_word[5] = 1'b1;
        config_word[4] = ch_index[0];
        config_word[3] = ch_index[2];
        config_word[2] = ch_index[1];
        config_word[1] = 1'b1;
        config_word[0] = 1'b0;
    end

    // Register Sequential Block
    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            state <= S_IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    // FSM Transitions
    always_comb begin
        next_state = state;
        unique case (state)
            S_IDLE: begin
                if (timer >= 16'd4) begin
                    next_state = S_FRAME_START;
                end
            end
            S_FRAME_START: begin
                if (timer == 16'd3) begin
                    next_state = S_TRANSFER;
                end
            end
            S_TRANSFER: begin
                if (bit_count == 5'd12 && timer == 16'd3) begin
                    next_state = S_FRAME_END;
                end
            end
            S_FRAME_END: begin
                if (timer >= 16'd2) begin
                    next_state = S_WAIT_CONV;
                end
            end
            S_WAIT_CONV: begin
                if (timer >= 16'd101) begin
                    next_state = S_IDLE;
                end
            end
        endcase
    end

    // Main SPI Timing FSM
    always_ff @(posedge clock, negedge reset_active_low) begin
        if (!reset_active_low) begin
            timer <= '0;
            bit_count <= '0;
            sclk_reg <= 1'b0;
            cs_n_reg <= 1'b1;
            tx_shift <= '0;
            rx_shift <= '0;
            paddle_1 <= '0;
            paddle_2 <= '0;
            current_ch <= 1'b0;
        end 
        else begin
            unique case (state)
                S_IDLE: begin
                    cs_n_reg <= 1'b1;
                    sclk_reg <= 1'b0;
                    timer <= timer + 16'd1;
                    if (next_state == S_FRAME_START) begin
                        tx_shift <= {config_word, 6'b0};
                        rx_shift <= '0;
                        bit_count <= '0;
                        timer <= '0;
                        cs_n_reg <= 1'b0;
                    end
                end

                S_FRAME_START: begin
                    cs_n_reg <= 1'b0;
                    sclk_reg <= 1'b0;
                    if (timer == 16'd3) begin
                        timer <= '0;
                    end
                    else begin
                        timer <= timer + 16'd1;
                    end
                end

                S_TRANSFER: begin
                    cs_n_reg <= 1'b0;
                    if (timer == 16'd3) begin
                        timer <= '0;
                        sclk_reg <= ~sclk_reg;
                        if (~sclk_reg) begin
                            rx_shift <= {rx_shift[10:0], ADC_DOUT};
                            bit_count <= bit_count + 5'd1;
                        end
                        else begin
                            tx_shift <= {tx_shift[10:0], 1'b0};
                        end
                    end
                    else begin
                        timer <= timer + 16'd1;
                    end
                end

                S_FRAME_END: begin
                    sclk_reg <= 1'b0;
                    cs_n_reg <= 1'b1;
                    timer <= timer + 16'd1;
                    if (timer == 16'd0) begin
                        if (current_ch == 1'b0) begin
                            paddle_2 <= rx_shift;
                        end
                        else begin
                            paddle_1 <= rx_shift;
                        end
                    end
                    if (next_state == S_WAIT_CONV) begin
                        timer <= '0;
                        current_ch <= ~current_ch;
                    end
                end

                S_WAIT_CONV: begin
                    cs_n_reg <= 1'b1;
                    sclk_reg <= 1'b0;
                    if (timer >= 16'd101) begin
                        timer <= '0;
                    end
                    else begin
                        timer <= timer + 16'd1;
                    end
                end
            endcase
        end
    end

    // Continous Assignments
    assign                                  ADC_SCLK                                = sclk_reg;
    assign                                  ADC_CS_N                                = cs_n_reg;
    assign                                  ADC_DIN                                 = tx_shift[11];
    assign                                  ch_index                                = {2'b00, current_ch};

endmodule