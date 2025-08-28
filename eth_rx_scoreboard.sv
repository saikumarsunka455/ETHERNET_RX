class eth_rx_score_board extends uvm_scoreboard;

//====================factory registration =================
	`uvm_component_utils(eth_rx_score_board)

	 byte_queue in_que , out_que;

   	eth_config_class h_eth_config_class; 
	uvm_event event_sb;
	virtual eth_interface h_eth_interface;

//==================== analysis port=======================
	`uvm_analysis_imp_decl(_outmon)
	uvm_analysis_imp #(byte_queue,eth_rx_score_board) h_score_board_input_monitor_imp;
	uvm_analysis_imp_outmon #(byte_queue,eth_rx_score_board) h_score_board_output_monitor_imp;

//===============construction =======================

	function new(string name="", uvm_component parent);
		super.new(name,parent);
	endfunction

//====================build phase=======================

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		h_score_board_input_monitor_imp = new("h_score_board_input_monitor_imp",this);
		event_sb = uvm_event_pool :: get_global("event_sb_out");
		h_score_board_output_monitor_imp = new("h_score_board_output_monitor_imp",this);
	endfunction

//===========================connect phase=====================

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
        assert(uvm_config_db #(eth_config_class)::get(null,this.get_full_name(),"eth_config_class",h_eth_config_class));
		uvm_config_db #(virtual eth_interface) :: get(this , "" , "eth_interface", h_eth_interface);

	endfunction

//====================write functions==================

	function void write(input byte_queue in_data_que);
		in_que = in_data_que;
	endfunction

	function void write_outmon(input byte_queue out_data_que);
		out_que = out_data_que;
	endfunction



	//===================run phase =========================

	task run_phase(uvm_phase phase);
		super.run_phase(phase);
		forever 
		begin//{ 
//--------------------- thid flag be 0 after completion of every bd once it is 1 -----
			h_eth_config_class.delete_flag=0;

//---------------- wait for the event trigger in the output monitor after completion of every bd ---------
			event_sb.wait_trigger();

		//	$display($time," &&&&&&&&&& from screboard &&&&&&&&&& in que %p ---- size  %0d  \n\n\n out que  %p ---- size  %0d \n\n\n ",in_que,in_que.size,out_que,out_que.size);

			foreach(in_que[i]) begin
				if(out_que[i] == in_que[i]) begin
				  `uvm_info( "SCOREBOARD PASS",$sformatf("********* PASS *******in_que = %0d out_que=%0d ||**********",in_que[i],out_que[i]),UVM_HIGH);
				end
				else begin
				 `uvm_info( "SCOREBOARD FAIL ",$sformatf("******** FAIL ******* in_que = %0d out_que=%0d ||**********",in_que[i],out_que[i]),UVM_HIGH);
				end
			end

		//	@(h_eth_interface.cb_host_mem_monitor);
			h_eth_config_class.delete_flag=1;
//$display($time," *********************************** flag %0d ",h_eth_config_class.delete_flag);
			in_que.delete();
			out_que.delete();

		@(h_eth_interface.cb_host_mem_monitor);

	//	#20;
		end//}

	endtask

//=============== final phase for only displays ========

	function void final_phase(uvm_phase phase);
		super.final_phase(phase);

			$display("\n\n\n");

			$display($time," &&&&&&&&&&&&&&&&&&&&&&&& TXBD  %p ",h_eth_config_class.RXD);

			$display($time," &&&&&&&&&&&&&&&&&&&&&&&& TX_BD_NUM ----- %0d ",h_eth_config_class.TX_BD_NUM);

			h_eth_config_class.displays();
	endfunction
endclass



