//=====================config class==================//

class eth_config_class extends uvm_object;

//=========factory registration====================//

	`uvm_object_utils(eth_config_class)

//==============construction====================//

	function new(string name="");

		super.new(name);
	endfunction

//============registers declaration===================//

	int MODER;

	int INT_SOURCE;

	int INT_MASK;

	int TX_BD_NUM;

	int MIIADDRESS;

	int MAC_ADDR0;

	int MAC_ADDR1;

	int TXD[int]; //offset+0

	int RXD[int]; //offset+4

//======================to store the length =======
	int temp_length;
	bit delete_flag , EMPTY;
task displays;
		$display($time,"-------------TX_EN ==%0d---------------",MODER[1]);
		$display($time,"-------------RX_EN ==%0d---------------",MODER[0]);
		$display($time,"-------------NOPRE ==%0d---------------",MODER[2]);
		$display($time,"-------------IFG ==%0d---------------",MODER[6]);
		$display($time,"-------------FULLD==%0d---------------",MODER[10]);
		$display($time,"-------------HUGEN ==%0d---------------",MODER[14]);
		$display($time,"-------------PAD ==%0d---------------",MODER[15]);
		$display($time,"-------------TXB_M ==%0d---------------",INT_MASK[0]);
		$display($time,"-------------TXE_M ==%0d---------------",INT_MASK[1]);
		$display($time,"-------------TX_BD_NUM ==%0d---------------",TX_BD_NUM[7:0]);
		$display($time,"------------Source ==%h--%0d-------------",MIIADDRESS,MIIADDRESS);
		$display($time,"------------mac0 ==%h- %0d--------------",MAC_ADDR0,MAC_ADDR0);
		$display($time,"------------mac1 ==%h--%0d-------------",MAC_ADDR1,MAC_ADDR1);
		for(int i=1024+(TX_BD_NUM[7:0]*8);i<2048;i+=8) 
			$display($time,"-------------Length =%0d----------EMPTY  %0d -------",RXD[i][31:16],RXD[i][15]);
		
endtask	

endclass




