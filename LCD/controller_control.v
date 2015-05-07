/*
 *  Control module for LCD 1602 A controller
 *  Initial version:
 *    - Only INIT, WRITE DATA and CLEAR are implemented
 *
 *  gonzalof
 */

module controller_control #(
  parameter [3:0] NFLAGS  = 7,
  parameter [0:0] MODE = 1,         // 0: 8 bit - 1: 4bit
  parameter [0:0] LINES = 1         // 0: 1 line - 1: 2 lines
  )(
  input wire  [5:0]           cmd_in,
  input wire  [NFLAGS:0]      flags_in,
  input wire  [0:0]           driver_rdy,         // Not implemented yet
  input wire  [0:0]           enable,         // Not implemented yet
  input wire  [0:0]           rst,
  output reg  [0:0]           nctrl_count,
  output reg  [0:0]           ctrl_sel_count,
  output reg  [0:0]           ctrl_sel_data,
  output reg  [0:0]           ctrl_error,   // Not implemented yet
  output reg  [0:0]           ctrl_rdy,
  output reg  [7:0]           ctrl_cmd
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

/// FLAGS: counter checkpoints used to have proper delays between commands
parameter [3:0] f_40ns    =6,
                f_250ns   =5,
                f_42us    =4,
                f_100us   =3,
                f_1640us  =2,
                f_4100us  =1,
                f_15000us =0;

/// INIT STATE MACHINE
parameter [5:0] INIT_ON   = 5'b0_0000,
                INIT_SET  = 5'b0_0001,
                INIT_MODE = 5'b0_0010,
                INIT_DISP = 5'b0_0100,
                INIT_CLR  = 5'b0_1000,
                INIT_RDY  = 5'b1_0000;

reg [5:0] init_state;

always @(posedge clk) begin
  case (cmd_in) begin
    // 1: INIT: will initiate the LCD and will set the default
    //    configuration (4bit - 2lines - AutoI/D)
    INIT: begin
      case (init_state) begin
        // After turned ON set default values to control lines - Wait for 15 ms - Lower the ready bit
        INIT_ON: begin
          init_state  <= f_15000us ? INIT_SET : INIT_ON;
          stop        <= f_15000us ? 1'b1 : 1'b0;
        end

        INIT_SET: begin
          stop          <= f_250ns ? 1'b1 : 1'b0;
          init_state    <= nibble  ? INIT_MODE : INIT_SET;
        end
        default: begin
          stop        <= 1'b1;
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

