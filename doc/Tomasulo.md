## Tomasulo Steps

### Issue

- 从指令队列(FIFO)中取指令，此时为`In-order`；

- 检查结构冒险：目标RS有空 && ROB有空   -> 发射进入RS

  否则Stall

- 寻找操作数：Register File(Get : Value/ROB Index)->ROB[Index]

  找到将数据送到RS，否则将`ROB Index`送回RS.Field(Q)

- Register Rename：将自己在ROB中的Index带回RS作为Tag，并把RegisterFile中目的寄存器的标记改为Tag

- Busy：将RS和ROB对应位置的Buffer打上占用标签 (也许是Control Entries？

  同时更新RS和ROB中需要的信息

### Execute

- Wait For Operand：通过之前带回的操作数的Tag监听CDB，听到了则写入Value
- 两个操作数就绪后，将Instr从RS传入FU执行
- 不同类型的指令
  - Register Operation：执行不同的周期数
  - Load：Two Steps
    - 等base register + 计算有效地址
    - Read From Mem
  - Store：One Step
    - 等base register + 计算有效地址

### Write result

- 广播：结果算出，通过CDB向所有RS进行广播，同时更新ROB

- 释放RS：将RS的Busy Tag打上空闲标记

- Store 特殊处理：

  如果Source Operand就绪，写入Value field of ROB entry

  否则就要在ROB中监听CDB等待Value

### Commit

每周期检查ROB头部(保证commit in-order)，如果已经Ready，则分三种情况Commit

- Branch Instr. ：

  如果预测是错误的，则清空RS、ROB和Instr queue，设置pc为正确跳转的地址，重新来过。

- Register Operand + Load : 

  更新Register File，条件是Tag相同才能更新

- Store：

  更新内存

将占用标记打掉。

## Tomasulo Principle

- 提高性能的本质是提高部件的使用率，通过使得没有依赖的指令尽快执行的方式。

- 所谓`Register Renaming`，不过如此

  将原先的区别标记(寄存器下标)丢掉，重新建立新的标识符(与指令**一一映射**，例如ROB下标)，从而解决了antidependecny

  本质上就是取消了依赖性

- 在LS指令目标内存地址不同的情况下，确实不会出现冒险，这是因为有关于寄存器的数据冲突都已经被`Register Renaming`所重命名了；但目标内存地址相同时，会出现数据冲突，因为数据冲突与数据存在寄存器还是Memory当中没有关系，源于读写顺序在时空上被扰乱，在ROB中指令一定是按顺序commit的，所以不会出现WAW和WAR，RAW的消除依赖于：任何一个load指令在读内存之前要确保前面没有相同地址的STORE指令。