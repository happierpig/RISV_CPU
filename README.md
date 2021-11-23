# RISCV-CPU

#### Write Log

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

#### Repo Structure

```
|--riscv/
|  |--ctrl/             Interface with FPGA
|  |--sim/              Testbench, add to Vivado project only in simulation
|  |--src/              Where your code should be
|  |  |--common/                Provided UART and RAM
|  |  |--Basys-3-Master.xdc     constraint file
|  |  |--cpu.v                  Fill it. 
|  |  |--hci.v                  A bus between UART/RAM and CPU
|  |  |--ram.v                  RAM
|  |  |--riscv_top.v            Top design
|  |--sys/              Help compile
|  |--testcase/         Testcases
|  |--autorun_fpga.sh   Autorun Testcase on FPGA
|  |--build_test.sh     Run it to build test.data from test.c
|  |--FPGA_test.py      Test correctness on FPGA
|  |--pd.tcl            Program device the bitstream onto FPGA
|  |--run_test.sh       Run test
|  |--run_test_fpga.sh  Run test on FPGA
|--serial/              A third-party library for interfacing with FPGA ports
```
