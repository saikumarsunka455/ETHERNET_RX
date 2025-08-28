`timescale 1ns/1ps

module top;
	import uvm_pkg::*;
	import eth_package::*;
	
	bit pclk_i, MTxclk , MRxclk;


	always #20 pclk_i++;
	always #20 MTxclk++;
	always #20 MRxclk++;

	eth_interface h_eth_interface(pclk_i,MTxclk,MRxclk);

	eth_top DUT(.pclk_i(h_eth_interface.pclk_i), .prstn_i(h_eth_interface.prstn_i),.pwdata_i(h_eth_interface.pwdata_i), .prdata_o(h_eth_interface.prdata_o), .paddr_i(h_eth_interface.paddr_i), .psel_i(h_eth_interface.psel_i), .pwrite_i(h_eth_interface.pwrite_i), .penable_i(h_eth_interface.penable_i), .pready_o(h_eth_interface.pready_o), .m_paddr_o(h_eth_interface.m_paddr_o),.m_psel_o(h_eth_interface.m_psel_o), .m_pwrite_o(h_eth_interface.m_pwrite_o), .m_pwdata_o(h_eth_interface.m_pwdata_o), .m_prdata_i(h_eth_interface.m_prdata_i), .m_penable_o(h_eth_interface.m_penable_o), .m_pready_i(h_eth_interface.m_pready_i),	.int_o(h_eth_interface.int_o),.mtx_clk_pad_i(h_eth_interface.MTxclk), .mtxd_pad_o(h_eth_interface.MTxD), .mtxen_pad_o(h_eth_interface.MTxen), .mtxerr_pad_o(h_eth_interface.MTxerr),.mcrs_pad_i(h_eth_interface.mcrs),.mrx_clk_pad_i(h_eth_interface.MRxclk) , .mrxd_pad_i(h_eth_interface.MRxD) , .mrxdv_pad_i(h_eth_interface.MRxdv) , .mrxerr_pad_i(h_eth_interface.MRxerr));
//			
//================= config class instance =========
	eth_config_class h_eth_config_class;
	initial begin
		h_eth_config_class = new();
		
		uvm_config_db #(virtual eth_interface) :: set(null , "*" , "eth_interface", h_eth_interface);
		uvm_config_db #(eth_config_class) :: set(null , "*" , "eth_config_class", h_eth_config_class);

		run_test();
	end 
endmodule
