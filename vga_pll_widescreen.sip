set_global_assignment -entity "vga_pll_widescreen" -library "lib_vga_pll_widescreen" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "vga_pll_widescreen" -library "lib_vga_pll_widescreen" -name IP_TOOL_VERSION "25.1"
set_global_assignment -entity "vga_pll_widescreen" -library "lib_vga_pll_widescreen" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_vga_pll_widescreen" -name SPD_FILE [file join $::quartus(sip_path) "vga_pll_widescreen.spd"]

set_global_assignment -library "lib_vga_pll_widescreen" -name MISC_FILE [file join $::quartus(sip_path) "vga_pll_widescreen_sim/vga_pll_widescreen.vo"]
