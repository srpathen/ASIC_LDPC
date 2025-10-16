`include "cordic_header.svh"
module cordic_top(m, rot_vec, xin, yin, zin, xout, yout, zout, clk, reset);
	parameter number_of_stages	= 16;
	parameter number_of_flops	= 8;
	localparam flops_to_stages	= number_of_stages / number_of_flops;

	if (!(number of stages % number_of_flops == 0)) $error("number of flops does not evenly divide number of stages");

	input clk, reset;

	input	m, rot_vec;
	input	[`N-1:0] xin, yin, zin;
	output	[`N-1:0] xout, yout, zout;

	//note that each bit or number that moves through the system has a flop array and a wire array feeding into it, use of n_ prefix for wires
	logic [number_of_stages - 1 : 0] n_ms;
	logic [number_of_flops - 1  : 0] ms;
	logic [number_of_stages - 1 : 0] n_rot_vecs;
	logic [number_of_flops - 1  : 0] rot_vecs;
	logic [`N-1:0] xs[number_of_flops - 1  : 0];
	logic [`N-1:0] ys[number_of_flops - 1  : 0];
	logic [`N-1:0] zs[number_of_flops - 1  : 0];
	logic [`N-1:0] n_xs[number_of_stages - 1  : 0];
	logic [`N-1:0] n_ys[number_of_stages - 1  : 0];
	logic [`N-1:0] n_zs[number_of_stages - 1  : 0];

	generate
		//track each instance. i is the trig iteration, k is the hyperbolic. We use next_k to make sure of repeats
		genvar i;
		genvar k;
		genvar next_k;
		k = 1;
		next_k = 4;

		//statically assign initial case
		cordic_stage #(
		.stage_number_trig(i),
		.stage_numer_hype(k)
		)
		cordic_first (
		.m(m),
		.rot_vec(rot_vec),
		.xin(xin),
		.yin(yin),
		.zin(zin),
		.xout(n_xs[0]),
		.yout(n_ys[0]),
		.zout(z_zs[0])
		);
		k = k + 1;
		assign n_ms[0]	= m;
		assign n_rot_vecs[0] = rot_vec;
		for (i = 1; i < number_of_stages; i = i + 1) begin
			if (i % flops_to_stages == 0) begin //this case creates the stages that have flops as inputs. outputs wires
				cordic_stage #(
				.stage_number_trig(i),
				.stage_number_hype(k)
				)
				cordic_inst (
				.m(ms[(i / flops_to_stages) - 1]), // in 16/8 example, 2 -> 0, 4 -> 1. in 16/16 example, 1 -> 0, 2 -> 1
				.rot_vec(rot_vecs[(i / flops_to_stages) - 1]),
				.xin(xs[(i / flops_to_stages)] - 1), //readout the flop array. need to do math to prevent memory array size growth
				.yin(ys[(i / flops_to_stages)] - 1),
				.zin(zs[(i / flops_to_stages)] - 1),
				.xout(n_xs[i]),
				.yout(n_ys[i]),
				.zout(z_zs[i])
				);
				assign n_ms[i] = ms[i / flops_to_stages];
				assign n_rot_vecs = rot_vecs[i / flops_to_stages];
			end else begin //this case creates stages with wires as inputs and outputs
				cordic_stage #(
				.stage_number_trig(i),
				.stage_number_hype(k)
				)
				cordic_inst (
				.m(n_ms[i - 1]),
				.rot_vec(n_rot_vecs[i - 1]),
				.xin(n_xs[i - 1]),
				.yin(n_ys[i - 1]),
				.zin(n_zs[i - 1]),
				.xout(n_xs[i]),
				.yout(n_ys[i]),
				.zout(z_zs[i])
				);
				assign n_ms[i] = ms[i / flops_to_stages];
				assign n_rot_vecs = rot_vecs[i / flops_to_stages];
			end

			if(k == next_k) begin //ensure k repeats by once per k, 3k + 1 series, not adding one to the k index, makes sure the hyper stages will repeat this numbering
				next_k = (3*next_k) + 1;
			end else begin
				k = k + 1;
			end
		end
	endgenerate

	always_ff @(posedge clk or negedge reset) begin
		if(~reset) begin
			for(int j = 0; j < number_of_flops; j = j + 1) begin //reset block
				ms[j]		<= '0;
				rot_vecs[j]	<= '0;
				xs[j]		<= '0;
				ys[j]		<= '0;
				zs[j]		<= '0;
			end
		end else begin
			for(int j = 1; j < number_of_flops + 1; j = j + 1) begin //turn the wires from the correct stage into flops
				ms[j-1]		<= n_ms[(j * flops_to_stages) - 1]; //fs = 1 case, 		0 <= 1, 1 <= 2, 2 <= 3
				rot_vecs[j-1]	<= n_rot_vecs[(j * flops_to_stages) - 1]; //fs = 2 case,	0 <= 1, 1 <= 3, 2 <= 5
				xs[j-1]		<= n_xs[(j * flops_to_stages) - 1]; //fs = 3 case,		0 <= 2, 1 <= 5, 3 <= 8
				ys[j-1]		<= n_ys[(j * flops_to_stages) - 1];
				zs[j-1]		<= n_zs[(j * flops_to_stages) - 1];
			end
		end
	end
endmodule
