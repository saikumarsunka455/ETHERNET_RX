
//====== sequence item class =======//

class eth_sequence_item extends uvm_sequence_item;

//==================== factory construction ============
		`uvm_object_utils(eth_sequence_item)
//================ construction ==================
	function new(string name = "");
		super.new(name);
	endfunction


//====================== signal declaration ============


//----------------rand variables------------------------//
//---------------host signals
	rand bit prstn_i , psel_i , pwrite_i , penable_i;
	rand bit [31:0]paddr_i , pwdata_i;

//--------------------memory signals-----------
	rand bit[31:0]m_prdata_i;
	rand bit m_pready_i;
//----------------non random variables----------------//
//-------------host signals-------------------
	bit [31:0]prdata_o;
	bit int_o , pready_o;

//-------------memory signals----------------
	bit [31:0]m_pwdata_o,m_paddr_o;
	bit m_psel_o,m_pwrite_o,m_penable_o;
    
//-------------- tx mac signals -------
	rand bit mcrs;
	bit MTxerr,MTxen;
	bit [3:0] MTxD;

//-----------=rx_mac_signals-------------

	rand bit [3:0]MRxD;
	rand bit MRxdv;
	rand bit MRxerr;

//---------------- internal fields-------------------

 rand bit [7:0] TX_BD_NUM;

 rand bit [15:0] Len_Tx;

 rand bit [15:0] Len_Rx;

 rand bit  PAD;

 rand bit  HUGEN;

 rand bit  FULLD;

 rand bit  LOOPBACK;

 rand bit  IFG;

 rand bit  PRO;

 rand bit  BRO;

 rand bit  NOPRE;

 rand bit  TXEN;

 rand bit  RXEN;

 rand bit TXE_M;

 rand bit TXB_M;

 rand bit RXE_M;

 rand bit RXB_M;

 rand bit RD;

 rand bit MT;

 rand bit IRQ;

 rand bit[31:0] TX_PNTR;

 rand bit[31:0] RX_PNTR;

 bit[15:0] length_q[$];

	bit tx_bd_num_flag_randomize;
rand int TEMP;
 enum {good_frame,bad_frame,good_frame_len_lt_46,good_frame_len_gt_1500,good_frame_len_bw_46_to_1500,len_4} type_frame;

	constraint mac{MRxerr == 0; soft MRxdv == 1;soft mcrs == 1;};
	constraint prdata {
						m_prdata_i inside{[0:1000]};
						};

/*	constraint tx_ptnt {
						TX_PNTR inside {[0:1000]};
						(TX_PNTR%4==0);
	};*/

	constraint tx_ptnt {
						RX_PNTR inside {[0:1000]};
						(RX_PNTR%4==0);
	};
	constraint registers{
						(paddr_i=='d0)  -> pwdata_i == {16'b0,PAD,HUGEN,3'b0,FULLD,3'b0,IFG,PRO,1'b0,BRO,NOPRE,TXEN,RXEN};

						(paddr_i=='d4)  -> pwdata_i == {28'b0,1'b1,1'b1,1'b1,1'b1};
						(paddr_i=='d8)  -> pwdata_i == {28'b0,RXE_M,RXB_M,TXE_M,TXB_M};
						(paddr_i=='d32) -> pwdata_i == {24'b0,TX_BD_NUM};
						(paddr_i=='d48) -> pwdata_i == {27'b0,5'hc};
						(paddr_i=='d64) -> pwdata_i == 32'b0;
						(paddr_i=='d68) -> pwdata_i == {16'b0,16'habcd};

						(paddr_i>1023 && paddr_i<2048 && paddr_i%8==0) -> pwdata_i == {Len_Rx,MT,IRQ,14'b0};
						(paddr_i>1023 && paddr_i<2048 && paddr_i%8==4) -> pwdata_i == RX_PNTR;
						//(paddr_i>1023 && paddr_i<2048 && paddr_i%8==4) -> (pwdata_i%4==0);

					}

	constraint pad_hugen{
						if(type_frame == 0)
							{
								foreach(length_q[i]) {
							
									if(length_q[i]<46){
										PAD==1;
										HUGEN == TEMP;
									}
									else 
										PAD == PAD;
									if((length_q[i] > 1500) && (length_q[i] < 2031)) {
										HUGEN==1;
									}
								}
							}
							else if(type_frame == 2 || type_frame ==5) { 
								PAD == 1;
								HUGEN == 0;

							}	
							else if(type_frame == 3) { 
								PAD == 0;
								HUGEN == 1;

							}
							else if(type_frame == 1) { 
								PAD == 0;
								HUGEN == 0;

							}
						};



	constraint lenght{
						if(type_frame == 0)
						 	Len_Rx inside {64};
						else if(type_frame == 1)
							Len_Rx inside {[0:45],[1501:2030]};
						else if(type_frame == 2)
							Len_Rx inside {[4:45]};
						else if(type_frame == 3)
							Len_Rx inside {[1501:2030]};
						else if(type_frame == 4)
							Len_Rx inside {[46:1500]};
						else if(type_frame == 5)
							Len_Rx inside {[1:4]};


					 };



	constraint all_fields {
							
								 FULLD == 0;
							soft IFG   == 1;
							soft PRO   == 1;
							soft IFG   == 1;
							soft NOPRE == 0;
							soft TXEN  == 0;
								 RXEN  == 1;
							soft TXE_M == 1;
							soft TXB_M == 1;
							soft RXE_M == 1;
							soft RXB_M == 1;

								if(tx_bd_num_flag_randomize) TX_BD_NUM inside {[1:128]};


								 RD    == 1;
								 MT    == 1;
								 IRQ   == 1;

							//soft Len_Tx inside {[4:2030]};
							};
	//---------------------------------for tx_bd_num from make file------------------------------//
	task t1_txbd_value();

		if($value$plusargs("bd_value=%0d",TX_BD_NUM))
			$display($time,"-----------bd_value=%0d--------",TX_BD_NUM);

		if($value$plusargs("bd_num_flag=%0d",tx_bd_num_flag_randomize))
			$display($time,"-----------bd_num_flag=%0d--------",tx_bd_num_flag_randomize);

		if(!tx_bd_num_flag_randomize) TX_BD_NUM.rand_mode(0);

	endtask

	task t1_lenth();
		if($value$plusargs("type_frame1=%d",type_frame))
			$display($time,"-----------type_frame=%s--------",type_frame);

	endtask

	//---------------------------post_randomize for storing length for each bd -------------------//
	function void post_randomize();
		
		if(paddr_i>1023 && paddr_i<2048 && (paddr_i%4==0) && (paddr_i%8==0)&& pwrite_i)
			length_q.push_back(pwdata_i[31:16]);
	endfunction


endclass



