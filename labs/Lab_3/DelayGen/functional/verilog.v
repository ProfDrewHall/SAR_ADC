module DelayGen (
		input	In,
		output	Out,
		inout	VDD,
		inout	VSS
		);

wire		Buff1, Buff2;

DEL2   U0 (.I(In),     .Z(Buff1), .VDD(VDD), .VSS(VSS));
DEL2   U1 (.I(Buff1),  .Z(Buff2), .VDD(VDD), .VSS(VSS));
CKBD12 U2 (.I(Buff2), . Z(Out),   .VDD(VDD), .VSS(VSS));

endmodule
