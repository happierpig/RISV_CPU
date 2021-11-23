### Register 可写入信号

- 没有新的指令进入decode，组合输出不变，导致register不断取同一个值设置BusyTag
- 增加in_fetcher_ce 信号解决

### ROB 可写入判断问题

``NOP空指令`禁止写入

> 实际上写入了也没关系，commit阶段对NOP没有要求
>
> rs lsb存进去`NOP不出问题，不会commit

### Right Branch Commit

正确跳转指令的处理需要head++

而不能只处理错误跳转

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

- 解决方案：memCtrl写入数据时，传入地址的同时进行写入。

### Multi-driven net

- 在不同的时序逻辑always块当中对同一寄存器赋值会产生数据竞争，综合出来的电路会有多驱动现象
- 解决方法：写到同一个always块里，综合器会自动处理(也许是综合成多路选择器)

### Monitor CDB

- ALU/LSB的广播与ROB readyTag的更新是同一个周期执行的，在这之前进入栈中的指令是可以被广播到的，在这之后进入的指令可以从ROB中获取，这一周期进入的指令需要同时监听CDB避免无法获得源寄存器的值。

以及一大堆手误问题....

### LSB Load RAW问题

- RAW：Load指令前面*相同内存地址*的Store还未写入完毕，Load就去读写了

- 我的Check：Load执行之前会去ROB遍历是否有地址相同的`未commit`Store指令

  因为LSB是顺序的 所以该Load之前的Store都已经计算出了地址并且进入了ROB当中

- 问题：在LSB pop掉头部store后，ROB中地址更新会慢一个周期，这个周期的Load会执行掉。

- 解决 ： 增加一个判断

  ```verilog
  if(in_rob_check == `FALSE && address[nowPtr] != out_destination)
  ```

  