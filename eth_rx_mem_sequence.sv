//====== mem sequence class =======//

class eth_rx_mem_sequence extends uvm_sequence #(eth_sequence_item);

	`uvm_object_utils(eth_rx_mem_sequence)   //=Factory registration

//===============construction =======================

	function new(string name = "");
		super.new(name);
	endfunction

//==========================task body============================//
task body();
		req=eth_sequence_item :: type_id::create("req");

		start_item(req);

		assert(req.randomize() with {m_pready_i == 1;});
	
		finish_item(req);


	endtask

endclass

