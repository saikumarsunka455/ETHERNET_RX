//======================ethernet host sequencer =================


class eth_rx_host_sequencer extends uvm_sequencer #(eth_sequence_item);

//=====================factory registration ============================
	`uvm_component_utils(eth_rx_host_sequencer)

//============================construction========================
	function new(string name="",uvm_component parent);
		super.new(name,parent);
	endfunction

endclass
