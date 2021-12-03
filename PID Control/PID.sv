module PID(error, clk, rst_n, err_vld, moving, frwrd, lft_spd, rght_spd);

	input clk, rst_n, err_vld, moving;
	input signed [11:0] error;
        input [9:0] frwrd;
	output [10:0] lft_spd, rght_spd;
	
	///////////////////////////////////////////////////////////////////////////////////////
	//                                   P-TERM                                          //    
	///////////////////////////////////////////////////////////////////////////////////////

	logic signed [13:0] P_term;
	wire signed [9:0] err_sat;
	localparam P_COEFF_PTERM = 5'h08;

	// if, error[11] is negative , check 10:9 bits, if both are 1 then assign err_sat as lower 10 bits,
	// else saturate to most negative value in  a 10 bit binary number 10'200.

	// likewise for positive numbers.
	assign err_sat = (error[11]==1)? ((error[10:9]===2'b11)?error[9:0]:10'h200) :
							  ((error[10:9]===2'b00)?error[9:0]:10'h1FF) ;

	// signed multiply 
	assign P_term = err_sat * $signed(P_COEFF_PTERM);

	///////////////////////////////////////////////////////////////////////////////////////
	//                                   I-TERM                                          //    
	///////////////////////////////////////////////////////////////////////////////////////

	logic signed [8:0]I_term;
	logic ov;
	// Registers required
	reg signed [14:0]nxt_integrator ,integrator, accum;
	reg signed [14:0] mux_out_3, err_sat_15;

	assign I_term = integrator[14:6];

	always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
	  integrator<= 15'h0000;
	else
	  integrator<= nxt_integrator;

	// Sign-extend to 15 bits
	assign err_sat_15 = {{5{err_sat[9]}},err_sat};

	//Accumulator
	assign accum = (integrator + err_sat_15);

	// Overflow statement
	assign ov = ( (err_sat_15[14] == integrator[14]) && (integrator[14] != accum[14]) ) ? 1'b1 : 1'b0;

	// Check error valid and ov
	assign mux_out_3 = (err_vld && (!ov)) ? accum: integrator ;

	//Check moving and assign to nxt_integrator
	assign nxt_integrator = (moving) ?  mux_out_3 : 15'h0000 ;


         

	///////////////////////////////////////////////////////////////////////////////////////
	//                                   D-TERM                                          //    
	///////////////////////////////////////////////////////////////////////////////////////
	logic [9:0] mux_out_1, mux_out_2, D_diff, prev_err;
	reg [9:0] q1, q2;
	logic signed [6:0] D_diff_sat;
	logic signed [12:0] D_term;
	localparam D_term_coeff = 6'h0B;

	assign mux_out_1 = (err_vld)? err_sat[9:0]: q1;

	// First Flip- FLop
	always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
	q1 <= 10'h000;
	else
	q1 <= mux_out_1;

	assign mux_out_2 = (err_vld)? q1: q2;

	// Second Flip FLop
	always_ff @(posedge clk, negedge rst_n)
	if(!rst_n)
	q2 <= 10'h000;
	else
	q2 <= mux_out_2;

	assign prev_err = q2;

	//assign D_diff = err_sat - prev_err;
	assign D_diff = err_sat[9:0] - q2;

	// Saturation
	assign D_diff_sat = (D_diff[9]===1)? ((D_diff[8:6]===3'b111)?D_diff[6:0]:7'h40) :
							  ((D_diff[8:6]===3'b000)?D_diff[6:0]:7'h3f) ;

						
	assign D_term = D_diff_sat * $signed(D_term_coeff);
	///////////////////////////////////////////////////////////////////////////////////////
	//                                   PID
	///////////////////////////////////////////////////////////////////////////////////////
	logic signed [10:0] mux1_in, mux2_in, mux1, mux2;	
	logic signed [13:0] P_term_modif, I_term_modif, D_term_modif;
	logic signed [13:0] PID;
	logic signed [10:0] frwrd_modif;
	logic signed [10:0] lft_sat, rght_sat;
	
	assign P_term_modif = P_term;
	assign I_term_modif = { {5{I_term[8]}} ,I_term[8:0]}; 
	assign D_term_modif = { {1{D_term[12]}} ,D_term[12:0]}; 
	assign PID = P_term_modif + I_term_modif + D_term_modif;
	
	assign frwrd_modif = {1'b0, frwrd};
	
	assign mux1_in = frwrd_modif + PID[13:3];	
	assign lft_sat = (~frwrd_modif[10] && ~PID[13])? mux1_in[10] : 0;
	assign lft_spd = (moving)?{ lft_sat? 11'h3ff: mux1_in} : 0;
	
	assign mux2_in = frwrd_modif -PID[13:3];	
	assign rght_sat = (~frwrd_modif[10] && PID[13])? mux2_in[10] : 0;
	assign rght_spd = (moving)?{ rght_sat? 11'h3ff: mux2_in} : 0;
endmodule