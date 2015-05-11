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

module L1602A_driver #(
  parameter [3:0] NFLAGS  = 7,
  parameter [0:0] MODE    = 1,         // 0: 8 bit - 1: 4bit
  parameter [0:0] LINES   = 1          // 0: 1 line - 1: 2 lines
  )(
  input wire  [0:0]           clk,
  input wire  [7:0]           data_in,
  input wire  [NFLAGS-1:0]    flags_in,
  input wire  [0:0]           enable,
  input wire  [0:0]           is_data,
  input wire  [0:0]           rst,
  output reg  [0:0]           driver_count,
  output reg  [0:0]           driver_error,   // Not implemented yet
  output reg  [0:0]           driver_rdy,
  output reg  [2:0]           driver_ctrl,    // RS - RW - E
  output reg  [7-(MODE*4):0]  driver_data
  );


/// LCD control signal names
parameter [1:0] RS = 2,
                RW = 1,
                EN = 0;

/// FLAGS: counter checkpoints used to have proper delays between commands
parameter [3:0] f_40ns    =6,
                f_250ns   =5,
                f_42us    =4,
                f_100us   =3,
                f_1640us  =2,
                f_4100us  =1,
                f_15000us =0;

/// FSM STATE Names
parameter [3:0] INIT  = 4'b0000,
                SEND  = 4'b0001,
                CLOSE = 4'b0010,
                END   = 4'b0100;

reg [3:0] state;
reg [0:0] nibble;     // Records which nibble is being processed 0: higher 1: lower

// store data_in on a reg afteer a en posedge
// or turn on an error flag if op changes while busy

always @(posedge clk) begin
  state <= rst ? 4'b1000 : state;
  if(~enable) begin
    state <= INIT;
    driver_rdy    <= 1'b1;
    nibble        <= 1'b0;
  end else begin
    case (state)
      // Set Write mode - Wait 40ns
      INIT: begin
        driver_ctrl[RW] <= 1'b0;
        driver_ctrl[RS] <= is_data;
        driver_rdy      <= 1'b0;
        driver_count    <= flags_in[f_40ns] ? 1'b1 : 1'b0;
        state           <= flags_in[f_40ns] ? SEND: INIT;
      end
      // Enable bus - send first nibble - wait 230ns
      SEND: begin
        driver_ctrl[EN] <= 1'b1;
        driver_ctrl[RS] <= is_data;
        driver_rdy      <= 1'b0;
        driver_data     <= nibble  ? data_in[3:0] : data_in[7:4];
        driver_count    <= flags_in[f_250ns] ? 1'b1 : 1'b0;
        state           <= flags_in[f_250ns] ? CLOSE : SEND;
      end
      // Disable bus wait 10ns (40ns)
      CLOSE: begin
        driver_ctrl[EN] <= 1'b0;
        driver_ctrl[RS] <= is_data;
        driver_rdy      <= 1'b0;
        nibble          <= ~nibble;
        driver_count    <= flags_in[f_40ns] ? 1'b1 : 1'b0;
        state           <= flags_in[f_40ns] ? END : CLOSE;
      end
      // Unset Write mode - Wait 40us - Send next nibble or go to next INIT state
      END: begin
        driver_ctrl[RW] <= 1'b1;
        driver_ctrl[RS] <= is_data;
        driver_rdy      <= 1'b0;
        driver_count    <= flags_in[f_250ns] ? 1'b1 : 1'b0;
        state           <= flags_in[f_250ns] ? (nibble ? INIT : 4'b1000) : END;
      end
      default: begin
        driver_ctrl   <= 3'b010;       // RS - RW - EN
        driver_data   <= 4'b0000;
        driver_count  <= 1'b1;
        driver_rdy    <= 1'b1;
        nibble        <= 1'b0;
        //state         <= 4'b1000;
      end
    endcase
  end
end

endmodule

