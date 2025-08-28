//======================ethernet mem sequencer =================


class eth_rx_mem_sequencer extends uvm_sequencer #(eth_sequence_item);

//=====================factory registration ============================
	`uvm_component_utils(eth_rx_mem_sequencer)

//============================construction========================
	function new(string name="",uvm_component parent);
		super.new(name,parent);
	endfunction

endclass
