/******************************************************************************
 * SARFSMNSIG
 * SAR ADC FSM and Signaling Unit
 *
 * Signaling
 *			SAMP				--> Sampling command
 * 			COMPOUT			--> Comparator output
 * 			CPb & CNb		--> Comparator Outputs before latch
 *			COMPStatus		--> Comparator current state indicator
 *			COMPEn			--> Comparator Enable
 * 			CLK & CLKb		--> Comparator differential controls
 * 			EOC 				--> End Of Conversion flag
 *			S, Sb, SR & SRb	--> Switches control
 *****************************************************************************/
module SARFSMNSIG (
	input				SAMP,
	input				COMPOUT,
	input				CPb,
	input				CNb,
	input				COMPEn,
	output				COMPStatus,
	output		[8:0]	S, Sb, SR, SRb,
	output				CLK, CLKb,
	output	reg			EOC,
	output	reg	[8:0]	Code
	);

/* Registers ----------------------------------------------------------------*/
reg		[9:0]	Index;

always @(negedge COMPEn or posedge SAMP) begin
	if (SAMP) begin
		/* Reset the data for the next conversion */
		Index		<= 10'b1000000000;
		Code			<=  9'd0;
		EOC			<=  1'b0;
	end else begin
		/* Code Generation */
		if (COMPOUT)
			Code		<= Code;
		else
			Code		<= Code | Index [9:1];
		/* State Transition*/
		Index		<= Index >> 1;
		EOC			<= EOC|Index [0];
	end
 end

/* Asynchronous cycle generation ----------------------------------------------
 * Once of the CPb or CNb becomes one, we enable the Comparator for the next
 * cycle, till we pass all the cycles.
 * For signaling we need it to be inverted here rather than later at the CLK
 * other wse it would be hard to make the intial signal.
 */
assign	COMPStatus	=  SAMP ? 1'b0 : ~EOC & ~CPb  & ~CNb;

/* Output Signals to Switches -----------------------------------------------*/
assign	S		=  (SAMP ? 9'd0 : (Code | Index [9:1]));
assign	Sb		= ~(SAMP ? 9'd0 : (Code | Index [9:1]));
assign	SR		=  (SAMP ? 9'd0 :~(Code | Index [9:1]));
assign	SRb		= ~(SAMP ? 9'd0 :~(Code | Index [9:1]));

/* Output Signals to Comparat -----------------------------------------------*/
assign	CLK		=   COMPEn & ~CLKb;
assign	CLKb		=  ~COMPEn & ~CLK;

endmodule

/******************************************************************************
 * DelGen
 * Delay Generator Unit
 *
 * Signaling
 *			In		--> Input
 * 			Out 		--> Output
 *****************************************************************************/

module DelayGen (
	input				In,
	output				Out,
	inout				VDD, 
	inout				VSS
	); 

wire		Buff1, Buff2;

DEL2   U0 (.I(In),     .Z(Buff1), .VDD(VDD), .VSS(VSS));
DEL2   U1 (.I(Buff1),  .Z(Buff2), .VDD(VDD), .VSS(VSS));
CKBD12 U2 (.I(Buff2), . Z(Out),   .VDD(VDD), .VSS(VSS));

endmodule

/******************************************************************************
 * SARController
 * EC 266 SAR Controller Unit
 *
 * Signaling
 *			SAMP				--> Sampling command
 *			COMPStatus		--> Comparator current state indicator
 *			COMPEn			--> Comparator Enable
 * 					  	 	COMPEnIn, COMPEnOut are just added for timing.
 * 							Will be shorted from outside
 * 			COMPOUT			--> Comparator output
 * 			CPb & CNb		--> Comparator Outputs before latch
 * 			CLK & CLKb		--> Comparator differential controls
 * 			EOC 				--> End Of Conversion flag
 *			S, Sb, SR & SRb	--> Switches control
 *****************************************************************************/
module SARController (
	input				SAMP,
	input				COMPOUT,
	input				CPb,
	input				CNb,
	input				COMPEnIn,
	output				COMPEnOut,
	output		[8:0]	S, Sb, SR, SRb,
	output				CLK, CLKb,
	output				EOC,
	output		[8:0]	Code,
	inout				VDD, VSS
	);

wire		OMPStatus;

SARFSMNSIG	U0	(
	.SAMP		(SAMP),
	.COMPOUT		(COMPOUT),
	.CPb			(CPb),
	.CNb			(CNb),
	.COMPEn		(COMPEnIn),
	.COMPStatus 	(COMPStatus),
	.S 			(S),
	.Sb			(Sb),
	.SR			(SR),
	.SRb			(SRb),
	.CLK			(CLK),
	.CLKb		(CLKb),
	.EOC			(EOC),
	.Code		(Code)
	);

DelayGen		U1	(
	.In		(COMPStatus),
	.Out		(COMPEnOut),
	.VDD		(VDD),
	.VSS		(VSS)
	);

endmodule

