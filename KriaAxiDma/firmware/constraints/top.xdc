# enable the over-temperature shutdown feathers
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN ENABLE [current_design]
# compress the bitstream to make it smaller
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

# Map the external port to the KR260 25MHz onboard oscillator
set_property PACKAGE_PIN C3 [get_ports ext_clk_25m]
set_property IOSTANDARD LVCMOS18 [get_ports ext_clk_25m]

# Define the clock constraints for the Vivado timing analyzer
create_clock -period 40.000 -name ext_clk_25m [get_ports ext_clk_25m]

#Fan Speed Enable
set_property PACKAGE_PIN A12 [get_ports {fan_en_b}]
set_property IOSTANDARD LVCMOS33 [get_ports {fan_en_b}]
set_property SLEW SLOW [get_ports {fan_en_b}]
set_property DRIVE 4 [get_ports {fan_en_b}]

########################     LEDS     ########################
## ONLY NEEDS TO BE DEFINED WHEN NOT USING BOARD COMPONENTS!!!
### UF1
#set_property PACKAGE_PIN F8 [get_ports {led[0]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[0]}]
### UF2
#set_property PACKAGE_PIN E8 [get_ports {led[1]}]
#set_property IOSTANDARD LVCMOS18 [get_ports {led[1]}]

######################## PMOD 1 Upper ########################
#set_property PACKAGE_PIN H12 [get_ports {pmod_1_01}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_1_01}]

#set_property PACKAGE_PIN E10 [get_ports {pmod_1_02}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_1_02}]

#set_property PACKAGE_PIN D10 [get_ports {pmod_1_03}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_1_03}]

#set_property PACKAGE_PIN C11 [get_ports {pmod_1_04}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_1_04}]

######################## PMOD 1 Lower ########################
#set_property PACKAGE_PIN B10 [get_ports {pmod_1_07}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_1_07}]

#set_property PACKAGE_PIN E12 [get_ports {pmod_1_08}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_1_08}]

#set_property PACKAGE_PIN D11 [get_ports {pmod_1_09}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_1_09}]

#set_property PACKAGE_PIN B11 [get_ports {pmod_1_10}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod_1_10}]

######################## PMOD 2 Upper ########################
# set_property PACKAGE_PIN J11 [get_ports mclk2]
# set_property IOSTANDARD LVCMOS33 [get_ports mclk2]

# set_property PACKAGE_PIN J10 [get_ports lrclk2]
# set_property IOSTANDARD LVCMOS33 [get_ports lrclk2]

# set_property PACKAGE_PIN K13 [get_ports sclk2]
# set_property IOSTANDARD LVCMOS33 [get_ports sclk2]

# set_property PACKAGE_PIN K12 [get_ports sd2]
# set_property IOSTANDARD LVCMOS33 [get_ports sd2]

######################## PMOD 2 Lower ########################
#set_property PACKAGE_PIN H11 [get_ports {pmod2_io[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod2_io[4]}]

#set_property PACKAGE_PIN G10 [get_ports {pmod2_io[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod2_io[5]}]

#set_property PACKAGE_PIN F12 [get_ports {pmod2_io[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod2_io[6]}]

#set_property PACKAGE_PIN F11 [get_ports {pmod2_io[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod2_io[7]}]

######################## PMOD 3 Upper ########################
#set_property PACKAGE_PIN AE12 [get_ports {pmod3_io[0]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod3_io[0]}]

#set_property PACKAGE_PIN AF12 [get_ports {pmod3_io[1]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod3_io[1]}]

#set_property PACKAGE_PIN AG10 [get_ports {pmod3_io[2]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod3_io[2]}]

#set_property PACKAGE_PIN AH10 [get_ports {pmod3_io[3]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod3_io[3]}]

######################## PMOD 3 Lower ########################
#set_property PACKAGE_PIN AF11 [get_ports {pmod3_io[4]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod3_io[4]}]

#set_property PACKAGE_PIN AG11 [get_ports {pmod3_io[5]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod3_io[5]}]

#set_property PACKAGE_PIN AH12 [get_ports {pmod3_io[6]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod3_io[6]}]

#set_property PACKAGE_PIN AH11 [get_ports {pmod3_io[7]}]
#set_property IOSTANDARD LVCMOS33 [get_ports {pmod3_io[7]}]

######################## PMOD 4 Upper ########################
set_property PACKAGE_PIN AC12 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]

set_property PACKAGE_PIN AD12 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]

set_property PACKAGE_PIN AE10 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]

set_property PACKAGE_PIN AF10 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]

######################## PMOD 4 Lower ########################
set_property PACKAGE_PIN AD11 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]

set_property PACKAGE_PIN AD10 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]

set_property PACKAGE_PIN AA11 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]

set_property PACKAGE_PIN AA10 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]