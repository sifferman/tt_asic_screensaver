`default_nettype none

module tt_um_asic_screensaver (
    input  wire [7:0] ui_in,    // Dedicated inputs - connected to the input switches
    output wire [7:0] uo_out,   // Dedicated outputs - connected to the 7 segment display
    input  wire [7:0] uio_in,   // IOs: Bidirectional Input path
    output wire [7:0] uio_out,  // IOs: Bidirectional Output path
    output wire [7:0] uio_oe,   // IOs: Bidirectional Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // will go high when the design is enabled
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

wire clk_25_175 = clk;
wire rst = !rst_n;

wire hsync, vsync;
wire [3:0] r, g, b;

assign uo_out = {hsync, vsync, r};
assign uio_out = {g, b};

assign hsync = 0;
assign vsync = 0;
assign r = 0;
assign g = 0;
assign b = 0;

assign uio_oe = -1;

// top #(.IMAGE_SELECT(2)) screensaver (
//     .clk_25_175(clk_25_175), .rst(rst),
//     .hsync(hsync), .vsync(vsync),
//     .r(r), .g(g), .b(b)
// );

endmodule
