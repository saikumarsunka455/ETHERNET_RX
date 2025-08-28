class eth_rx_host_active_agent extends uvm_component;

	`uvm_component_utils(eth_rx_host_active_agent) //factory registraction 
	
		
	eth_rx_host_sequencer h_eth_rx_host_sequencer;
	eth_rx_host_driver    h_eth_rx_host_driver;
	eth_rx_host_monitor   h_eth_rx_host_monitor;

	//====CONSTRUCTOR=========
	
	function new(string name = "eth_host_active_agent", uvm_component parent);
	super.new(name,parent);
	endfunction

	//========BUILB PHASE=======

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		
		h_eth_rx_host_sequencer = eth_rx_host_sequencer::type_id::create("h_eth_rx_host_sequencer",this);
		h_eth_rx_host_driver = eth_rx_host_driver::type_id::create("h_eth_rx_host_driver",this);
		h_eth_rx_host_monitor = eth_rx_host_monitor::type_id::create("h_eth_rx_host_monitor",this);
		
	endfunction

//============connect phase==================//

	function void connect_phase(uvm_phase phase);

		super.connect_phase(phase);

//=====================connction of tlm ports of host driver and host sequncer=============//

		h_eth_rx_host_driver.seq_item_port.connect(h_eth_rx_host_sequencer.seq_item_export);
	
	endfunction



endclass

