class eth_rx_mem_output_monitor extends uvm_monitor;
	//============= FACTORY REGISTRATION
	`uvm_component_utils(eth_rx_mem_output_monitor)

//================== instances =========	
	 eth_sequence_item h_seq_item;
	virtual eth_interface h_eth_interface;
   	eth_config_class h_eth_config_class; 
	//----------------------- byte queue storing -------
	byte_queue byte_payload_storing_que_out_mon;

//--------------------------------------------------------//
//---------------------internal fields--------------------//
//--------------------------------------------------------//

	bit[7:0] frame_byte_queue[$]; //------frame-------------//
	bit[7:0] source_addr_q[6];    //------source addr ------//
	bit[7:0] dist_addr_q[6];      //------distnation addr---//
	bit[7:0] length_q[2];         //------length -----------//
	bit[7:0] crc_q[4];            //------crc---------------//
	bit flag;

	int bit32_flag; //-------------------- internal rxbd_count---------
	//-------- for respective bd_adr--------------//
	bit[15:0] rx_bd_addr;
	//-------- for total frame receive ---------------------//
	int bd_done;

	//---------flag for check initial bd_addr ----------//	
	bit bd_loc_flag;

	//---------for nummber bds get received --------------// 
	//---------increment it for every bd receive----------//
	int bd_count;

	//-----------store as nibbles from frame----------------//
	bit[3:0] nibble_crc[$];
	//------------queue for active nibbles of nibble_crc queue
	bit[3:0] nibble_crc_temp[$];

//=============== uvm event pool =======
	uvm_event event_out_mon;

//--------------------------------------------------------//
//---------------------internal fields--------------------//
//--------------------------------------------------------//



	//~~~~~~~~~Component_Construction~~~~~~//
	function new (string name="eth_rx_mem_output_monitor",uvm_component parent);
		super.new(name,parent);
	endfunction
	
	//========== ANALYSIS PORT ====================
	uvm_analysis_port #(byte_queue) h_mem_output_monitor_port;
	
	function void build_phase(uvm_phase phase);
		super.build_phase(phase);	
		h_mem_output_monitor_port = new("h_mem_output_monitor_port",this);
		h_seq_item = eth_sequence_item::type_id::create("h_seq_item",this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		uvm_config_db #(virtual eth_interface) :: get(this , "" , "eth_interface", h_eth_interface);
        assert(uvm_config_db #(eth_config_class)::get(null,this.get_full_name(),"eth_config_class",h_eth_config_class));
		event_out_mon = uvm_event_pool :: get_global("event_sb_out");

	endfunction


//================= run phase ===============
	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever@(h_eth_interface.cb_host_mem_monitor)
		begin
			h_seq_item.prstn_i = h_eth_interface.cb_host_mem_monitor.prstn_i;
			h_seq_item.m_penable_o = h_eth_interface.cb_host_mem_monitor.m_penable_o;
			h_seq_item.m_pwrite_o = h_eth_interface.cb_host_mem_monitor.m_pwrite_o;
			h_seq_item.m_psel_o = h_eth_interface.cb_host_mem_monitor.m_psel_o;
			h_seq_item.m_pwdata_o = h_eth_interface.cb_host_mem_monitor.m_pwdata_o;
			h_seq_item.m_paddr_o = h_eth_interface.cb_host_mem_monitor.m_paddr_o;
			h_seq_item.m_prdata_i = h_eth_interface.cb_host_mem_monitor.m_prdata_i;
			h_seq_item.m_pready_i = h_eth_interface.cb_host_mem_monitor.m_pready_i;
			
			frame_collection;

		end
	endtask

	

	//-------------------------task for frame colleting----------------------------
	task frame_collection;

		if(h_seq_item.m_psel_o && h_seq_item.m_penable_o && h_seq_item.m_pwrite_o&&h_seq_item.m_pready_i) begin
//			if(h_eth_config_class.RXD[1024+((h_eth_config_class.TX_BD_NUM)*8)+4]==m_paddr_o) 
			begin

				//-------------------colleting 32bit frame for every edge and storing into into byte byte into queue---------------
				//-------------------colleting frame------------------------------------------------------------------------------
				frame_byte_queue.push_back({h_seq_item.m_pwdata_o[27:24] , h_seq_item.m_pwdata_o[31:28]});
				frame_byte_queue.push_back({h_seq_item.m_pwdata_o[19:16] , h_seq_item.m_pwdata_o[23:20]});
				frame_byte_queue.push_back({h_seq_item.m_pwdata_o[11:8] , h_seq_item.m_pwdata_o[15:12]});
				frame_byte_queue.push_back({h_seq_item.m_pwdata_o[3:0] , h_seq_item.m_pwdata_o[7:4]});
	

				//-------------------colleting 32bit frame for every edge and storing into nibble nibble into queue for crc check---------------
				nibble_crc_temp.push_back(h_seq_item.m_pwdata_o[27:24]);
				nibble_crc_temp.push_back(h_seq_item.m_pwdata_o[31:28]);
				nibble_crc_temp.push_back(h_seq_item.m_pwdata_o[19:16]);
				nibble_crc_temp.push_back(h_seq_item.m_pwdata_o[23:20]);
				nibble_crc_temp.push_back(h_seq_item.m_pwdata_o[11:8]);
				nibble_crc_temp.push_back(h_seq_item.m_pwdata_o[15:12]);
				nibble_crc_temp.push_back(h_seq_item.m_pwdata_o[3:0]);
				nibble_crc_temp.push_back(h_seq_item.m_pwdata_o[7:4]);

			//----------------increment for every 32bit received---------------------------------
			bit32_flag++; 
			
			//---------------storing initial rx_bd_addr-----------------------------------------
			if(!bd_loc_flag) begin
				bd_loc_flag =1;
				rx_bd_addr = 1024+(h_eth_config_class.TX_BD_NUM*8);
			end


				//-----------------if frame length is multiples 4 then  bd_done will be length/4 times ---- 80/4 = 20-----

			if(!flag) begin
				if((18+h_eth_config_class.RXD[rx_bd_addr][31:16])%4==0) begin
					bd_done = (18+h_eth_config_class.RXD[rx_bd_addr][31:16])/4;
					flag = 1;
				end
				else begin
				//-----------------if frame length is not multiples 4 then  bd_done will be length/4+1 time ---- 81/4 = 21-----
					bd_done = (18+h_eth_config_class.RXD[rx_bd_addr][31:16])/4+1; //2+6+6+payload_length+4
					flag = 1;
				end
			end

			//-----------------if frame length is multiples 4 then  bd_done will be length/4 times ---- 80/4 = 20-----
			if((18+h_eth_config_class.RXD[rx_bd_addr][31:16])%4==0)
				bd_done = (18+h_eth_config_class.RXD[rx_bd_addr][31:16])/4;
			else
			//-----------------if frame length is not multiples 4 then  bd_done will be length/4+1 time ---- 81/4 = 21-----
				bd_done = (18+h_eth_config_class.RXD[rx_bd_addr][31:16])/4+1;

/*				//------------distination addr-------------------
				dist_addr_check;
				//------------source addr ------------------------
				source_addr_check;
				//-------------length check-----------------------
				length_check;
				//-------------payload colletion-----------------
				payload_check;
				//------------crc collect----------------
				crc_collect;*/
					$display($time,"----bit32_flag = %0d---",bit32_flag);
					$display($time,"----bd_done = %0d---",bd_done);


				//----------------receive total frame length------------------------
				if(bit32_flag==bd_done/* && h_eth_config_class.RXD[rx_bd_addr][15]*/) begin

				//------------distination addr-------------------
				dist_addr_check;
				//------------source addr ------------------------
				source_addr_check;
				//-------------length check-----------------------
				length_check;
				//-------------payload colletion-----------------
				payload_check;
				//------------crc collect----------------
				crc_collect;

//$display($time," ********************** %p ",byte_payload_storing_que_out_mon);

					h_mem_output_monitor_port.write(byte_payload_storing_que_out_mon);
					event_out_mon.trigger();//----- event trigger for scoreboard comparision after 1 bd ---


$display($time," &&&&&&&&&&&&&&&&&&&&&& under trigger &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& size  %0d ---- flag  %b \n\n\n\n\n",byte_payload_storing_que_out_mon.size,h_eth_config_class.delete_flag);



					//----------------------send crc based on frame length only--------------------------
					for(int i=0;i<((18+h_eth_config_class.RXD[rx_bd_addr][31:16])*2);i++)
						nibble_crc[i] = nibble_crc_temp[i];
						
					crc_check;					
					//$display($time,"----rx_bd_addr = %0d---",h_eth_config_class.RXD[rx_bd_addr][31:16]);
					//$display($time,"----bit32_flag = %0d---",bit32_flag);
					//$display($time,"----bd_done = %0d---",bd_done);
					//$display($time,"----FRAME = %p  size=%0d ",frame_byte_queue,frame_byte_queue.size);
					//$display($time,"---DIST-= %p",dist_addr_q);
					//$display($time,"---SOURCE--= %p",source_addr_q);
					//$display($time,"---Length--= %p",length_q);
					//$display($time,"---Length--= %p",crc_q);

					//------------------increment bd after every receive----------------------
					bd_count++;
					//$display($time,"---bd_number={%0d}----payload-----= %p --size-----bd_count------ ",bd_count,byte_payload_storing_que_out_mon,byte_payload_storing_que_out_mon.size);
					//------increment the next bd_addr after respective frame --------------------------
					rx_bd_addr+=8; 
					//---------------deleting  and payload queue frame queue afeter payload trasmitting----------------
					frame_byte_queue.delete();
					nibble_crc_temp.delete();
					nibble_crc.delete();
					flag=0;
					if(h_eth_config_class.delete_flag) byte_payload_storing_que_out_mon.delete();
					//--------------initlize flag after frame trasmitting ----------------------
					bit32_flag = 0;
					bd_done = 0;
				end
			end
		end	

	endtask

	//----------------here distination addr of the rx is source addr of the tx ----------------
	//-----------------then here campare source addr resister from config class to received distination addr from dut------------------
	task dist_addr_check;
		//---------------distnation addr has store from 0-5 index locations in the frame---------------	
		if(frame_byte_queue.size>=6) 
		begin
			for(int i;i<6;i++) 
				dist_addr_q[i] = frame_byte_queue[i];	
			//-------------------------1st receive mac1 byte0 then after mac1 byte1 ----------------------
			///-------------------------here MAC_ADDR1[15:8] = is byte0 and MAC_ADDR1[7:0] = byte1-----------------
				if((dist_addr_q[0]==h_eth_config_class.MAC_ADDR1[15:8]) && (dist_addr_q[1]==h_eth_config_class.MAC_ADDR1[7:0]))
					`uvm_info("DIST_ADDR_PASS",$sformatf("DIST_PASS"),UVM_HIGH)
				else	
					`uvm_info("DIST_ADDR_FAIL",$sformatf("DIST_FAIL"),UVM_HIGH)
		end

	endtask


	//----------------here source addr of the rx is distination addr of the tx ----------------
	//-----------------then here campare distination addr resister from config class to received source addr from dut------------------
	task source_addr_check;
		//---------------source addr has store from 6-11 index in the frame---------------
		if(frame_byte_queue.size>=12) begin
			for(int i=6;i<12;i++)
				source_addr_q[i-6] = frame_byte_queue[i];
			//------------------{3'b0,FAID[4],FAID[3:0]}-------------------------//
			if(source_addr_q[0]==h_eth_config_class.MIIADDRESS[7:0])
				`uvm_info("SOURCE_ADDR_PASS",$sformatf("SOURCE_PASS"),UVM_HIGH)
			else
				`uvm_info("SOURCE_ADDR_FAIL",$sformatf("SOURCE_FAIL"),UVM_HIGH)

		end


	endtask

	//------------------task for length check---------------------------------
	task length_check;

		//---------------length has store from 12-13 index in the frame---------------
		if(frame_byte_queue.size>=14) begin
			for(int i=12;i<14;i++)
				length_q[i-12] = {frame_byte_queue[i][3:0] , frame_byte_queue[i][7:4]};
			if(length_q[1]==h_eth_config_class.RXD[rx_bd_addr][23:16]&& length_q[0]==h_eth_config_class.RXD[rx_bd_addr][31:24])
				`uvm_info("LENGTH PASS",$sformatf("LENGTH_PASS"),UVM_NONE)
			else
				`uvm_info("LENGTH FAIL",$sformatf("LENGTH_FAIL"),UVM_NONE)
		
		end

	endtask


	//------------------------task for payload store into queue--------------------
	task payload_check;
		//---------------payload has store from 14 to length of respestive rx_bd index in the frame---------------
		if(frame_byte_queue.size>=(14+h_eth_config_class.RXD[rx_bd_addr][31:16])) begin
		//	$display($time,"h_eth_config_class.RXD[rx_bd_addr]=%0d",h_eth_config_class.RXD[rx_bd_addr][31:16]);
			//-----------------loop itrate from length time of respetive bd-------------------
			for(int i=14;i<h_eth_config_class.RXD[rx_bd_addr][31:16]+14;i++) begin
				byte_payload_storing_que_out_mon[i-14] = frame_byte_queue[i];
			end
		end

	endtask

	//------------------colecting crc and it no use --------------------------------------
	task crc_collect;
		int local_length;
		local_length = (h_eth_config_class.RXD[rx_bd_addr][31:16]); //respective length
		
		if(frame_byte_queue.size>=(local_length+18)) begin
			for(int i=(14+local_length); i<(18+local_length); i++)begin
				crc_q[i-(14+local_length)] = frame_byte_queue[i];
			end
		end
		
	endtask


	//----------------------------crc calculating task----------------------------------
	task crc_check();
		bit [3:0] data;
		bit [31:0] crc_variable = 32'hffff_ffff; // initializing the variable
		bit [31:0] crc_next; 
		bit [31:0] calculated_magic_number;
		int nibble_size;
		
		nibble_size = nibble_crc.size;
	
			for(int i=0;i<nibble_size;i++) 
			begin
			data = nibble_crc.pop_front;
                        
			data = {<<{data}}; 

			crc_next[0] =    (data[0] ^ crc_variable[28]); 
			crc_next[1] =    (data[1] ^ data[0] ^ crc_variable[28] ^ crc_variable[29]); 
			crc_next[2] =    (data[2] ^ data[1] ^ data[0] ^ crc_variable[28] ^ crc_variable[29] ^ crc_variable[30]); 
			crc_next[3] =    (data[3] ^ data[2] ^ data[1] ^ crc_variable[29] ^ crc_variable[30] ^ crc_variable[31]); 
			crc_next[4] =    (data[3] ^ data[2] ^ data[0] ^ crc_variable[28] ^ crc_variable[30] ^ crc_variable[31]) ^ crc_variable[0]; 
			crc_next[5] =    (data[3] ^ data[1] ^ data[0] ^ crc_variable[28] ^ crc_variable[29] ^ crc_variable[31]) ^ crc_variable[1]; 
			crc_next[6] =    (data[2] ^ data[1] ^ crc_variable[29] ^ crc_variable[30]) ^ crc_variable[2]; 
			crc_next[7] =    (data[3] ^ data[2] ^ data[0] ^ crc_variable[28] ^ crc_variable[30] ^ crc_variable[31]) ^ crc_variable[3]; 
			crc_next[8] =    (data[3] ^ data[1] ^ data[0] ^ crc_variable[28] ^ crc_variable[29] ^ crc_variable[31]) ^ crc_variable[4]; 
			crc_next[9] =    (data[2] ^ data[1] ^ crc_variable[29] ^ crc_variable[30]) ^ crc_variable[5]; 
			crc_next[10] =    (data[3] ^ data[2] ^ data[0] ^ crc_variable[28] ^ crc_variable[30] ^ crc_variable[31]) ^ crc_variable[6]; 
			crc_next[11] =    (data[3] ^ data[1] ^ data[0] ^ crc_variable[28] ^ crc_variable[29] ^ crc_variable[31]) ^ crc_variable[7]; 
			crc_next[12] =    (data[2] ^ data[1] ^ data[0] ^ crc_variable[28] ^ crc_variable[29] ^ crc_variable[30]) ^ crc_variable[8];
			crc_next[13] =    (data[3] ^ data[2] ^ data[1] ^ crc_variable[29] ^ crc_variable[30] ^ crc_variable[31]) ^ crc_variable[9]; 
			crc_next[14] =    (data[3] ^ data[2] ^ crc_variable[30] ^ crc_variable[31]) ^ crc_variable[10]; 
			crc_next[15] =    (data[3] ^ crc_variable[31]) ^ crc_variable[11]; 
			crc_next[16] =    (data[0] ^ crc_variable[28]) ^ crc_variable[12]; 
			crc_next[17] =    (data[1] ^ crc_variable[29]) ^ crc_variable[13]; 
			crc_next[18] =    (data[2] ^ crc_variable[30]) ^ crc_variable[14]; 
			crc_next[19] =    (data[3] ^ crc_variable[31]) ^ crc_variable[15]; 
			crc_next[20] = 	  crc_variable[16]; 
			crc_next[21] =    crc_variable[17]; 
			crc_next[22] =    (data[0] ^ crc_variable[28]) ^ crc_variable[18]; 
			crc_next[23] =    (data[1] ^ data[0] ^ crc_variable[29] ^ crc_variable[28]) ^ crc_variable[19]; 
			crc_next[24] =    (data[2] ^ data[1] ^ crc_variable[30] ^ crc_variable[29]) ^ crc_variable[20]; 
			crc_next[25] =    (data[3] ^ data[2] ^ crc_variable[31] ^ crc_variable[30]) ^ crc_variable[21]; 
			crc_next[26] =    (data[3] ^ data[0] ^ crc_variable[31] ^ crc_variable[28]) ^ crc_variable[22]; 
			crc_next[27] =    (data[1] ^ crc_variable[29]) ^ crc_variable[23]; 
			crc_next[28] =    (data[2] ^ crc_variable[30]) ^ crc_variable[24];
			crc_next[29] =    (data[3] ^ crc_variable[31]) ^ crc_variable[25]; 
			crc_next[30] =    crc_variable[26]; 
			crc_next[31] =    crc_variable[27]; 

			crc_variable = crc_next;

			end
		
		calculated_magic_number = crc_variable;
		if(32'hc704dd7b==calculated_magic_number) begin

			`uvm_info("*******MAGIC CRC MATCH********" , $sformatf("========MAGIC CRC PASS======") , UVM_LOW);
	
		end

		else begin
			`uvm_info("*******MAGIC CRC MISMATCH********" , $sformatf("========MAGIC CRC FAIL=====") , UVM_LOW);
		end

		
	endtask
	


	

endclass



