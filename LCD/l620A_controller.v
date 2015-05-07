/*
 *  LCD 1602 A controller
 *  Initial version:
 *    - INIT will activate the LCD 4bit 2 lines auto I/D
 *    - WRITE will write the character to the LCD
 *    - CLEAR will clear the LCD
 *    - 20 MHz
 *    - Based on https://gist.github.com/jjcarrier/1529101
 *
 *  gonzalof
 */

module 1602A_controller #(
  parameter [1:0] NCOMMANDS = 3,
  parameter [0:0] MODE      = 1,         // 0: 8 bit - 1: 4bit
  parameter [0:0] LINES     = 1          // 0: 1 line - 1: 2 lines
  )(
  input wire  [0:0]           clk,
  input wire  [7:0]           data_in,
  input wire  [NCOMMANDS:0]   op_in,
  input wire  [0:0]           en,
  input wire  [0:0]           rst,
  output reg  [2:0]           lcd_ctrl,   // RS - RW - E
  output reg  [7-(MODE*4):0]  lcd_data,
  output reg  [0:0]           lcd_rdy
  );

/// Delays requiered by the LCD
parameter [19:0] t_40ns   = 1;        //40ns    == ~1clk
parameter [19:0] t_250ns  = 6;        //250ns   == ~6clks
parameter [19:0] t_42us   = 1008;     //42us    == ~1008clks
parameter [19:0] t_100us  = 2400;     //100us   == ~2400clks
parameter [19:0] t_1640us   = 39360;  //1.64ms  == ~39360clks
parameter [19:0] t_4100us   = 98400;  //4.1ms   == ~98400clks
parameter [19:0] t_15000us  = 360000; //15ms    == ~360000clks

/// Counter section to have proper delays between commands
reg [0:0] f_40ns    =0,
          f_250ns   =0,
          f_42us    =0,
          f_100us   =0,
          f_1640us  =0,
          f_4100us  =0,
          f_15000us =0;

// Counter instance
contador #(.WIDTH(20)) delay_count(
  .nxt(clk),
  .dir(1'b1),
  .rst(start_count),
  .empty(),
  .full(full),
  .cuenta(count_cum)
  );

// Registered counter comparator to set flag values
// Implement combinational version and compare results
always @(clk) begin
  f_40ns    <= (count_cum >= t_40ns   ) ? 1'b1 : 1'b0;
  f_250ns   <= (count_cum >= t_250ns  ) ? 1'b1 : 1'b0;
  f_42us    <= (count_cum >= t_42us   ) ? 1'b1 : 1'b0;
  f_100us   <= (count_cum >= t_100us  ) ? 1'b1 : 1'b0;
  f_1640us  <= (count_cum >= t_1640us ) ? 1'b1 : 1'b0;
  f_4100us  <= (count_cum >= t_4100us ) ? 1'b1 : 1'b0;
  f_15000us <= (count_cum >= t_15000us) ? 1'b1 : 1'b0;
end

// RST input to counter (RST also works as counter enable signal)
assign start_count = rst | ~count_enable;

// Count enable input to counter selector
assign count_enable = ctrl_sel_count ? nctrl_count : ndriver_count; //and with ~ready to be safe of crtl_sel_count failures

// store command on a reg afteer a en posedge
// or turn on an error flag if op changes while busy
assign command = en & (1'b1 << op_in);

// LCD Driver instance
l1602A_driver #(.NFLAGS(7)) lcd_driver (
  .data_in(ctrl_sel_data),
  .flags_in({f_40ns, f_250ns, f_42us, f_100us, f_1640us, f_4100us, f_15000us}),
  .enable(),
  .rst(rst),
  .driver_count(driver_count),
  .driver_error(),   // Not implemented yet
  .driver_rdy(driver_rdy),
  .driver_ctrl(lcd_ctrl),    // RS - RW - E
  .driver_data(lcd_data)
  );

// Combinational lcd driver data_in selector
always @(*) begin
  case (ctrl_sel_data) begin
    2'b10: driver_data_in   = data_in;
    2'b01: driver_data_in   = crtl_cmd;
    default driver_data_in  = 8'd0;
  end
end

// Main control
controller_control #(.NFLAGS(7)) control (
  .cmd_in(command),
  .flags_in({f_40ns, f_250ns, f_42us, f_100us, f_1640us, f_4100us, f_15000us}),
  .driver_rdy(driver_rdy),
  .enable(),                        // Not implemented yet
  .rst(rst),
  .nctrl_count(nctrl_count),
  .ctrl_sel_count(ctrl_sel_count),
  .ctrl_sel_data(ctrl_sel_data),
  .ctrl_error(),                    // Not implemented yet
  .ctrl_rdy(ctrl_rdy),
  .ctrl_cmd(ctrl_cmd)
  );

endmodule

