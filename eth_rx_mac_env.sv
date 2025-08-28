class eth_rx_mac_env extends uvm_env;
	`uvm_component_utils(eth_rx_mac_env)
	
	eth_rx_mac_active_agent h_eth_rx_mac_active_agent;
	
	function new(string name = "",uvm_component parent);
		super.new(name,parent);
	endfunction


	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		h_eth_rx_mac_active_agent = eth_rx_mac_active_agent::type_id::create("h_eth_mac_active_agent",this);
	endfunction

endclass
