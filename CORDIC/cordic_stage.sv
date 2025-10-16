`include "cordic_header.svh"

module cordic_stage(m, rot_vec, xin, yin, zin, xout, yout, zout);
	parameter stage_number_trig = 1;
	parameter stage_number_hype = 1;

	input m; //1 in circular. 0 in hyperbolic
	input rot_vec; //1 in rotation mode, 0 in vectoring
	input signed [`N-1:0] xin, yin, zin; //input vector and angle

	output signed [`N-1:0] xout, yout, zout; //ouput vector and angle

	logic signed [`N-1:0] alpha, yshift, xshift; //the angle to rotate by, and shifted x and y values based on the mode

	logic sigma; //decision bit
	
	//m = 0 is hyperbolic mode
	assign alpha	= m ? arctan[stage_number_trig] : arctanh[stage_number_hype];
	assign xshift	= m ? (xin >>> stage_number_trig) : (xin >>> stage_number_hype);
	assign yshift	= m ? (yin >>> stage_number_trig) : (yin >>> stage_number_hype);

	assign sigma = rot_vec ? (zin >= 0) : (yin < 0); //sigma[j] = 0 if in rotation mode and z[j] is below zero or higher. = 1 if in vectoring mode and y[j] is less than zero

	assign xout = (m ^ sigma) ? xin + yshift : xin - yshift; //x[j+1] = x[j] - 2^-j * y[j] if m == sigma[j]. x[j+1] = x[j] + 2^-j * y[j] else
	assign yout = sigma ? yin + xshift : yin - xshift; //y[j+1] = y[j] + 2^-j * x[j] if sigma[j] is 1. subtract otherwise
	assign zout = sigma ? zin - alpha : zin + alpha; //z[j+1] = z[j] - iteration angle is sigma[j] is 1. Add otherwise

endmodule
