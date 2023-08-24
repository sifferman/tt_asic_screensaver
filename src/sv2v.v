module top (
	clk_25_175,
	rst,
	hsync,
	vsync,
	r,
	g,
	b
);
	input clk_25_175;
	input rst;
	output wire hsync;
	output wire vsync;
	output wire [3:0] r;
	output wire [3:0] g;
	output wire [3:0] b;
	wire visible;
	wire [9:0] position_x;
	wire [9:0] position_x_NEXT;
	wire [8:0] position_y;
	wire [8:0] position_y_NEXT;
	wire [3:0] im_r;
	wire [3:0] im_g;
	wire [3:0] im_b;
	wire [31:0] frame;
	assign r = (visible ? im_r : 0);
	assign g = (visible ? im_g : 0);
	assign b = (visible ? im_b : 0);
	video_timer #(
		.H_FRONT(16),
		.H_VISIBLE(640),
		.H_SYNC(96),
		.H_BACK(48),
		.V_FRONT(10),
		.V_VISIBLE(480),
		.V_SYNC(2),
		.V_BACK(33)
	) vt(
		.clk(clk_25_175),
		.rst(rst),
		.hsync(hsync),
		.vsync(vsync),
		.visible(visible),
		.position_x(position_x),
		.position_x_NEXT(position_x_NEXT),
		.position_y(position_y),
		.position_y_NEXT(position_y_NEXT),
		.frame(frame)
	);
	image im(
		.clk(clk_25_175),
		.rst(rst),
		.position_x(position_x),
		.position_x_next(position_x_NEXT),
		.position_y(position_y),
		.position_y_next(position_y_NEXT),
		.frame(frame),
		.r(im_r),
		.g(im_g),
		.b(im_b)
	);
endmodule
module image (
	clk,
	rst,
	position_x,
	position_x_next,
	position_y,
	position_y_next,
	frame,
	r,
	g,
	b
);
	parameter SCREEN_WIDTH = 640;
	parameter SCREEN_HEIGHT = 480;
	input clk;
	input rst;
	input [$clog2(SCREEN_WIDTH) - 1:0] position_x;
	input [$clog2(SCREEN_WIDTH) - 1:0] position_x_next;
	input [$clog2(SCREEN_HEIGHT) - 1:0] position_y;
	input [$clog2(SCREEN_HEIGHT) - 1:0] position_y_next;
	input [31:0] frame;
	output reg [3:0] r;
	output reg [3:0] g;
	output reg [3:0] b;
	localparam BOX_HEIGHT = 100;
	localparam BOX_WIDTH = 100;

	reg [$clog2(SCREEN_WIDTH):0] box_x;
	reg [$clog2(SCREEN_WIDTH):0] box_xv;
	wire [$clog2(SCREEN_WIDTH):0] box_x_next;
	wire [$clog2(SCREEN_WIDTH):0] box_xv_next;
	wire [$clog2(SCREEN_WIDTH):0] box_x_trajectory;
	reg [$clog2(SCREEN_HEIGHT):0] box_y;
	reg [$clog2(SCREEN_HEIGHT):0] box_yv;
	wire [$clog2(SCREEN_HEIGHT):0] box_y_next;
	wire [$clog2(SCREEN_HEIGHT):0] box_yv_next;
	wire [$clog2(SCREEN_HEIGHT):0] box_y_trajectory;
	wire hit_v_edge;
	wire hit_h_edge;

	// assign hit_v_edge = ((box_x_trajectory) < 0) || ((box_x_trajectory) >= (SCREEN_WIDTH - BOX_WIDTH));
	// assign hit_h_edge = ((box_y_trajectory) < 0) || ((box_y_trajectory) >= (SCREEN_HEIGHT - BOX_HEIGHT));
	assign box_x_trajectory = box_x + box_xv;
	assign box_y_trajectory = box_y + box_yv;
	// assign box_x_next = ((0) > (box_x_trajectory) ? 0 : ((SCREEN_WIDTH - BOX_WIDTH) < (box_x_trajectory) ? SCREEN_WIDTH - BOX_WIDTH : box_x_trajectory));
	// assign box_y_next = ((0) > (box_y_trajectory) ? 0 : ((SCREEN_HEIGHT - BOX_HEIGHT) < (box_y_trajectory) ? SCREEN_HEIGHT - BOX_HEIGHT : box_y_trajectory));
	// assign box_xv_next = (hit_v_edge ? ~box_xv + 1 : box_xv);
	// assign box_yv_next = (hit_h_edge ? ~box_yv + 1 : box_yv);
	assign hit_v_edge = 1;
	assign hit_h_edge = 1;
	// assign box_x_trajectory = 0;
	// assign box_y_trajectory = 0;
	assign box_x_next = 0;
	assign box_y_next = 0;
	assign box_xv_next = 0;
	assign box_yv_next = 0;


	wire in_box;
	wire [3:0] lightness;
	reg [2:0] color;
	wire [2:0] color_next;

	assign in_box = (((box_x) <= (position_x)) && ((position_x) < ((box_x) + BOX_WIDTH))) && (((box_y) <= (position_y)) && ((position_y) < ((box_y) + BOX_HEIGHT)));
	assign lightness = {{3 {in_box}}, 1'b1};
	assign color_next = (!(hit_v_edge || hit_h_edge) ? color : (color == 3'b111 ? 3'b001 : color + 1));
	assign r = lightness & {4 {color[0]}};
	assign g = lightness & {4 {color[1]}};
	assign b = lightness & {4 {color[2]}};
	// assign in_box = 1;
	// assign lightness = 0;
	// assign color_next = 0;
	// assign r = 0;
	// assign g = 0;
	// assign b = 0;

	reg [31:0] frame_prev;
	always @(posedge clk)
		if (rst) begin
			box_x <= 50;
			box_y <= 50;
			box_xv <= 2;
			box_yv <= 1;
			frame_prev <= 0;
			color <= 3'b111;
		end
		else if (frame_prev != frame) begin
			box_x <= box_x_next;
			box_y <= box_y_next;
			box_xv <= box_xv_next;
			box_yv <= box_yv_next;
			frame_prev <= frame;
			color <= color_next;
		end

endmodule
module video_timer (
	clk,
	rst,
	hsync,
	vsync,
	visible,
	position_x,
	position_x_NEXT,
	position_y,
	position_y_NEXT,
	frame
);
	parameter H_VISIBLE = 640;
	parameter H_FRONT = 16;
	parameter H_SYNC = 96;
	parameter H_BACK = 48;
	parameter V_VISIBLE = 480;
	parameter V_FRONT = 10;
	parameter V_SYNC = 2;
	parameter V_BACK = 33;
	input clk;
	input rst;
	output wire hsync;
	output wire vsync;
	output wire visible;
	output wire [$clog2(H_VISIBLE) - 1:0] position_x;
	output wire [$clog2(H_VISIBLE) - 1:0] position_x_NEXT;
	output wire [$clog2(V_VISIBLE) - 1:0] position_y;
	output wire [$clog2(V_VISIBLE) - 1:0] position_y_NEXT;
	output reg [31:0] frame;
	localparam WHOLE_LINE = ((H_VISIBLE + H_FRONT) + H_SYNC) + H_BACK;
	localparam WHOLE_FRAME = ((V_VISIBLE + V_FRONT) + V_SYNC) + V_BACK;
	reg [$clog2(WHOLE_LINE) - 1:0] x_counter;
	wire [$clog2(WHOLE_LINE) - 1:0] x_counter_NEXT;
	reg [$clog2(WHOLE_FRAME) - 1:0] y_counter;
	wire [$clog2(WHOLE_FRAME) - 1:0] y_counter_NEXT;
	assign x_counter_NEXT = (x_counter == ((((H_VISIBLE + H_FRONT) + H_SYNC) + H_BACK) - 1) ? 0 : x_counter + 1);
	assign y_counter_NEXT = (x_counter != ((((H_VISIBLE + H_FRONT) + H_SYNC) + H_BACK) - 1) ? y_counter : (y_counter == ((((V_VISIBLE + V_FRONT) + V_SYNC) + V_BACK) - 1) ? 0 : y_counter + 1));
	wire hvisible;
	wire vvisible;
	assign hvisible = (x_counter < H_VISIBLE) && !rst;
	assign vvisible = (y_counter < V_VISIBLE) && !rst;
	assign visible = hvisible & vvisible;
	assign hsync = ~((((H_VISIBLE + H_FRONT) <= x_counter) && (x_counter < ((H_VISIBLE + H_FRONT) + H_SYNC))) && !rst);
	assign vsync = ~((((V_VISIBLE + V_FRONT) <= y_counter) && (y_counter < ((V_VISIBLE + V_FRONT) + V_SYNC))) && !rst);
	function automatic [$clog2(H_VISIBLE) - 1:0] sv2v_cast_B6BDA;
		input reg [$clog2(H_VISIBLE) - 1:0] inp;
		sv2v_cast_B6BDA = inp;
	endfunction
	assign position_x = sv2v_cast_B6BDA(x_counter);
	function automatic [$clog2(V_VISIBLE) - 1:0] sv2v_cast_CA094;
		input reg [$clog2(V_VISIBLE) - 1:0] inp;
		sv2v_cast_CA094 = inp;
	endfunction
	assign position_y = sv2v_cast_CA094(y_counter);
	assign position_x_NEXT = sv2v_cast_B6BDA(x_counter_NEXT);
	assign position_y_NEXT = sv2v_cast_CA094(y_counter_NEXT);
	wire [31:0] frame_NEXT = ((y_counter != 0) && (y_counter_NEXT == 0) ? frame + 1 : frame);
	always @(posedge clk)
		if (rst) begin
			x_counter <= (H_VISIBLE + H_FRONT) + H_SYNC;
			y_counter <= (V_VISIBLE + V_FRONT) + V_SYNC;
			frame <= ~0;
		end
		else begin
			x_counter <= x_counter_NEXT;
			y_counter <= y_counter_NEXT;
			frame <= frame_NEXT;
		end
endmodule
