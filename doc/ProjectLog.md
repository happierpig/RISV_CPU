## Timeline

2021.11.2 Learn Tomasulo and Verilog

2021.11.3 Complete the design drawing and start writing

2021.11.4 Finish PC/Fetcher/Register

2021.11.5 Finish Decoder/RS/ROB

2021.11.6 Finish LSB/ALU and modify some unreasonable codes

2021.11.7 Complete memory control unit and Finish all ,start debug

2021.11.8 Connect all

2021.11.9 Hello World

2021.11.12 Debugging

2021.11.13 Debugging and Pass all simulation test

2021.11.14 Add i-cache ,debug and pass all.

2021.11.15 Add Branch Prediction and debug

2021.11.17 Optimization of i-cache(1 instruction per cycle) and add write buffer

2021.11.18 Debug of Misbranch

2021.11.19 Add output(uart_full check) and support input

2021.11.20 Pass FPGA tests



## Debug Log

### Register 可写入信号

- 没有新的指令进入decode，组合输出不变，导致register不断取同一个值设置BusyTag
- 增加in_fetcher_ce 信号解决

### ROB 可写入判断问题

``NOP空指令`禁止写入

> 实际上写入了也没关系，commit阶段对NOP没有要求
>
> rs lsb存进去`NOP不出问题，不会commit

### Right Branch Commit

- 正确跳转指令的处理需要head++

​		而不能只处理错误跳转

### ROB empty loop queue commit question

- 我的设计：commit之后readyTag仍然是True，避免某一个周期Reg里面没有更新而ROB当中Ready已经消失，导致的找不到源寄存器数据问题。然后在`Store Entry`的时候将readyTag打为False

- 所以检查头部能否Commit时还要检查队列是不是空

  ```verilog
  if(ready[nowPtr] == `TRUE && head != tail) begin end
  ```

### HCI设计导致的程序无法终止问题

- ```verilog
  //hci.v
  if (~q_io_en & io_en) begin //io_en: address[17:16] = 2'b11时为True; q_io_en为 q_io_en <= io_en
    //所以当写入与地址传入不同时的时候，进不去这个if就无法终止
    if (io_wr) begin      // memory write signal
      case (io_sel)       // io_sel is address[2:0]
        3'h00: begin      // 0x30000 write: output byte
          if (!tx_full && io_din!=8'h00) begin
            d_tx_data = io_din;
            d_wr_en   = 1'b1;
          end
          $write("%c", io_din);
        end
        3'h04: begin      // 0x30004 write: indicates program stop
          if (!tx_full) begin
            d_tx_data = 8'h00;
            d_wr_en = 1'b1;
          end
          d_state = S_DECODE; 
          d_program_finish = 1'b1;
          $display("IO:Return");
          $finish;
        end
      endcase
  ......
  ```

- 解决方案：memCtrl写入数据时，传入地址的**同时**进行写入。

### Multi-driven net

- 在不同的时序逻辑always块当中对同一寄存器赋值会产生数据竞争，综合出来的电路会有**多驱动**现象
- 解决方法：写到同一个always块里，综合器会自动处理(也许是综合成多路选择器)

### Monitor CDB

- ALU/LSB的广播与ROB readyTag的更新是同一个周期执行的，在这之前进入栈中的指令是可以被广播到的，在这之后进入的指令可以从ROB中获取，这一周期进入的指令需要**同时监听CDB**避免无法获得源寄存器的值。

### LSB Load RAW问题

- RAW：Load指令前面*相同内存地址*的Store还未写入完毕，Load就去读写了

- 我的Check：Load执行之前会去ROB遍历是否有地址相同的`未commit`Store指令

  因为LSB是顺序的 所以该Load之前的Store都已经计算出了地址并且进入了ROB当中

- 问题：在LSB pop掉头部store后，ROB中地址更新会慢一个周期，这个周期的Load会执行掉。

- 解决 ： 增加一个判断

  ```verilog
  if(in_rob_check == `FALSE && address[nowPtr] != out_destination)
  ```


### Misbranch Reflush

- 注意`misbranch`需要冲刷掉的所有信号，避免遗漏。
- 如：`memctrl`当中的flag信号需要刷掉

### uart_full 时延

- 向uart发出申请写出output，其输入的`io_buffer_full`会有**两个周期的时延**，所以每次输出后要等待两个周期再尝试下一次输出

### ram 读数据延迟

- 由于ram的设计(详见common/block_ram)，读入地址的更新是时序逻辑，导致申请读入数据后**两个周期**才能获得数据。

- Memory Control的设计需要适合延迟两个周期



### io_in

- 仍未解决
- `statement_test`测试点在增加读入功能后，每次上板后第一次跑`statement_test`以及只跑`statement_test`都可以正确跑出。但如果跑了其他测试点后再跑`statement_test`会得到错误输出。
- 猜测：reset问题/降频不到位；但并未找到。