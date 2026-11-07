# Design and Verification of AMBA APB Protocol (Verilog + UVM)

Implementation of an AMBA APB3 slave with a memory behind it, verified with a
Verilog testbench and a UVM environment. Built and simulated in Xilinx Vivado 2024.1
(xsim). Based on the paper:

> Shankar, Dipti Girdhar, Neeraj Kr. Shukla, "Design and Verification of AMBA APB
> Protocol," International Journal of Computer Applications (0975-8887), Vol. 95,
> No. 21, June 2014.

## Features
- APB3 slave with IDLE -> SETUP -> ACCESS operation, zero wait states (PREADY)
- Memory (256 x 32) connected behind the slave (WR, RD, ADDR_WR, ADDR_RD, DIN, DOUT)
- APB master (bridge model) with a simple start/done command interface
- Verilog testbench: directed + random tests with automatic PASS/FAIL checking<img width="1366" height="768" alt="apbslave1 jpeg" src="https://github.com/user-attachments/assets/589ededb-d883-4269-b072-8dc8a9d4492a" />
<img width="1366" height="768" alt="apbslave1 jpeg" src="https://github.com/user-attachments/assets/cfa93672-1f9e-4e31-9563-d9d01818260e" />

- UVM environment: sequence item, sequences, sequencer, driver, monitor, agent,
  scoreboard (reference memory model), environment, test

## Repository structure
```
rtl/
  apb_slave.v        APB3 slave
  memory.v           Memory behind the slave
  apb_top.v          Top: slave + memory
  apb_master.v       APB master / bridge model (testbench use)
tb/
  verilog/
    apb_tb.v         Verilog testbench (master + DUT)
  uvm/
    apb_if.sv        APB interface with clocking blocks
    apb_pkg.sv       Package including all UVM classes
    tb_top.sv        UVM top testbench
    apb_seq_item.vh  apb_sequence.vh  apb_sequencer.vh  apb_driver.vh
    apb_monitor.vh   apb_agent.vh     apb_scoreboard.vh apb_env.vh
    apb_test.vh
docs/                Waveform and console screenshots
```

## How to run (Vivado 2024.1)

### Verilog testbench
1. Add `rtl/*.v` as Design Sources and `tb/verilog/apb_tb.v` as a Simulation Source.
2. Set `apb_tb` as the simulation top and run Behavioral Simulation.
3. Expected console result: `TEST SUMMARY: PASS = 22, FAIL = 0`.

### UVM testbench
1. Add `rtl/apb_slave.v`, `rtl/memory.v`, `rtl/apb_top.v` and all files in `tb/uvm/`
   as Simulation Sources. Set the `.vh` files to type "Verilog Header".
2. In the Tcl Console:
   ```
   set_property top tb_top [get_filesets sim_1]
   set_property -name {xsim.compile.xvlog.more_options} -value {-L uvm} -objects [get_filesets sim_1]
   set_property -name {xsim.elaborate.xelab.more_options} -value {-L uvm} -objects [get_filesets sim_1]
   update_compile_order -fileset sim_1
   ```
3. Run Behavioral Simulation, then `run 2000ns`.

## Results
| Test | Result |
|---|---|
| Verilog testbench | 22 PASS, 0 FAIL |
| UVM (20 write + 20 read-back) | UVM_ERROR = 0, UVM_FATAL = 0, all reads matched |

Screenshots are in `docs/`.

## Tools
Xilinx Vivado 2024.1, Vivado Simulator (xsim), UVM 1.2
