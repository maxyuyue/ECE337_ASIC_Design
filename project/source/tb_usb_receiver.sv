`timescale 1ns / 10ps

module tb_usb_receiver ();
  localparam  CLK_PERIOD    = 1;

  logic tb_clk;
  logic tb_n_rst;
  logic tb_d_plus;
  logic tb_d_minus;
  logic tb_r_enable;
  logic [7:0] tb_r_data;
  logic tb_empty;
  logic tb_full;
  logic tb_rcving;
  logic tb_r_error;
  logic [7:0] tb_test_byte;
  logic [3:0] tb_PID;

  integer tb_bit_num;
  integer tb_test_num;
  string tb_test_description;

  task reset_dut;
  begin
    tb_n_rst = 0;

    @(posedge tb_clk);
    @(posedge tb_clk);

    @(negedge tb_clk);
    
    tb_n_rst = 1;

    @(negedge tb_clk);
    @(negedge tb_clk);
  end
  endtask

  task send_byte;
    input logic [7:0] target;
    integer i;
  begin
    @(posedge tb_clk);
    tb_bit_num = 0;
    for(i = 0; i < 8; i++ ) begin
      if(target[i] == 0) begin
        tb_d_plus =  ~tb_d_plus;
        tb_d_minus = ~tb_d_plus;
      end
      #(CLK_PERIOD * 8);
      tb_bit_num ++;
    end
  end
  endtask

  task send_sync;
  begin
    send_byte(8'b10000000);
  end
  endtask

  task send_PID;
    input logic [3:0]PID;
    input logic expected_PID_ERR;
  begin
    send_byte({~PID, PID});
  end
  endtask

  task send_eop;
    integer i;
  begin
    @(posedge tb_clk);
    tb_bit_num = 0;
    for(i = 0; i < 3; i++ ) begin
      tb_d_plus = 0;
      tb_d_minus = 0;
      #(CLK_PERIOD * 8);
      tb_bit_num ++;
    end
    tb_d_plus = 1;
    #(CLK_PERIOD * 8);
  end
  endtask

  task send_bit;
    input logic target;
  begin
    if(target == 0) begin
        tb_d_plus =  ~tb_d_plus;
        tb_d_minus = ~tb_d_plus;
    end
    #(CLK_PERIOD * 8);
    tb_bit_num ++;
  end
  endtask

  task read_fifo;
   input logic [7:0] expected_out;
  begin
    
    if(tb_r_data == expected_out) begin
      $info("Correct! test case %d. %s", tb_test_num, tb_test_description);
    end else begin
      $info("!!!!!!!!!!!!! Incorrect!. test case %d. %s", tb_test_num, tb_test_description);
    end

    @(negedge tb_clk);
    tb_r_enable = 1;
    #(CLK_PERIOD);
    tb_r_enable = 0;
    #(CLK_PERIOD * 3);

  end
  endtask

  // Clock generation block
  always begin
    // Start with clock low to avoid false rising edge events at t=0
    tb_clk = 1'b0;
    // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
    tb_clk = 1'b1;
    // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
  end

  usb_receiver DUT (
    .clk(tb_clk),
    .n_rst(tb_n_rst),
    .d_plus(tb_d_plus),
    .d_minus(tb_d_minus),
    .r_enable(tb_r_enable),
    .r_data(tb_r_data),
    .empty(tb_empty),
    .full(tb_full),
    .rcving(tb_rcving),
    .r_error(tb_r_error),
    .PID(tb_PID)
  );
  

  // begin
  initial begin
    tb_n_rst = 1;
    tb_d_plus = 1;
    tb_d_minus = 0;
    tb_r_enable = 0;
    tb_bit_num = 0;
    tb_test_num = 0;


    // test case 1 reset DUT
    tb_test_num++;
    tb_test_description = "reset DUT";
    tb_bit_num = 0;
    reset_dut();
    #(CLK_PERIOD * 3);

    // test case 2 send a byte 
    tb_test_num++;
    tb_test_description = "send a byte";
    tb_bit_num = 0;
    reset_dut();
    #(CLK_PERIOD * 3);

    tb_test_byte = 8'b01010101;
    send_sync();
    send_PID(4'b0001);
    send_byte(tb_test_byte);
    send_eop();
    #(CLK_PERIOD * 3);
    read_fifo(tb_test_byte);

    // test case 3 send three bytes
    tb_test_num++;
    tb_test_description = "send three bytes";
    tb_bit_num = 0;
    reset_dut();
    #(CLK_PERIOD * 3);

    send_sync();
    send_PID(4'b0001);
    tb_test_byte = 8'b00000000;
    send_byte(tb_test_byte);
    tb_test_byte = 8'b01000000;
    send_byte(tb_test_byte);
    tb_test_byte = 8'b01100001;
    send_byte(tb_test_byte);
    send_eop();
    #(CLK_PERIOD * 3);
    read_fifo(8'b00000000);
    #(CLK_PERIOD);
    read_fifo(8'b01000000);
    #(CLK_PERIOD);
    read_fifo(8'b01100001);

    // test case 4 SYNC err case
    tb_test_num++;
    tb_test_description = "SYNC err case";
    tb_bit_num = 0;
    reset_dut();
    #(CLK_PERIOD * 3);

    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_bit(0);
    tb_test_byte = 8'b01000000;
    send_PID(4'b0001);
    send_byte(tb_test_byte);
    send_eop();
    #(CLK_PERIOD * 8);

    // test case 5 EOP err case
    tb_test_num++;
    tb_test_description = " EOP err case";
    tb_bit_num = 0;
    reset_dut();
    #(CLK_PERIOD * 3);

    send_sync();
    send_PID(4'b0001);
    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_bit(0);
    send_eop();
    #(CLK_PERIOD * 3);
    send_sync();
    send_eop();

    //immediate another packet 
    tb_test_num++;
    tb_test_description = "immediate another packet";
    tb_bit_num = 0;
    reset_dut();
    #(CLK_PERIOD * 3);

    send_sync();
    send_PID(4'b0001);
    send_eop();

    send_sync();
    send_PID(4'b0001);
    tb_test_byte = 8'b10000001;
    send_byte(tb_test_byte);
    send_eop();
    read_fifo(tb_test_byte);

    //incorrect PID err case 
    tb_test_num++;
    tb_test_description = "incorrect PID err case";
    tb_bit_num = 0;
    reset_dut();
    #(CLK_PERIOD * 3);

    send_sync();
    send_PID(4'b1111);
    tb_test_byte = 8'b10000001;
    send_byte(tb_test_byte);
    send_eop();
    
    //EOP during PID_RCV err case 
    tb_test_num++;
    tb_test_description = "EOP during PID_RCV err case";
    tb_bit_num = 0;
    reset_dut();
    #(CLK_PERIOD * 3);

    send_sync();
    send_bit(1);
    send_bit(1);
    send_bit(0);
    send_bit(1);
    send_eop();

    
  end


endmodule