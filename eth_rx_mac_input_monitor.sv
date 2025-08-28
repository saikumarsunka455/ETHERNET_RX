class eth_rx_mac_input_monitor extends uvm_monitor;
	//============= FACTORY REGISTRATION
	`uvm_component_utils(eth_rx_mac_input_monitor)

//================== instances =========	
	 eth_sequence_item h_seq_item;
	virtual eth_interface h_eth_interface;
   	eth_config_class h_eth_config_class; 
	//----------------------- byte queue storing -------
		byte_queue byte_payload_storing_que_in_mon;
//============================= internal variables ============
//--------- preamble_flag indicates the preamble pass or fail and sfd_flag indicates the SFD pass or fail ----
	bit preamble_flag , sfd_flag;
//------------ count to count the nibble by nibble checking ----
	int count;
//------------------ count to store the byte into a variable ------
	bit [7:0]payload_byte_store;
	bit [1:0]count_byte; 

	//~~~~~~~~~Component_Construction~~~~~~//
	function new (string name="eth_rx_mac_input_monitor",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	//========== ANALYSIS PORT ====================
	uvm_analysis_port #(byte_queue) h_mac_input_monitor_port;
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);	
		h_mac_input_monitor_port = new("h_mac_input_monitor_port",this);
		h_seq_item = eth_sequence_item::type_id::create("h_seq_item",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		uvm_config_db #(virtual eth_interface) :: get(this , "" , "eth_interface", h_eth_interface);
        assert(uvm_config_db #(eth_config_class)::get(null,this.get_full_name(),"eth_config_class",h_eth_config_class));

	endfunction


//================= run phase ===============
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever@(h_eth_interface.cb_mac_monitor_rx)
		begin
            
			h_seq_item.MRxD = h_eth_interface.cb_mac_monitor_rx.MRxD;
			h_seq_item.MRxerr = h_eth_interface.cb_mac_monitor_rx.MRxerr;
			h_seq_item.MRxdv = h_eth_interface.cb_mac_monitor_rx.MRxdv;
			h_seq_item.mcrs = h_eth_interface.cb_mac_monitor_rx.mcrs;
//------------------- checking RxEN =1 and MRxDV =1 -------
			if(h_eth_config_class.MODER[0] && h_seq_item.MRxdv && h_eth_config_class.EMPTY) begin
				count = count + 1;	//------ count increment for every nibble 
				monitor_check;		//------ calling monitor check task 
//$display($time," ***************************** in mac input monitor  %p --- rxen %0d mrxdv  %0d  -mrxd  %0d --- count  %0d ---- count_byte  %0d ---- preamble_flag  %b  sfd_flag  %b --- length  %0d ",byte_payload_storing_que_in_mon,h_eth_config_class.MODER[0],h_seq_item.MRxdv,h_seq_item.MRxD,count,count_byte,preamble_flag,sfd_flag,h_eth_config_class.temp_length);
			end
			
			h_mac_input_monitor_port.write(byte_payload_storing_que_in_mon);

			if(h_eth_config_class.delete_flag) begin 
//$display($time," ^^^^^^^^^^ input monitor  %p ",byte_payload_storing_que_in_mon);
			byte_payload_storing_que_in_mon.delete();
			end
		end
	endtask

//*******************************************************************************************************************************
//*******************************************************************************************************************************
//============================ THIS DESCRIPTION IS FOR WITH PREAMBLE =========
/*
		count 1 to 14 --- 14 clock pulses preamble will come and check the preamble so call preamble_check() task 
		count 15 and 16 --- SFD will come and check the SFD so call SFD_check() task		
		from count 17 to 28 --- DESTINATION ADDRESS --- 6 octets --- 12 nibbles (16+12=28)
		from count 29 to 40 --- SOURCE ADDRESS -------- 6 octets --- 12 nibbles (28+12=40)
		from count 41 to 44 --- LENGTH ---------------- 2 octets --- 4 nibbles (40+4=44)
		from 45 to ((45+length*2)-1) -- PAYLOAD ------- length octets --- length *2  ---- payload_data_storing() task
		after completion of payload and CRC receiving the count will be 0 ---
*/

//============================ THIS DESCRIPTION IS FOR WITHOUT PREAMBLE =========
/*
		count 1 and 2 --- SFD will come and check the SFD so call SFD_check() task		
		from count 3 to 14 --- DESTINATION ADDRESS --- 6 octets --- 12 nibbles (2+12=14)
		from count 15 to 26 --- SOURCE ADDRESS -------- 6 octets --- 12 nibbles (14+12=26)
		from count 27 to 30 --- LENGTH ---------------- 2 octets --- 4 nibbles (26+4=30)
		from 31 to ((31+length*2)-1) -- PAYLOAD ------- length octets --- length *2  ---- payload_data_storing() task
		after completion of payload and CRC receiving the count will be 0 ---
*/
//*******************************************************************************************************************************
//*******************************************************************************************************************************


//================= monitor checking task calling individual tasks based on count =====
	task monitor_check;
//================ checking nopre field ==============
		if(!h_eth_config_class.MODER[2]) begin
			if(count<=14) preamble_check;
			else if((count==15 || count==16) && !preamble_flag) SFD_check;
			else if((count>=45 && count<=((45+(h_eth_config_class.temp_length*2))-1)) && !sfd_flag && (h_eth_config_class.temp_length>=46)) payload_data_storing;
			else if((count>=45 && count<=((45+(46*2))-1)) && !sfd_flag && (h_eth_config_class.temp_length<46)) payload_data_storing;
			else if((count == ((45+(h_eth_config_class.temp_length*2))+8)-1) && (h_eth_config_class.temp_length>=46)) count=0;
			else if((count == ((45+(46*2))+8)-1) && (h_eth_config_class.temp_length<46)) count=0;
		end
		else begin
			if(count==1 || count==2) SFD_check;
			else if((count>=31 && count<=((31+(h_eth_config_class.temp_length*2))-1)) && !sfd_flag && (h_eth_config_class.temp_length>=46)) payload_data_storing;
			else if((count>=31 && count<=((31+(46*2))-1)) && !sfd_flag && (h_eth_config_class.temp_length<46)) payload_data_storing;
			else if((count == ((31+(h_eth_config_class.temp_length*2))+8)-1) && (h_eth_config_class.temp_length>=46)) count=0;
			else if((count == ((31+(46*2))+8)-1) && (h_eth_config_class.temp_length<46)) count=0;
		end
	endtask
//============== preamble checking task ========
	task preamble_check;
		if(h_seq_item.MRxD=='b0101) preamble_flag=0;
		else preamble_flag=1;
	endtask
//================== SFD checking task =========
	task SFD_check;
		if(count==15 || count ==1) 
			if(h_seq_item.MRxD=='b0101) sfd_flag=0;
			else sfd_flag=1;
		else if(count==16 || count==2)
			if(h_seq_item.MRxD=='b1101) sfd_flag=0;
			else sfd_flag=1;
	endtask

/*
		count_byte --- is for to count the nibbles to became byte 
		if count_byte =0 then first nibble will come then it stored into an MSB of 8 bit variable(payload_byte_store)--- [7:4]
		if count_byte =1 then second nibble will come then it stored into an LSB of 8 bit variable  --------- [3:0]
		after two nibbles stored then the count_byte be 2 then it became 0 and this 8 bit variable(payload_byte_store) push_back into the queue --
*/	


//================ payload collection task =======
	task payload_data_storing;
		if(count_byte==0) payload_byte_store[7:4]=h_seq_item.MRxD;	
		else if(count_byte==1) payload_byte_store[3:0]=h_seq_item.MRxD;
		count_byte++;
		if(count_byte ==2) begin
			byte_payload_storing_que_in_mon.push_back(payload_byte_store);
			count_byte=0;
		end
	endtask
	
/*	function void final_phase(uvm_phase phase);
		super.final_phase(phase);
		$display($time," $$$$$$$$$$$$$$$$$$$$$$$$$  byte_payload_storing_que_in_mon  %p ----- size  %0d ",byte_payload_storing_que_in_mon,byte_payload_storing_que_in_mon.size);
	endfunction*/
endclass

