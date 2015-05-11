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
  input wire  [0:0]           clk,
  input wire  [5:0]           cmd_in,
  input wire  [NFLAGS-1:0]    flags_in,
  input wire  [0:0]           driver_rdy,         // Not implemented yet
  input wire  [0:0]           enable,         // Not implemented yet
  input wire  [0:0]           rst,
  output reg  [0:0]           nctrl_count,
  output reg  [0:0]           ctrl_sel_count,
  output reg  [1:0]           ctrl_sel_data,
  output reg  [0:0]           ctrl_enable_driver,
  output reg  [0:0]           ctrl_error,   // Not implemented yet
  output reg  [0:0]           ctrl_rdy,
  output reg  [7:0]           ctrl_cmd
  );
//
wire [5:0] command;

/// LCD Commands
parameter [7:0] SETUP       = 8'b00101000;  //Execution time = 42us, sets to 4-bit interface, 2-line display, 5x8 dots
parameter [7:0] DISP_ON     = 8'b00001100;  //Execution time = 42us, Turn ON Display
parameter [7:0] ALL_ON      = 8'b00001111;  //Execution time = 42us, Turn ON All Display
parameter [7:0] ALL_OFF     = 8'b00001000;  //Execution time = 42us, Turn OFF All Display
parameter [7:0] CLEAR_CMD   = 8'b00000001;  //Execution time = 1.64ms, Clear Display
parameter [7:0] ENTRY_MODE  = 8'b00000110;  //Execution time = 42us, Normal Entry, Cursor increments, Display is not shifted
parameter [7:0] HOME        = 8'b00000010;  //Execution time = 1.64ms, Return Home
parameter [7:0] C_SHIFT_L   = 8'b00010000;  //Execution time = 42us, Cursor Shift
parameter [7:0] C_SHIFT_R   = 8'b00010100;  //Execution time = 42us, Cursor Shift
parameter [7:0] D_SHIFT_L   = 8'b00011000;  //Execution time = 42us, Display Shift
parameter [7:0] D_SHIFT_R   = 8'b00011100;  //Execution time = 42us, Display Shift

// Counter mux control select
parameter [0:0] CONTROL_COUNT = 1'b0,
                DRIVER_COUNT  = 1'b1;

// DATA IN mux control select
parameter [1:0] EXTERNAL_DATA = 2'b10,
                INTERNAL_CMD  = 2'b01,
                UNUSED_DATA   = 2'b00;

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

/// CONTROL STATE MACHINE
reg [5:0] ctrl_state;

/// INIT STATES
parameter [5:0] INIT_ON   = 6'b00_0001,
                INIT_SET  = 6'b00_0010,
                INIT_MODE = 6'b00_0100,
                INIT_DISP = 6'b00_1000,
                INIT_CLR  = 6'b01_0000,
                INIT_RDY  = 6'b10_0000,
                INIT_NOP  = 6'b00_0000;

/// CLEAR STATES
parameter [2:0] CLEAR_DO      = 3'b001,
                CLEAR_WAIT    = 3'b010,
                CLEAR_MEM_RST = 3'b100,  //unused - not needed
                CLEAR_NOP     = 3'b000;

// SEND DATA STATES
parameter [2:0] SEND_DO   = 1'b001,
                SEND_NOP  = 1'b000;

// store command on a reg afteer a en posedge
// or turn on an error flag if op changes while busy
assign command = (enable << cmd_in);

//always @(posedge enable or posedge driver_rdy) begin
always @(posedge clk) begin
  if (rst | ~enable) begin
    ctrl_state          <= 1;
    ctrl_sel_count      <= CONTROL_COUNT;
    ctrl_sel_data       <= UNUSED_DATA;
    ctrl_enable_driver  <= 1'b0;
    ctrl_rdy            <= 1'b1;
    ctrl_cmd            <= 8'b0000_0000;
    nctrl_count         <= 1'b1;
  end else begin
  case (command)
    // 1: INIT: will initiate the LCD and will set the default
    //    configuration (4bit - 2lines - AutoI/D)
    INIT: begin
      case (ctrl_state)
        // Needed only after FPGA programming, not implemented for now
        INIT_ON: begin
          ctrl_sel_count      <= CONTROL_COUNT;
          ctrl_sel_data       <= UNUSED_DATA;
          ctrl_enable_driver  <= 1'b0;
          ctrl_rdy            <= 1'b0;
          nctrl_count         <= flags_in[f_15000us] ? 1'b1 : 1'b0;
          ctrl_state          <= flags_in[f_15000us] ? INIT_SET : INIT_ON;
        end

        INIT_SET: begin
          ctrl_sel_count      <= DRIVER_COUNT;
          ctrl_sel_data       <= INTERNAL_CMD;
          ctrl_enable_driver  <= 1'b1;
          ctrl_rdy            <= 1'b0;
          ctrl_cmd            <= SETUP;
          ctrl_state          <= (driver_rdy & ctrl_enable_driver) ? INIT_MODE : INIT_SET;
        end

        INIT_MODE: begin
          ctrl_sel_count      <= DRIVER_COUNT;
          ctrl_sel_data       <= INTERNAL_CMD;
          ctrl_enable_driver  <= 1'b1;
          ctrl_rdy            <= 1'b0;
          ctrl_cmd            <= ENTRY_MODE;
          ctrl_state          <= (driver_rdy & ctrl_enable_driver) ? INIT_DISP : INIT_MODE;
        end

        INIT_DISP: begin
          ctrl_sel_count      <= DRIVER_COUNT;
          ctrl_sel_data       <= INTERNAL_CMD;
          ctrl_enable_driver  <= 1'b1;
          ctrl_rdy            <= 1'b0;
          ctrl_cmd            <= DISP_ON;
          ctrl_state          <= (driver_rdy & ctrl_enable_driver) ? INIT_CLR : INIT_DISP;
        end

        // These two states are equivalent to CLEAR. The state machine could jump there instead
        // Or just change the usage model and not include an initial clear on the INIT sequence
        INIT_CLR: begin
          ctrl_sel_count      <= DRIVER_COUNT;
          ctrl_sel_data       <= INTERNAL_CMD;
          ctrl_enable_driver  <= 1'b1;
          ctrl_rdy            <= 1'b0;
          ctrl_cmd            <= CLEAR_CMD;
          ctrl_state          <= (driver_rdy & ctrl_enable_driver) ? INIT_RDY : INIT_CLR;
        end

        INIT_RDY: begin
          ctrl_sel_count      <= CONTROL_COUNT;
          ctrl_sel_data       <= UNUSED_DATA;
          ctrl_enable_driver  <= 1'b0;
          ctrl_rdy            <= 1'b0;
          nctrl_count         <= flags_in[f_1640us] ? 1'b1 : 1'b0;
          ctrl_state          <= flags_in[f_1640us] ? INIT_NOP : INIT_RDY;
        end

        default: begin
          ctrl_state          <= 1;
          ctrl_sel_count      <= CONTROL_COUNT;
          ctrl_sel_data       <= UNUSED_DATA;
          ctrl_enable_driver  <= 1'b0;
          ctrl_rdy            <= 1'b1;
          nctrl_count         <= 1'b1;
        end
      endcase
    end
    // 2: CONFIG: to be implemented soon
    CONFIG: begin
    end
    // 4: SEND_DATA: will send data to LCD
    SEND_DATA: begin
      case (ctrl_state)
        SEND_DO: begin
          ctrl_sel_count      <= DRIVER_COUNT;
          ctrl_sel_data       <= EXTERNAL_DATA;
          ctrl_enable_driver  <= 1'b1;
          ctrl_rdy            <= 1'b0;
          ctrl_state          <= (driver_rdy & ctrl_enable_driver) ? SEND_NOP : SEND_DO;
        end

        default: begin
          ctrl_sel_count      <= CONTROL_COUNT;
          ctrl_sel_data       <= UNUSED_DATA;
          ctrl_enable_driver  <= 1'b0;
          ctrl_rdy            <= 1'b1;
          nctrl_count         <= 1'b1;
        end
      endcase
    end
    // 8: CLEAR: will clean the display and set the DDRAM address to 0
    CLEAR: begin
      case (ctrl_state)
        CLEAR_DO: begin
          ctrl_sel_count      <= DRIVER_COUNT;
          ctrl_sel_data       <= INTERNAL_CMD;
          ctrl_enable_driver  <= 1'b1;
          ctrl_rdy            <= 1'b0;
          ctrl_cmd            <= CLEAR_CMD;
          ctrl_state          <= (driver_rdy & ctrl_enable_driver) ? CLEAR_WAIT : CLEAR_DO;
        end

        CLEAR_WAIT: begin
          ctrl_sel_count      <= CONTROL_COUNT;
          ctrl_sel_data       <= UNUSED_DATA;
          ctrl_enable_driver  <= 1'b0;
          ctrl_rdy            <= 1'b0;
          nctrl_count         <= flags_in[f_1640us] ? 1'b1 : 1'b0;
          ctrl_state          <= flags_in[f_1640us] ? CLEAR_NOP : CLEAR_WAIT;
        end
        CLEAR_MEM_RST: begin
          ;
        end
        default: begin
          ctrl_state          <= 1;
          ctrl_sel_count      <= CONTROL_COUNT;
          ctrl_sel_data       <= UNUSED_DATA;
          ctrl_enable_driver  <= 1'b0;
          ctrl_rdy            <= 1'b1;
          nctrl_count         <= 1'b1;
        end
      endcase
    end
    // 32: OFF: will turn of the LCD display
    //     To be implemented
    OFF: begin
    end
    // 0: IDLE : default status doing nothing, it must enable the ready bit
    default: begin
      ctrl_state          <= 1;
      ctrl_sel_count      <= CONTROL_COUNT;
      ctrl_sel_data       <= UNUSED_DATA;
      ctrl_enable_driver  <= 1'b0;
      ctrl_rdy            <= 1'b1;
      nctrl_count         <= 1'b1;
    end
  endcase
  end
end

endmodule

