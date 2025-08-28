home = /home/chicago/tools/Questa_2021.4_3/questasim/linux_x86_64/../modelsim.ini


pack = eth_rx_package.sv


top = eth_rx_top.sv

interface = eth_rx_interface.sv

work:
	vlib work
map:
	vmap work work 


comp_max_bds_4_2030_len:
	vlog -work work +cover +acc -sv $(pack) $(top) $(interface)
	vsim -coverage -sva -c -do "log -r /*;coverage save -onexit cover_file.ucdb -assert -directive -cvg -code All ;run -all ;exit" -coverage -sva -l comp_max_bds_4_2030_len.log  -wlf comp_max_bds_4_2030_len.wlf work.top +UVM_TESTNAME=eth_test +svSeed=RANDOM +UVM_VERBOSITY=UVM_HIGH +bd_value=127 +bd_num_flag=0 +type_frame1=0

comp_max_bds_4_45_len:
	vlog -work work +cover +acc -sv $(pack) $(top) $(interface)
	vsim -coverage -sva -c -do "log -r /*;coverage save -onexit cover_file.ucdb -assert -directive -cvg -code All ;run -all ;exit" -coverage -sva -l comp_max_bds_4_45_len.log  -wlf comp_max_bds_4_45_len.wlf work.top +UVM_TESTNAME=eth_test +svSeed=RANDOM +UVM_VERBOSITY=UVM_HIGH +bd_value=0 +bd_num_flag=0 +type_frame1=2

comp_4len:
	vlog -work work +cover +acc -sv $(pack) $(top) $(interface)
	vsim -coverage -sva -c -do "log -r /*;coverage save -onexit cover_file.ucdb -assert -directive -cvg -code All ;run -all ;exit" -coverage -sva -l comp_4len.log  -wlf comp_4len.wlf work.top +UVM_TESTNAME=eth_test +svSeed=RANDOM +UVM_VERBOSITY=UVM_HIGH +bd_value=120 +bd_num_flag=0 +type_frame1=5


wave: 
	vsim -view apb.wlf &

merge:
	vcover merge all_cover.ucdb *.ucdb
	
clean:
	rm -rf *.ini transcript work regression_status_list *.log merge_list_file *.wlf .goutputstream* *.swp *.dbg wlf* *.vstf *.ucdb





