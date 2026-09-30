# NOTE: When describing the paths we use a forward slash, "/", as the path delimiter.
# If you didn't clone this repo into a C:/Development/KriaKR260Projects folder on your 
# machine you will need to update the paths below
set workspace_path "C:/Development/KriaProjects/TempAndHumidity/firmware/kria_hygrometer/outputs"
set xsa_file "${workspace_path}/hygrometer.xsa"
set repo_path "C:/Development/device-tree-xlnx"

if {[file exists $xsa_file]} {
    puts "$xsa_file was found."
} else {
    puts ""
    puts "$xsa_file was not found."
    puts "Press any key to exit..."
    gets stdin
    exit
}

puts "Open Hardware design and generate target..."
puts ""
hsi::open_hw_design ${xsa_file}
hsi::set_repo_path ${repo_path}
hsi::create_sw_design device-tree -os device_tree -proc psu_cortexa53_0
hsi::set_property CONFIG.dt_overlay true [hsi::get_os]
# If ZOCL is used (Maybe for Multi Channel DMWA, but not for this demo, so you can skip this line)
# xsct% hsi set_property CONFIG.dt_zocl true [hsi::get_os]
hsi::generate_target -dir ${workspace_path}
hsi::close_sw_design [hsi::current_sw_design]
hsi::close_hw_design [hsi::current_hw_design]

puts ""
puts "${workspace_path}/pl.dtsi should now be created!"
puts "Press any key to exit..."
gets stdin
