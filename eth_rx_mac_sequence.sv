//====== mac sequence class ==============================//

class eth_rx_mac_sequence extends uvm_sequence #(eth_sequence_item);

	`uvm_object_utils(eth_rx_mac_sequence)   //=Factory registration
//===============config class instance===================//
	eth_config_class h_eth_config_class; 


//===============internal variables======================//
	int rx_bd_memory_loc_addr; // calculate starting location of RXBD.
	bit [3:0] nibble_da_to_payload[$];//========================= storing nibble data into queue for crc calculations
	int generated_crc;                //============== generated crc value is stored in this variable


//===============construction ===========================//

	function new(string name = "");
		super.new(name);
	endfunction

//=================================================================================================================================================================================//---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------//=================================================================================================================================================================================


	task body();
		assert(uvm_config_db #(eth_config_class)::get(null,this.get_full_name(),"eth_config_class",h_eth_config_class));
		req=eth_sequence_item :: type_id::create("req");
		rx_bd_memory_loc_addr = 1024 + h_eth_config_class.TX_BD_NUM*8;	
	    

//==================================== BELOW FOR LOOP IS USED TO TRANSIMIT PACKETS BASED (128 - TXBDNUM) VALUE TIMES
		for(int rx_bd_no_of_frames = h_eth_config_class.TX_BD_NUM; rx_bd_no_of_frames < 128;rx_bd_no_of_frames++)
		begin
			h_eth_config_class.temp_length = h_eth_config_class.RXD[rx_bd_memory_loc_addr][31:16];
			h_eth_config_class.EMPTY = h_eth_config_class.RXD[rx_bd_memory_loc_addr][15];
			MCRS_0;//================MAKING MCRS AND MRXDV AS 0

			if(h_eth_config_class.MODER[2]==1)//============MODER[2] INDICATES nopre i.e nopre = 1 packet shouldnt consist of preamble else it should consider preamble. 
			begin
				SFD();	
			end
			else
			begin
				PREAMBLE();
				SFD();
			end
	
			DESTINATION_ADDR();

			SOURCE_ADDR();

			LENGTH();

			PAYLOAD();

			CRC();
		
			#1200;
		end

	endtask

	
//=================================================================================================================================================================================//-------------------------------------------------------------------MCRS DISABLE TASK---------------------------------------------------------------------------------------------//=================================================================================================================================================================================


  	task MCRS_0;
		`uvm_do_with(req,{MRxD == 'B0101;MRxdv == 0;mcrs == 0;})
	endtask

//=================================================================================================================================================================================//-------------------------------------------------------------------PREAMBLE GENERATION-------------------------------------------------------------------------------------------//=================================================================================================================================================================================




	task PREAMBLE;

		repeat(14)
		begin
			`uvm_do_with(req,{MRxD == 'B0101;MRxdv == 1;mcrs == 1;})
		end
	endtask

//=================================================================================================================================================================================//-------------------------------------------------------------------SFD GENERATION------------------------------------------------------------------------------------------------//=================================================================================================================================================================================


	task SFD;
			`uvm_do_with(req,{MRxD == 'B0101;MRxdv == 1;})
			#40;	
			`uvm_do_with(req,{MRxD == 'B1101;MRxdv == 1;})	
	endtask
	

//=================================================================================================================================================================================//--------------------------------------------------------------------DESTINATION ADDRESS GENERATION-------------------------------------------------------------------------------//=================================================================================================================================================================================



	task DESTINATION_ADDR;
		for(int i = 15;i > 0;i-=4)	
		begin
			`uvm_do_with(req,{MRxD == h_eth_config_class.MAC_ADDR1[i -: 4];})
			nibble_da_to_payload.push_back(req.MRxD);
		end
		repeat(8)
		begin
			`uvm_do_with(req,{MRxD == 'd0;MRxdv == 1;})
			nibble_da_to_payload.push_back(req.MRxD);
		end
	endtask

//=================================================================================================================================================================================//---------------------------------------------------------------------SOURCE ADDRESS GENERATION-----------------------------------------------------------------------------------//=================================================================================================================================================================================


	task SOURCE_ADDR;
		`uvm_do_with(req,{MRxD == 0;})
			nibble_da_to_payload.push_back(req.MRxD);
		`uvm_do_with(req,{MRxD == h_eth_config_class.MIIADDRESS[3:0];})
			nibble_da_to_payload.push_back(req.MRxD);
		repeat(10)
		begin
			`uvm_do_with(req,{MRxD == 'd0;})
			nibble_da_to_payload.push_back(req.MRxD);
		end

	endtask

//=================================================================================================================================================================================//---------------------------------------------------------------------LENGHT GENERATION-------------------------------------------------------------------------------------------
//=================================================================================================================================================================================


	task LENGTH;
			`uvm_do_with(req,{MRxD == h_eth_config_class.RXD[rx_bd_memory_loc_addr][27:24];})
			nibble_da_to_payload.push_back(req.MRxD);
			`uvm_do_with(req,{MRxD == h_eth_config_class.RXD[rx_bd_memory_loc_addr][31:28];})
			nibble_da_to_payload.push_back(req.MRxD);
			`uvm_do_with(req,{MRxD == h_eth_config_class.RXD[rx_bd_memory_loc_addr][19:16];})
			nibble_da_to_payload.push_back(req.MRxD);
			`uvm_do_with(req,{MRxD == h_eth_config_class.RXD[rx_bd_memory_loc_addr][23:20];})
			nibble_da_to_payload.push_back(req.MRxD);

	endtask

//=================================================================================================================================================================================//---------------------------------------------------------------------PAYLOAD GENERATION------------------------------------------------------------------------------------------//=================================================================================================================================================================================


	task PAYLOAD;
		repeat(h_eth_config_class.RXD[rx_bd_memory_loc_addr][31:16] * 2)
		begin
			`uvm_do(req);
			nibble_da_to_payload.push_back(req.MRxD);
		end
	
		if(h_eth_config_class.RXD[rx_bd_memory_loc_addr][31:16] < 46 && h_eth_config_class.MODER[15] == 1)
		begin
			repeat( (46 - h_eth_config_class.RXD[rx_bd_memory_loc_addr][31:16])*2)
			 begin
				`uvm_do_with(req,{MRxD == 'd0;})
			nibble_da_to_payload.push_back(req.MRxD);
			 end
		end
	//	$display($time,"======================== nibble_da_to_payload = %p==== nibble_da_to_payload.size = %d",nibble_da_to_payload,nibble_da_to_payload.size());
		
		crc_generation();//========================= task is used to generate crc value 
		
		rx_bd_memory_loc_addr+=8;
		
	endtask

//=================================================================================================================================================================================//----------------------------------------------------------------------CRC DRIVING TASK-------------------------------------------------------------------------------------------//=================================================================================================================================================================================
	task CRC;
		  for(int i = 28;i >= 0;i-=4) 
			`uvm_do_with(req,{MRxD == generated_crc[i+:4] ;})
			`uvm_do_with(req,{MRxD == 'hf;MRxdv==0;})
	endtask








//=================================================================================================================================================================================//----------------------------------------------------------------------CRC GENERATION---------------------------------------------------------------------------------------------//================================================================================================================================================================================
	task crc_generation(); 
		bit [3:0] data;
		bit [31:0] crc_variable = 32'hffff_ffff; // initializing the variable
		bit [31:0] crc_next; 
		int nibble_size;
		
		nibble_size = nibble_da_to_payload.size;
	
			for(int i=0;i<nibble_size;i++) 
			begin
			data = nibble_da_to_payload.pop_front;
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
		generated_crc[31:28] = {~crc_variable[28],~crc_variable[29],~crc_variable[30],~crc_variable[31]};
		generated_crc[27:24] = {~crc_variable[24],~crc_variable[25],~crc_variable[26],~crc_variable[27]};
		generated_crc[23:20] = {~crc_variable[20],~crc_variable[21],~crc_variable[22],~crc_variable[23]};
		generated_crc[19:16] = {~crc_variable[16],~crc_variable[17],~crc_variable[18],~crc_variable[19]};
		generated_crc[15:12] = {~crc_variable[12],~crc_variable[13],~crc_variable[14],~crc_variable[15]};
		generated_crc[11:8] = {~crc_variable[8],~crc_variable[9],~crc_variable[10],~crc_variable[11]};
		generated_crc[7:4] = {~crc_variable[4],~crc_variable[5],~crc_variable[6],~crc_variable[7]};
		generated_crc[3:0] = {~crc_variable[0],~crc_variable[1],~crc_variable[2],~crc_variable[3]};
	
	endtask
endclass
