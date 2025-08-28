//========== MASTER PASSIVE AGENT ==============//

class eth_rx_mem_passive_agent extends uvm_agent;

	`uvm_component_utils(eth_rx_mem_passive_agent)    //====== Factory registration

//========================instances ===========================
	
	eth_rx_mem_output_monitor h_eth_rx_mem_output_monitor;

	function new(string name = "",uvm_component parent);
		super.new(name,parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		h_eth_rx_mem_output_monitor = eth_rx_mem_output_monitor ::type_id::create("h_eth_rx_mem_output_monitor",this);
	endfunction


endclass

