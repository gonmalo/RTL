`timescale 1ns / 1ps


module PSDRAMDriver(
        output reg WE,
        output reg CE,
        output reg OE,
        output reg LB,
        output reg UB,
        output reg ADV,
        output reg CRE,
        input WAIT,
        output [23:0] ADDR,
        inout  [15:0] DATA_BUS,

        input  [22:0] Address,
        input  [15:0] DataWrite,
        output reg [15:0] DataRead,
        input  StartWrite,
        input  StartRead,
        input  StartConfig,
        input  StartReadBCR,
        output reg StartDownloading,
        output reg StartUploading,
        output reg ReadyWrite,
        output reg ReadyRead,
        output ReadyConfig,
        output reg ReadyReadBCR,
        output reg StartSendBuff,
        output [7:0]DebugRam,

        input  ClkMem
    );


parameter NUMBER_OF_PIXELS = 128; //Largo de la rafaga
parameter OPCODE = 23'b00_10_00_0_0_011_0_0_1_00_01_1_111_0;


parameter START_CONFIG1  = 1;
parameter START_CONFIG2  = 2;
parameter START_CONFIG3  = 3;
parameter START_CONFIG4  = 4;
parameter START_READ_BCR1= 5;
parameter START_READ_BCR2= 6;
parameter START_READ_BCR3= 7;
parameter START_READ1    = 8;
parameter START_READ2    = 9;
parameter START_READ3    =10;
parameter START_READ4    =11;
parameter START_READ5    =12;
parameter START_WRITE1  = 13;
parameter START_WRITE2  = 14;
parameter START_WRITE3  = 15;
parameter START_WRITE4  = 16;



reg [4:0]  Estados1;
reg [15:0] DataToBus;
reg ConfigReady;
reg Writing;
reg [2:0] Counter;
reg [7:0] DataCounter;
reg _WAIT;


assign DebugRam = {ClkMem,Estados1[4:0]};//DataCounter;

assign ReadyConfig = ConfigReady;
assign ADDR = ConfigReady ? (Address<<1) : OPCODE;

assign DATA_BUS[15:0] = Writing? {DataToBus[15:0]}:16'bZ;

initial begin
  CRE = 0;
  ADV = 0;
  LB = 0;
  UB = 0;
  OE = 0;
  CE = 1;
  WE = 0;
  Estados1 = 0;
  DataRead = 0;
  ReadyWrite = 0;
  ReadyRead = 0;
  ConfigReady = 0;
  Writing = 0;
  Counter = 0;
  DataCounter = 0;
  StartDownloading = 0;
  StartUploading = 0;
  _WAIT = 0;

  StartSendBuff = 0;
  ReadyReadBCR = 0;
  DataToBus = 0;

end

always @(negedge ClkMem) begin
  case (Estados1)
    0: begin
      ReadyRead <= 0;
      ReadyWrite <= 0;


      if (StartWrite) begin
        Estados1 <= START_WRITE1;
      end

      if (StartRead) begin
        Estados1 <= START_READ1;
      end

      if (StartReadBCR) begin
        Estados1 <= START_READ_BCR1;
      end

      if (StartConfig) begin
        Estados1 <= START_CONFIG1;
      end

    end
    /*
     * START CONFIG
     */
    START_CONFIG1:
    begin
      CRE <= 1;
      ADV <= 1;
      WE  <= 1;
      Estados1 <= START_CONFIG2;
      ConfigReady <= 0;
    end

    START_CONFIG2:
    begin
      ADV <= 0;
      CE  <= 0;
      Estados1 <= START_CONFIG3;
    end

    START_CONFIG3:
    begin
      ADV <= 1;
      if(Counter == 1) begin// depende del clock. 70ns
        Estados1 <= START_CONFIG4;
        WE <= 0;
        Counter <= 0;
      end
      else
        Counter <= Counter + 1;

    end

    START_CONFIG4:
    begin
      if (Counter == 3) begin
        WE  <= 1;
        CE  <= 1;
        CRE <= 0;
        Estados1 <= START_READ1;// Estados1 <= 0;
        Counter <= 0;
        ConfigReady <= 1;

      end
      else
        Counter <= Counter + 1;
    end


    /*
     * START READ CONFIG
     */
    START_READ_BCR1:
    begin
      ConfigReady <= 0;
      CRE <= 1;
      ADV <= 0;
      CE  <= 0;
      OE  <= 1;
      WE  <= 1;
      Estados1 <= START_READ_BCR2 ;
    end

    (START_READ_BCR2):
    begin
      CRE <= 0;
      ADV <= 1;

      if (Counter == 3) begin
        Counter <= 0;
        OE <= 0;
        Estados1 <= START_READ_BCR3;
      end
      else begin
        Counter <= Counter + 1;
      end
    end


    (START_READ_BCR3):
    begin
      if (_WAIT) begin
        CE <= 1;
        Estados1 <= START_READ1;
        ConfigReady <= 1;
      end
    end

  /*
   * START READ
   */
    (START_READ1):
    begin
      ADV <= 0;
      CE  <= 0;
      OE  <= 1;
      WE  <= 1;
      CRE <= 0;
      Estados1 <= START_READ2;
    end

    START_READ2:
    begin
      ADV <= 1;
      WE  <= 1;
      Estados1 <= START_READ3;
    end

    START_READ3:
    begin
      if (Counter == 1) begin
        OE <= 0;
        Estados1 <= START_READ4;
        Counter <= 0;
      end
      else
        Counter <= Counter + 1;
    end

    START_READ4:
    begin
      if(_WAIT) begin
        Estados1 <= START_READ5;
        StartDownloading <= 1;
      end
    end

    START_READ5:
    begin
      StartDownloading <= 0;
      if (DataCounter == NUMBER_OF_PIXELS-1) begin
        Estados1 <= 0;
        OE <= 1;
        CE <= 1;
        DataCounter <= 0;
        ReadyRead <= 1;
        DataRead <= DATA_BUS;
      end
      else begin
        DataCounter <= DataCounter + 1;
        DataRead <= DATA_BUS;
      end
    end

    /*
     * START WRITE
     */
    START_WRITE1:
    begin
      ADV <= 0;
      CE  <= 0;
      OE  <= 1;
      WE  <= 0;
      Estados1 <= START_WRITE2;
      Writing <= 1;
    //  StartSendBuff <= 1;
    end

    START_WRITE2:
    begin
      ADV <= 1;
      Estados1 <= START_WRITE3;
      StartUploading <= 1;
    //  StartSendBuff <= 1;                   // MODIFICADO
    end

    START_WRITE3:
    begin
      //StartSendBuff <= 1;
      //ADV <= 1;
      StartUploading <= 0;
      if (_WAIT) begin
        Estados1 <= START_WRITE4;
        StartSendBuff <= 1;
        //StartUploading <= 1;
        DataCounter <= 0;
        DataToBus <= DataWrite;//DataCounter;//
      end
    end

    START_WRITE4:
    begin
      //StartUploading <= 0;
      if (DataCounter == NUMBER_OF_PIXELS-1) begin
        Estados1 <= 0;
        OE <= 1;
        CE <= 1;
        DataCounter <= 0;
        Writing <= 0;
        ReadyWrite <= 0;
        StartSendBuff <= 0;                 // MODIFICADO
      end
      else begin
        DataCounter <= DataCounter + 1;
        DataToBus <= DataWrite;// DataCounter;//
        if (DataCounter == NUMBER_OF_PIXELS-2)
          ReadyWrite <= 1;
      end

    end

  endcase
end

always @(posedge ClkMem) begin
  if(WAIT)
    _WAIT <= 1;
  else
    _WAIT <= 0;
end

endmodule

