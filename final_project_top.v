// Copyright (C) 2025  Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License 
// Subscription Agreement, the Altera Quartus Prime License Agreement,
// the Altera IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Altera and sold by Altera or its authorized distributors.  Please
// refer to the Altera Software License Subscription Agreements 
// on the Quartus Prime software download page.

// PROGRAM		"Quartus Prime"
// VERSION		"Version 25.1std.0 Build 1129 10/21/2025 SC Lite Edition"
// CREATED		"Sun May  3 16:20:28 2026"

module final_project_top(
	CLOCK_50,
	ADC_DOUT,
	SW0,
	GPIO_0_D34,
	GPIO_0_D35,
	KEY0,
	SW9,
	FPGA_I2C_SCLK,
	AUD_XCK,
	AUD_DACDAT,
	VGA_CLK,
	VGA_BLANK_N,
	VGA_HS,
	VGA_VS,
	VGA_SYNC_N,
	FPGA_I2C_SDAT,
	AUD_BCLK,
	AUD_DACLRCK,
	ADC_CS_N,
	ADC_SCLK,
	ADC_DIN,
	HEX0,
	HEX1,
	HEX2,
	HEX3,
	HEX4,
	HEX5,
	VGA_B,
	VGA_G,
	VGA_R
);


input wire	CLOCK_50;
input wire	ADC_DOUT;
input wire	SW0;
input wire	GPIO_0_D34;
input wire	GPIO_0_D35;
input wire	KEY0;
input wire	SW9;
output wire	FPGA_I2C_SCLK;
output wire	AUD_XCK;
output wire	AUD_DACDAT;
output wire	VGA_CLK;
output wire	VGA_BLANK_N;
output wire	VGA_HS;
output wire	VGA_VS;
output wire	VGA_SYNC_N;
output wire	FPGA_I2C_SDAT;
output wire	AUD_BCLK;
output wire	AUD_DACLRCK;
output wire	ADC_CS_N;
output wire	ADC_SCLK;
output wire	ADC_DIN;
output wire	[6:0] HEX0;
output wire	[6:0] HEX1;
output wire	[6:0] HEX2;
output wire	[6:0] HEX3;
output wire	[6:0] HEX4;
output wire	[6:0] HEX5;
output wire	[7:0] VGA_B;
output wire	[7:0] VGA_G;
output wire	[7:0] VGA_R;

wire	SYNTHESIZED_WIRE_101;
wire	SYNTHESIZED_WIRE_102;
wire	SYNTHESIZED_WIRE_103;
wire	SYNTHESIZED_WIRE_104;
wire	SYNTHESIZED_WIRE_105;
wire	SYNTHESIZED_WIRE_106;
wire	[1:0] SYNTHESIZED_WIRE_107;
wire	[2:0] SYNTHESIZED_WIRE_108;
wire	[3:0] SYNTHESIZED_WIRE_8;
wire	[2:0] SYNTHESIZED_WIRE_109;
wire	[3:0] SYNTHESIZED_WIRE_10;
wire	SYNTHESIZED_WIRE_110;
wire	SYNTHESIZED_WIRE_111;
wire	SYNTHESIZED_WIRE_112;
wire	[10:0] SYNTHESIZED_WIRE_113;
wire	[9:0] SYNTHESIZED_WIRE_114;
wire	[47:0] SYNTHESIZED_WIRE_115;
wire	[43:0] SYNTHESIZED_WIRE_116;
wire	[3:0] SYNTHESIZED_WIRE_117;
wire	[43:0] SYNTHESIZED_WIRE_118;
wire	[39:0] SYNTHESIZED_WIRE_119;
wire	[10:0] SYNTHESIZED_WIRE_120;
wire	[9:0] SYNTHESIZED_WIRE_121;
wire	[10:0] SYNTHESIZED_WIRE_122;
wire	[9:0] SYNTHESIZED_WIRE_123;
wire	[10:0] SYNTHESIZED_WIRE_124;
wire	[9:0] SYNTHESIZED_WIRE_125;
wire	[10:0] SYNTHESIZED_WIRE_126;
wire	[9:0] SYNTHESIZED_WIRE_127;
wire	SYNTHESIZED_WIRE_34;
wire	SYNTHESIZED_WIRE_35;
wire	SYNTHESIZED_WIRE_36;
wire	SYNTHESIZED_WIRE_37;
wire	[11:0] SYNTHESIZED_WIRE_128;
wire	SYNTHESIZED_WIRE_43;
wire	SYNTHESIZED_WIRE_44;
wire	SYNTHESIZED_WIRE_45;
wire	SYNTHESIZED_WIRE_46;
wire	[11:0] SYNTHESIZED_WIRE_129;
wire	SYNTHESIZED_WIRE_49;
wire	SYNTHESIZED_WIRE_50;
wire	SYNTHESIZED_WIRE_51;
wire	SYNTHESIZED_WIRE_52;
wire	SYNTHESIZED_WIRE_53;
wire	SYNTHESIZED_WIRE_54;
wire	[3:0] SYNTHESIZED_WIRE_130;
wire	SYNTHESIZED_WIRE_60;
wire	SYNTHESIZED_WIRE_61;
wire	[10:0] SYNTHESIZED_WIRE_76;
wire	[9:0] SYNTHESIZED_WIRE_87;
wire	[3:0] SYNTHESIZED_WIRE_93;
wire	[11:0] SYNTHESIZED_WIRE_95;
wire	SYNTHESIZED_WIRE_97;

assign	VGA_CLK = SYNTHESIZED_WIRE_60;
assign	VGA_BLANK_N = SYNTHESIZED_WIRE_61;




score_lives	b2v_inst(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.game_active(SYNTHESIZED_WIRE_101),
	.frame_tick(SYNTHESIZED_WIRE_102),
	.two_player(SYNTHESIZED_WIRE_103),
	.reset_scores(SYNTHESIZED_WIRE_104),
	.burger_hit_p1(SYNTHESIZED_WIRE_105),
	.burger_hit_p2(SYNTHESIZED_WIRE_106),
	.game_state(SYNTHESIZED_WIRE_107),
	.p1_lives(SYNTHESIZED_WIRE_108),
	.p1_score_inc(SYNTHESIZED_WIRE_8),
	.p2_lives(SYNTHESIZED_WIRE_109),
	.p2_score_inc(SYNTHESIZED_WIRE_10),
	.HEX0(HEX0),
	.HEX1(HEX1),
	.HEX2(HEX2),
	.HEX3(HEX3),
	.HEX4(HEX4),
	.HEX5(HEX5));


collision_detect	b2v_inst1(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.game_active(SYNTHESIZED_WIRE_101),
	.p1_ba(SYNTHESIZED_WIRE_110),
	.p2_ba(SYNTHESIZED_WIRE_111),
	.two_player(SYNTHESIZED_WIRE_103),
	.burg_active(SYNTHESIZED_WIRE_112),
	.burg_x(SYNTHESIZED_WIRE_113),
	.burg_y(SYNTHESIZED_WIRE_114),
	.enemy_alive(SYNTHESIZED_WIRE_115),
	.enemy_base_x(SYNTHESIZED_WIRE_116),
	.enemy_eb_active(SYNTHESIZED_WIRE_117),
	.enemy_eb_x(SYNTHESIZED_WIRE_118),
	.enemy_eb_y(SYNTHESIZED_WIRE_119),
	.p1_bx(SYNTHESIZED_WIRE_120),
	.p1_by(SYNTHESIZED_WIRE_121),
	.p1_x(SYNTHESIZED_WIRE_122),
	.p1_y(SYNTHESIZED_WIRE_123),
	.p2_bx(SYNTHESIZED_WIRE_124),
	.p2_by(SYNTHESIZED_WIRE_125),
	.p2_x(SYNTHESIZED_WIRE_126),
	.p2_y(SYNTHESIZED_WIRE_127),
	.p1_hit(SYNTHESIZED_WIRE_35),
	.p2_hit(SYNTHESIZED_WIRE_44),
	.p1_bull_kill(SYNTHESIZED_WIRE_36),
	.p2_bull_kill(SYNTHESIZED_WIRE_45),
	.burger_hit_p1(SYNTHESIZED_WIRE_105),
	.burger_hit_p2(SYNTHESIZED_WIRE_106),
	.p1_bull_hit_enemy(SYNTHESIZED_WIRE_37),
	.p2_bull_hit_enemy(SYNTHESIZED_WIRE_46),
	.eb_kill(SYNTHESIZED_WIRE_93),
	.enemy_kill(SYNTHESIZED_WIRE_130),
	.enemy_kill_col(SYNTHESIZED_WIRE_95),
	.p1_score_inc(SYNTHESIZED_WIRE_8),
	.p2_score_inc(SYNTHESIZED_WIRE_10));


player_ctrl	b2v_inst11(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.game_active(SYNTHESIZED_WIRE_101),
	.frame_tick(SYNTHESIZED_WIRE_102),
	.two_player(SYNTHESIZED_WIRE_103),
	.fire_press(SYNTHESIZED_WIRE_34),
	.hit(SYNTHESIZED_WIRE_35),
	.bull_kill(SYNTHESIZED_WIRE_36),
	.enemy_hit(SYNTHESIZED_WIRE_37),
	.reset_game(SYNTHESIZED_WIRE_104),
	.adc_val(SYNTHESIZED_WIRE_128),
	.bullet_active(SYNTHESIZED_WIRE_110),
	.fire_sfx(SYNTHESIZED_WIRE_53),
	.die_sfx(SYNTHESIZED_WIRE_50),
	.bullet_x(SYNTHESIZED_WIRE_120),
	.bullet_y(SYNTHESIZED_WIRE_121),
	.lives(SYNTHESIZED_WIRE_108),
	.player_x(SYNTHESIZED_WIRE_122),
	.player_y(SYNTHESIZED_WIRE_123));


player2_ctrl	b2v_inst12(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.game_active(SYNTHESIZED_WIRE_101),
	.frame_tick(SYNTHESIZED_WIRE_102),
	.two_player(SYNTHESIZED_WIRE_103),
	.fire_press(SYNTHESIZED_WIRE_43),
	.hit(SYNTHESIZED_WIRE_44),
	.bull_kill(SYNTHESIZED_WIRE_45),
	.enemy_hit(SYNTHESIZED_WIRE_46),
	.reset_game(SYNTHESIZED_WIRE_104),
	.adc_val(SYNTHESIZED_WIRE_129),
	.bullet_active(SYNTHESIZED_WIRE_111),
	.fire_sfx(SYNTHESIZED_WIRE_54),
	.die_sfx(SYNTHESIZED_WIRE_51),
	.bullet_x(SYNTHESIZED_WIRE_124),
	.bullet_y(SYNTHESIZED_WIRE_125),
	.lives(SYNTHESIZED_WIRE_109),
	.player_x(SYNTHESIZED_WIRE_126),
	.player_y(SYNTHESIZED_WIRE_127));


sound_effects_generator_top	b2v_inst13(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.sel_gameover(SYNTHESIZED_WIRE_49),
	.sel_dead1(SYNTHESIZED_WIRE_50),
	.sel_dead2(SYNTHESIZED_WIRE_51),
	.sel_burger(SYNTHESIZED_WIRE_52),
	.sel_bullet1(SYNTHESIZED_WIRE_53),
	.sel_bullet2(SYNTHESIZED_WIRE_54),
	.enemy_kill(SYNTHESIZED_WIRE_130),
	.AUD_XCK(AUD_XCK),
	.AUD_DACDAT(AUD_DACDAT),
	.FPGA_I2C_SCLK(FPGA_I2C_SCLK),
	.FPGA_I2C_SDAT(FPGA_I2C_SDAT),
	.AUD_BCLK(AUD_BCLK),
	.AUD_DACLRCK(AUD_DACLRCK));


vga_generator_output_top	b2v_inst18(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.VGA_SYNC_N(VGA_SYNC_N),
	.VGA_BLANK_N(SYNTHESIZED_WIRE_61),
	.VGA_HS_N(VGA_HS),
	.VGA_VS_N(VGA_VS),
	.VGA_CLK(SYNTHESIZED_WIRE_60),
	.frame_tick(SYNTHESIZED_WIRE_102),
	.hcount_out(SYNTHESIZED_WIRE_76),
	.vcount_out(SYNTHESIZED_WIRE_87));


adc_controller	b2v_inst19(
	.clock_50(CLOCK_50),
	.reset_active_low(KEY0),
	.ADC_DOUT(ADC_DOUT),
	.ADC_CS_N(ADC_CS_N),
	.ADC_SCLK(ADC_SCLK),
	.ADC_DIN(ADC_DIN),
	.paddle_1(SYNTHESIZED_WIRE_128),
	.paddle_2(SYNTHESIZED_WIRE_129));


burger_ctrl	b2v_inst2(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.game_active(SYNTHESIZED_WIRE_101),
	.frame_tick(SYNTHESIZED_WIRE_102),
	.burger_hit_p1(SYNTHESIZED_WIRE_105),
	.burger_hit_p2(SYNTHESIZED_WIRE_106),
	.burg_active(SYNTHESIZED_WIRE_112),
	.collect_sfx(SYNTHESIZED_WIRE_52),
	.burg_x(SYNTHESIZED_WIRE_113),
	.burg_y(SYNTHESIZED_WIRE_114));


vga_renderer_output_top	b2v_inst20(
	.vga_clock(SYNTHESIZED_WIRE_60),
	.reset_active_low(KEY0),
	.blanking_active_low(SYNTHESIZED_WIRE_61),
	.p1_ba(SYNTHESIZED_WIRE_110),
	.p2_ba(SYNTHESIZED_WIRE_111),
	.two_player(SYNTHESIZED_WIRE_103),
	.burg_active(SYNTHESIZED_WIRE_112),
	.alignment(SW9),
	.game_active(SYNTHESIZED_WIRE_101),
	.frame_tick(SYNTHESIZED_WIRE_102),
	.burg_x(SYNTHESIZED_WIRE_113),
	.burg_y(SYNTHESIZED_WIRE_114),
	.enemy_alive(SYNTHESIZED_WIRE_115),
	.enemy_base_x(SYNTHESIZED_WIRE_116),
	.enemy_eb_active(SYNTHESIZED_WIRE_117),
	.enemy_eb_x(SYNTHESIZED_WIRE_118),
	.enemy_eb_y(SYNTHESIZED_WIRE_119),
	.game_state(SYNTHESIZED_WIRE_107),
	.hcount(SYNTHESIZED_WIRE_76),
	.p1_bx(SYNTHESIZED_WIRE_120),
	.p1_by(SYNTHESIZED_WIRE_121),
	.p1_lives(SYNTHESIZED_WIRE_108),
	.p1_x(SYNTHESIZED_WIRE_122),
	.p1_y(SYNTHESIZED_WIRE_123),
	.p2_bx(SYNTHESIZED_WIRE_124),
	.p2_by(SYNTHESIZED_WIRE_125),
	.p2_lives(SYNTHESIZED_WIRE_109),
	.p2_x(SYNTHESIZED_WIRE_126),
	.p2_y(SYNTHESIZED_WIRE_127),
	.vcount(SYNTHESIZED_WIRE_87),
	.blue(VGA_B),
	.green(VGA_G),
	.red(VGA_R));


binary_to_seven_seg	b2v_inst3(
	.paddle_A(SYNTHESIZED_WIRE_128),
	.paddle_B(SYNTHESIZED_WIRE_129)
	
	
	
	
	
	);


enemy_grid	b2v_inst4(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.game_active(SYNTHESIZED_WIRE_101),
	.frame_tick(SYNTHESIZED_WIRE_102),
	.reset_game(SYNTHESIZED_WIRE_104),
	.eb_kill(SYNTHESIZED_WIRE_93),
	.enemy_kill(SYNTHESIZED_WIRE_130),
	.enemy_kill_col(SYNTHESIZED_WIRE_95),
	.base_x(SYNTHESIZED_WIRE_116),
	.eb_active(SYNTHESIZED_WIRE_117),
	.eb_x(SYNTHESIZED_WIRE_118),
	.eb_y(SYNTHESIZED_WIRE_119),
	.enemy_alive(SYNTHESIZED_WIRE_115));


game_fsm	b2v_inst7(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.frame_tick(SYNTHESIZED_WIRE_102),
	.start_press(SYNTHESIZED_WIRE_97),
	.sw0(SW0),
	.enemy_alive(SYNTHESIZED_WIRE_115),
	.p1_lives(SYNTHESIZED_WIRE_108),
	.p2_lives(SYNTHESIZED_WIRE_109),
	.game_active(SYNTHESIZED_WIRE_101),
	.two_player(SYNTHESIZED_WIRE_103),
	.game_over_sfx(SYNTHESIZED_WIRE_49),
	.reset_scores(SYNTHESIZED_WIRE_104),
	.game_state(SYNTHESIZED_WIRE_107));


input_decode	b2v_inst8(
	.clock(CLOCK_50),
	.reset_active_low(KEY0),
	.JOY_1(GPIO_0_D34),
	.JOY_2(GPIO_0_D35),
	.fire1(SYNTHESIZED_WIRE_34),
	.fire2(SYNTHESIZED_WIRE_43),
	.start_press(SYNTHESIZED_WIRE_97));


endmodule
