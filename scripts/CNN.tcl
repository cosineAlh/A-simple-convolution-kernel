#===========================================================
set_svf CNN.svf
#===========================================================

#===========================================================
# Step 1: Reload & elaborate the RTL file list & check
#===========================================================
read_file -format verilog ./CNN.v

if {[link] == 0} {
	echo "Link with error!";
	exit;}

if {[check_design] == 0} {
	echo "Check design with error!";
	exit;}

#===========================================================
# Step 2: reset the design first
#===========================================================
#reset_design

#===========================================================
# Step 3: write the unmapped ddc file
#===========================================================
#uniquify
#set uniquify_naming_style "%s_%d"
#write -f ddc -hierarchy -output /home/user001/tsclient/workplace_wzr/VLSI/${TOP_MODULE}.ddc

#===========================================================
# Step 3: Dedine clock
#===========================================================
create_clock -period 8 [get_ports clk]
set_dont_touch_network [get_ports clk]

#===========================================================
# Step 4: Define reset
#===========================================================
set_dont_touch_network [get_ports rst]

#===========================================================
# Step 5: Set input delay
#===========================================================
set_input_delay 5 -clock clk [all_inputs]
remove_input_delay [get_ports clk]

#===========================================================
# Step 6: Set output delay

set_output_delay 5 -clock clk [all_outputs]

#===========================================================
# Step 7: Set design rule
#===========================================================
set_max_area 0
set_max_fanout 4 CNN
set_max_transition 0.8 CNN

#===========================================================
# Step 8: Compile
#===========================================================
set_svf off
compile -exact_map

#===========================================================
# Step 9: Report
#===========================================================
report_area > ./report/area.txt
report_power > ./report/power.txt
report_timing > ./reprot/timing.txt

#===========================================================
# Step 10: Write
#===========================================================
write -hierarchy -format verilog -output ./my_verilog.v
write_sdf ./report/my_sdf.sdf

exit
