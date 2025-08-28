//==================host INPUT MONITOR= dummy input monitor to store into config class for registers configurations properly ====================//

class eth_rx_host_monitor extends uvm_monitor;

//================factory registration=========================//

	`uvm_component_utils(eth_rx_host_monitor)

//===========construction==================//

	function new(string name = "" , uvm_component parent);

		super.new(name , parent);

	endfunction

//============ instances ==================//

	virtual eth_interface h_eth_interface;

	eth_sequence_item h_eth_sequence_item;
      
   	eth_config_class h_eth_config_class; 
       
  
//============build phase==================//

	function void build_phase(uvm_phase phase);

		super.build_phase(phase);
	
//==========object creation========================//
		h_eth_sequence_item = new("h_eth_sequence_item"); 

    endfunction


//============connect phase==================//

	function void connect_phase(uvm_phase phase);

		super.connect_phase(phase);

	    uvm_config_db #(virtual eth_interface) :: get(this , this.get_full_name() , "eth_interface", h_eth_interface);
 		
        assert(uvm_config_db #(eth_config_class)::get(null,this.get_full_name(),"eth_config_class",h_eth_config_class));
	
	endfunction


//====================RUN PHASE==================//



	task run_phase(uvm_phase phase);
		super.run_phase(phase);
                 
      forever @(h_eth_interface.cb_host_mem_monitor) begin//{
        
      
             
			h_eth_sequence_item.prstn_i = h_eth_interface.cb_host_mem_monitor.prstn_i;
			h_eth_sequence_item.psel_i = h_eth_interface.cb_host_mem_monitor.psel_i;
			h_eth_sequence_item.penable_i = h_eth_interface.cb_host_mem_monitor.penable_i;
			h_eth_sequence_item.pwrite_i = h_eth_interface.cb_host_mem_monitor.pwrite_i;
			h_eth_sequence_item.pwdata_i = h_eth_interface.cb_host_mem_monitor.pwdata_i;
			h_eth_sequence_item.paddr_i = h_eth_interface.cb_host_mem_monitor.paddr_i;
			h_eth_sequence_item.pready_o = h_eth_interface.cb_host_mem_monitor.pready_o;


//-----------------updating on config class----------------------//
		if(h_eth_sequence_item.prstn_i && h_eth_sequence_item.pwrite_i && h_eth_sequence_item.psel_i && h_eth_sequence_item.penable_i && h_eth_sequence_item.pready_o) begin//{ 

				
			if(h_eth_sequence_item.paddr_i == 48) h_eth_config_class.MIIADDRESS = h_eth_sequence_item.pwdata_i;
			else if(h_eth_sequence_item.paddr_i == 64) h_eth_config_class.MAC_ADDR0 = h_eth_sequence_item.pwdata_i;
			else if(h_eth_sequence_item.paddr_i == 68) h_eth_config_class.MAC_ADDR1 = h_eth_sequence_item.pwdata_i;
			else if(h_eth_sequence_item.paddr_i == 32) h_eth_config_class.TX_BD_NUM = h_eth_sequence_item.pwdata_i;
			else if(h_eth_sequence_item.paddr_i>=1024 && h_eth_sequence_item.paddr_i <=2047) h_eth_config_class.RXD[h_eth_sequence_item.paddr_i] = h_eth_sequence_item.pwdata_i;
			else if(h_eth_sequence_item.paddr_i == 8) h_eth_config_class.INT_MASK = h_eth_sequence_item.pwdata_i;
			else if(h_eth_sequence_item.paddr_i == 4) h_eth_config_class.INT_SOURCE = h_eth_sequence_item.pwdata_i;
			else if(h_eth_sequence_item.paddr_i == 0) h_eth_config_class.MODER = h_eth_sequence_item.pwdata_i;

  		end//}





	end//}
				
	endtask   
endclass

