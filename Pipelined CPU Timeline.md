5-stage Pipelined CPU timeline: *reference only*

- Before Week 7: 
    - 1. Read CAAQA and make sure you **understand** how pipelined CPUs work.
    - 2. configure your Vivado environment and prepare for your editor ( VSCode [<-- this is enough] or Idea with plugin [<-- not necessary nor useful as for me])
- Week 7: Build a skeleton (create files and modules, finish between-stage registers)
- Week 8: Design Register and PC register. Finish Instruction Decode, Execution and Write Back stages. [simple but time consuming. easy to create bugs here]
- Week 9: Design memory access and implement Instruction Fetch and Memory stages. [not that easy to think of at first. just move on and debug it later]
- Week 10: Finish all parts, debug and try to pass simulation of simple testcases. [Running large testcases with simulation can be EXTREEEMELY slow]
- Week 11-13: Add I-cache, D-cache, branch predictions and debug. [you should better add I-cache early when debugging your code because a lot of bugs occurs only when your CPU is really "pipelined"]
- Week 14-16: Run on FPGA and debug. [if you have latches or some other weird thing in your design, it may take a while to find the bug]

Note: do not forget the grading policy of Pipelined CPU. If you want to do some advanced part of design, you should better finish the scheduled parts in advance and try to catch up with the final deadline.