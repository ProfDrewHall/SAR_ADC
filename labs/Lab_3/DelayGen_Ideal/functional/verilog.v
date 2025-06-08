module DelayGen_Ideal (
		input	In,
		output	Out
		);

assign	#2 	Out = In;

endmodule
