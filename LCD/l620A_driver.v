/*
 *  LCD 1602 A driver
 *  Initial version:
 *    - 4bit mode operation
 *    - 2 lines
 *    - 20MHz clock
 *    - Based on https://gist.github.com/jjcarrier/1529101
 *
 *  gonzalof
 */

module 1602A_driver #(
  parameter [0:0] MODE = 1,         // 0: 8 bit - 1: 4bit
  parameter [0:0] LINES = 1         // 0: 1 line - 1: 2 lines
  )(
  input wire  [0:0] clk,
  input wire  [7:0] data_in,
  input wire  [0:0] en,
  input wire  [0:0] rst,
  output reg  [2:0]           lcd_ctrl,   // RS - RW - E
  output reg  [7-(MODE*4):0]  lcd_data,
  output reg  [0:0]           lcd_rdy
  );


/// LCD Commands
parameter [7:0] SETUP     = 8'b00101000;  //Execution time = 42us, sets to 4-bit interface, 2-line display, 5x8 dots
parameter [7:0] DISP_ON   = 8'b00001100;  //Execution time = 42us, Turn ON Display
parameter [7:0] ALL_ON    = 8'b00001111;  //Execution time = 42us, Turn ON All Display
parameter [7:0] ALL_OFF   = 8'b00001000;  //Execution time = 42us, Turn OFF All Display
parameter [7:0] CLEAR     = 8'b00000001;  //Execution time = 1.64ms, Clear Display
parameter [7:0] ENTRY_N   = 8'b00000110;  //Execution time = 42us, Normal Entry, Cursor increments, Display is not shifted
parameter [7:0] HOME      = 8'b00000010;  //Execution time = 1.64ms, Return Home
parameter [7:0] C_SHIFT_L   = 8'b00010000;  //Execution time = 42us, Cursor Shift
parameter [7:0] C_SHIFT_R   = 8'b00010100;  //Execution time = 42us, Cursor Shift
parameter [7:0] D_SHIFT_L   = 8'b00011000;  //Execution time = 42us, Display Shift
parameter [7:0] D_SHIFT_R   = 8'b00011100;  //Execution time = 42us, Display Shift

/// DRIVER Commands
parameter [5:0] INIT      = 6'b00_0001,
                CONFIG    = 6'b00_0010,
                SEND_DATA = 6'b00_0100,
                CLEAR     = 6'b00_1000,
                OFF       = 6'b10_0000,
                IDLE      = 6'b00_0000;

/// LCD control signal names
parameter [1:0] RS = 2,
                RW = 1,
                EN = 0;

/// Delays requiered by the LCD
parameter [19:0] t_40ns   = 1;    //40ns    == ~1clk
parameter [19:0] t_250ns  = 6;    //250ns   == ~6clks
parameter [19:0] t_42us   = 1008;   //42us    == ~1008clks
parameter [19:0] t_100us  = 2400;   //100us   == ~2400clks
parameter [19:0] t_1640us   = 39360;  //1.64ms  == ~39360clks
parameter [19:0] t_4100us   = 98400;  //4.1ms     == ~98400clks
parameter [19:0] t_15000us  = 360000; //15ms    == ~360000clks

/// Counter section to have proper delays between commands
reg [0:0] f_40ns    =0,
          f_250ns   =0,
          f_42us    =0,
          f_100us   =0,
          f_1640us  =0,
          f_4100us  =0,
          f_15000us =0;

contador #(.WIDTH(20)) delay_count(
  .nxt(clk),
  .dir(1'b1),
  .rst(start_count),
  .empty(),
  .full(full),
  .cuenta(count_cum)
  );

always @(posedge clk) begin
  if (rst | stop) begin
    flag_250ns  <=0;
    flag_42us   <=0;
    flag_100us  <=0;
    flag_1640us <=0;
    flag_4100us <=0;
    flag_15000us<=0;
    start_count <=1;
  end else begin
    f_40ns    <= (count_cum >= t_40ns   ) ? 1'b1 : 1'b0;
    f_250ns   <= (count_cum >= t_250ns  ) ? 1'b1 : 1'b0;
    f_42us    <= (count_cum >= t_42us   ) ? 1'b1 : 1'b0;
    f_100us   <= (count_cum >= t_100us  ) ? 1'b1 : 1'b0;
    f_1640us  <= (count_cum >= t_1640us ) ? 1'b1 : 1'b0;
    f_4100us  <= (count_cum >= t_4100us ) ? 1'b1 : 1'b0;
    f_15000us <= (count_cum >= t_15000us) ? 1'b1 : 1'b0;
  end
end

/// DRIVER Commands control unit

/// INIT STATE MACHINE
parameter [5:0] INIT_ON   = 5'b0_0000,
                INIT_SET  = 5'b0_0001,
                INIT_MODE = 5'b0_0010,
                INIT_DISP = 5'b0_0100,
                INIT_CLR  = 5'b0_1000,
                INIT_RDY  = 5'b1_0000;
reg [5:0] init_state;


reg [3:0] substate;   // common substate ... first implementation
reg [0:0] nibble;     // Records which nibble is being processed 0: higher 1: lower

// store command on a reg afteer a en posedge
// or turn on an error flag if op changes while busy
assign command = en & (1'b1 << op);

always @(posedge clk) begin
  case (command) begin
    // 1: INIT: will initiate the LCD and will set the default
    //    configuration (4bit - 2lines - AutoI/D)
    INIT: begin
      case (init_state) begin
        // After turned ON set default values to control lines - Wait for 15 ms - Lower the ready bit
        INIT_ON: begin
          lcd_ctrl    <= 3'b010;       // RS - RW - EN
          lcd_data    <= 4'b0000;
          lcd_rdy     <= 1'b0;
          nibble      <= 1'b0;
          init_state  <= f_15000us ? INIT_SET : INIT_ON;
          stop        <= f_15000us ? 1'b1 : 1'b0;
        end

        INIT_SET: begin
          case (substate) begin
            // Set Write mode - Wait 40ns
            0: begin
              lcd_ctrl [RW] <= 1'b0;
              stop          <= f_40ns ? 1'b1 : 1'b0;
              substate      <= f_40ns ? substate + 1'b1 : substate;
            end
            // Enable bus - send first nibble - wait 230ns
            1: begin
              lcd_ctrl [EN] <= 1'b1;
              lcd_data      <= nibble  ? SETUP[3:0] : SETUP[7:4];
              stop          <= f_250ns ? 1'b1 : 1'b0;
              substate      <= f_250ns ? substate << 1 : substate;
            end
            // Disable bus wait 10ns (40ns)
            2: begin
              lcd_ctrl [EN] <= 1'b0;
              nibble        <= ~nibble;
              stop          <= f_40ns ? 1'b1 : 1'b0;
              substate      <= f_40ns ? substate << 1 : substate;
            end
            // Unset Write mode - Wait 40us - Send next nibble or go to next INIT state
            4: begin
              lcd_ctrl [RW] <= 1'b1;
              stop          <= f_250ns ? 1'b1 : 1'b0;
              substate      <= f_250ns ? 4'b0000 : substate;
              init_state    <= nibble  ? INIT_MODE : INIT_SET;
            end
            default: begin
              lcd_ctrl    <= 3'b010;       // RS - RW - EN
              lcd_data    <= 4'b0000;
              lcd_rdy     <= 1'b0;
              nibble      <= 1'b0;
              stop        <= 1'b1;
            end
          end
        end
      end
    end
    // 2: CONFIG: to be implemented soon
    CONFIG: begin
    end
    // 4: SEND_DATA: will send data to LCD (4bit mode)
    SEND_DATA: begin
    end
    // 32: OFF: will turn of the LCD display
    //     To be implemented
    OFF: begin
    end
    // 0: IDLE : default status doing nothing, it must enable the ready bit
    default: begin
    end
  end
end

endmodule

