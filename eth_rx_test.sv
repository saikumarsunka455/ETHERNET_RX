class eth_test extends uvm_test;

//================== factory registration ========
	`uvm_component_utils(eth_test)

//============instance ========
	eth_rx_top_env h_eth_rx_top_env;
	eth_rx_host_sequence h_eth_rx_host_sequence;
	eth_rx_mem_sequence h_eth_rx_mem_sequence;
	eth_rx_mac_sequence h_eth_rx_mac_sequence;
	eth_rx_reconfig_int_source h_eth_rx_reconfig_int_source;

	virtual eth_interface h_eth_interface;
   	eth_config_class h_eth_config_class; 
//=============== construction ==========
	function new(string name = "",uvm_component parent);
		super.new(name,parent);
	endfunction


	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		assert(uvm_config_db #(virtual eth_interface) :: get(this , "" , "eth_interface", h_eth_interface));
		assert(uvm_config_db #(eth_config_class)::get(null,this.get_full_name(),"eth_config_class",h_eth_config_class));
		h_eth_rx_top_env = eth_rx_top_env::type_id::create("h_eth_rx_top_env",this);
		h_eth_rx_host_sequence = eth_rx_host_sequence::type_id::create("h_eth_rx_host_sequence");
		h_eth_rx_mem_sequence = eth_rx_mem_sequence::type_id::create("h_eth_rx_mem_sequence");
		h_eth_rx_mac_sequence = eth_rx_mac_sequence::type_id::create("h_eth_rx_mac_sequence");
		h_eth_rx_reconfig_int_source = eth_rx_reconfig_int_source::type_id::create("h_eth_rx_reconfig_int_source");
	endfunction

	function void start_of_simulation_phase(uvm_phase phase);
	//function void end_of_elaboration_phase(uvm_phase phase);
	//	uvm_top.print_topology();//  to print the topology to verify how the connetions is going on
		print();
	endfunction

//=====================run phase=======================//

	task run_phase(uvm_phase phase);
		super.run_phase(phase);

		phase.raise_objection(this,"rasied");

			h_eth_rx_host_sequence.start(h_eth_rx_top_env.h_eth_rx_host_mem_env.h_eth_rx_host_active_agent.h_eth_rx_host_sequencer);
			
			fork			
				h_eth_rx_mem_sequence.start(h_eth_rx_top_env.h_eth_rx_host_mem_env.h_eth_rx_mem_active_agent.h_eth_rx_mem_sequencer);
				h_eth_rx_mac_sequence.start(h_eth_rx_top_env.h_eth_rx_mac_env.h_eth_rx_mac_active_agent.h_eth_rx_mac_sequencer);
				for(int frame_address_location = (1024 + h_eth_config_class.TX_BD_NUM*8); frame_address_location < 2048;frame_address_location+=8)
				begin
					if(h_eth_config_class.RXD[frame_address_location][14] && h_eth_config_class.INT_MASK[2])
						wait(h_eth_interface.int_o) h_eth_rx_reconfig_int_source.start(h_eth_rx_top_env.h_eth_rx_host_mem_env.h_eth_rx_host_active_agent.h_eth_rx_host_sequencer);
					else begin
						`uvm_info("TEST",$sformatf("======================IRQ OR RXB_M ANY ONE THOSE TWO ARE DISABLE, SO IT WONT GENERATE INTERRUPT INT_O"),UVM_NONE);
					end
				end
			join
		//	$display($time,"==================== RXD = %p  h_eth_config_class.RXd[1024 + h_eth_config_class.TX_BD_NUM*8][14]  %d h_eth_config_class.INT_MASK[2] %d",h_eth_config_class.RXD,h_eth_config_class.RXD[1024 + h_eth_config_class.TX_BD_NUM*8][14],h_eth_config_class.INT_MASK[2]);
			#10000;
		phase.drop_objection(this , "dropped");
	endtask


endclass

