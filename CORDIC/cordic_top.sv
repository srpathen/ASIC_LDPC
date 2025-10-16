`include "cordic_header.svh"
module cordic_top(m, rot_vec, xin, yin, zin, xout, yout, zout);
	parameter number_of_stages	= 16;
	parameter number_of_flops	= 8;

	input	m, rot_vec;
	input	[`N-1:0] xin, yin, zin;
	output	[`N-1:0] xout, yout, zout;

	logic [number_of_stages - 1 : 0] n_ms;
	logic [number_of_flops - 1  : 0] ms;
	logic [`N-1:0] xs[number_of_flops - 1  : 0];
	logic [`N-1:0] ys[number_of_flops - 1  : 0];
	logic [`N-1:0] zs[number_of_flops - 1  : 0];
	logic [`N-1:0] n_xs[number_of_stages - 1  : 0];
	logic [`N-1:0] n_ys[number_of_stages - 1  : 0];
	logic [`N-1:0] n_zs[number_of_stages - 1  : 0];

	generate
	genvar i;
		for (i = 0; i < number_of_stages; i = i + 1) begin
			if (i % (number_of_stages / number_of_flops) == (number_of_stages / number_of_flops) - 1) begin
				cordic_stage #(
				.stage_number_trig(),
				.stage_numer_hype()
				)
				cordic_inst (
				.m,
				.rot_vec(),
				.xin(),
				.yin(),
				.zin(),
				.xout(),
				.yout(),
				.zout()
				);
			end
		end
	endgenerate
endmodule
