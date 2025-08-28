//===================== ethernet mac driver ==============

class eth_rx_mac_driver extends uvm_driver #(eth_sequence_item);

//==============================function registration ================

	`uvm_component_utils(eth_rx_mac_driver)

	virtual eth_interface h_eth_interface; //virtual interface instance
   	eth_config_class h_eth_config_class; 

//================construction=============================

	function new(string name="", uvm_component parent);
		super.new(name,parent);
	endfunction

//============connect phase==================//

	function void connect_phase(uvm_phase phase);

		super.connect_phase(phase);

//---------------------interface getting-----------------------------//	    
	    assert(uvm_config_db #(virtual eth_interface) :: get(this , this.get_full_name() , "eth_interface", h_eth_interface));
		assert(uvm_config_db #(eth_config_class)::get(null,this.get_full_name(),"eth_config_class",h_eth_config_class));
	
	endfunction


//=====================run phase ============//
	task run_phase(uvm_phase phase);
			req = eth_sequence_item :: type_id::create("req");
		forever@(h_eth_interface.cb_mac_driver_rx)begin

			seq_item_port.get_next_item(req);

			h_eth_interface.cb_mac_driver_rx.mcrs  		<= req.mcrs;
			h_eth_interface.cb_mac_driver_rx.MRxerr  	<= req.MRxerr;
			h_eth_interface.cb_mac_driver_rx.MRxdv  	<= req.MRxdv;
			h_eth_interface.cb_mac_driver_rx.MRxD 		<= req.MRxD;
			seq_item_port.item_done();
		end
	endtask


endclass







