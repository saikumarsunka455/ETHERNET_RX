//======================= eth mem ACTIVE AGENT ====================//

class eth_rx_mem_active_agent extends uvm_agent;

//================ factory registration ==================

	`uvm_component_utils(eth_rx_mem_active_agent)

//===================construction ================

	function new(string name = "" , uvm_component parent);
		super.new(name,parent);
	endfunction

//========================instances ===========================

	eth_rx_mem_sequencer h_eth_rx_mem_sequencer;
	eth_rx_mem_driver h_eth_rx_mem_driver;

//====================build phase=======================

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

//=======================memory creations===========================
		h_eth_rx_mem_sequencer = eth_rx_mem_sequencer :: type_id :: create("h_eth_rx_mem_sequencer",this);
		h_eth_rx_mem_driver = eth_rx_mem_driver :: type_id :: create("h_eth_rx_mem_driver",this);
	endfunction

//===========================connect phase=====================

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		h_eth_rx_mem_driver.seq_item_port.connect(h_eth_rx_mem_sequencer.seq_item_export);
	endfunction

endclass





