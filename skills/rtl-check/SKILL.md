---
name: rtl-check
description: Use this skill to run or propose RTL syntax checks, lint checks, and small directed simulations. Prefer Verilator by default, but use VCS/Xcelium when the design requires project-specific simulator support.
metadata:
  source: "RTL skill set"
  category: rtl
---

# RTL Check

Use this skill for RTL syntax checks, lint checks, and small directed simulations.

Core rule: a check must validate a concrete timing scenario or RTL property. Do not claim PASS unless a command actually ran.

Default tool: Verilator.

Use VCS or Xcelium instead when the design depends on UVM, encrypted IP, vendor primitives, gate-level/SDF, unsupported DPI, simulator-specific behavior, or company run scripts.

## When To Use

Use this skill when the user asks for:

- Verilator check
- lint / syntax / compile check
- small directed simulation
- waveform-assisted timing check
- validation of a WaveDrom scenario
- ready/valid, FIFO, arbiter, FSM, timeout, or abort behavior check

Do not use this skill for full UVM regressions or project signoff.

## Reference Guide

Reuse the RTL design references:

- `../rtl-design/references/module-template.md`
- `../rtl-design/references/handshake.md`
- `../rtl-design/references/fifo.md`
- `../rtl-design/references/arbiter.md`
- `../rtl-design/references/fsm.md`
- `../rtl-design/references/zero-base-design-note.md`

## Check Flow

Use this order:

1. Identify the module and exact files.
2. Identify include dirs, defines, and top module.
3. Run or propose syntax/lint command.
4. If behavior matters, pick one concrete timing scenario.
5. Build a tiny directed test for that scenario.
6. Assert only the few signals that prove the behavior.
7. Report what actually ran and what did not run.

## Default Lint Commands

Simple SystemVerilog RTL:

```sh
verilator --lint-only --Wall -sv <rtl_files>
```

If timing controls are present:

```sh
verilator --lint-only --Wall --timing -sv <rtl_files>
```

With include directories and defines:

```sh
verilator --lint-only --Wall -sv \
  +incdir+./rtl \
  +incdir+./include \
  +define+SIM \
  <rtl_files>
```

Useful options:

- `--top-module <name>`: specify top module
- `-Wno-fatal`: do not make warnings fatal
- `-Wno-DECLFILENAME`: ignore file/module name mismatch when intentional
- `-Wno-UNUSED`: suppress intentional unused signals
- `-Wno-WIDTH`: suppress only after reviewing width behavior

Do not suppress warnings blindly. Explain why the warning is harmless or unavoidable.

## Lint Review Priority

Prioritize findings in this order:

1. syntax error
2. missing include or macro
3. multiple drivers
4. inferred latch
5. combinational loop
6. width mismatch
7. uninitialized state
8. unused signal caused by design bug
9. incomplete assignment or unreachable branch
10. filename/module mismatch

Width warnings must be reviewed carefully in RTL.

## Directed Simulation Goal

A small simulation should support one timing story, not broad coverage.

Each directed test should:

1. reset DUT
2. drive only the needed handshake or state transition
3. assert the signals that prove the scenario
4. optionally dump VCD/FST
5. match one WaveDrom scene when available

Good test names:

```text
tb_<module>_stall_hold.cpp
tb_<module>_stall_release.cpp
tb_<module>_simul_consume_refill.cpp
tb_<module>_fifo_full_boundary.cpp
tb_<module>_fifo_empty_boundary.cpp
tb_<module>_response_wait.cpp
tb_<module>_timeout_error.cpp
```

## Minimal Verilator Simulation

Build:

```sh
verilator -Wall -sv --cc <rtl_files> \
  --top-module <top_module> \
  --exe tb_<scenario>.cpp \
  --build
```

Run:

```sh
./obj_dir/V<top_module>
```

With waveform:

```sh
verilator -Wall -sv --trace --cc <rtl_files> \
  --top-module <top_module> \
  --exe tb_<scenario>.cpp \
  --build
./obj_dir/V<top_module>
```

Open:

```sh
gtkwave dump.vcd
```

## Minimal C++ Harness Pattern

```cpp
#include "V<top_module>.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cassert>

static vluint64_t main_time = 0;

static void tick(V<top_module>* dut, VerilatedVcdC* tfp = nullptr) {
    dut->clk = 0;
    dut->eval();
    if (tfp) tfp->dump(main_time++);
    dut->clk = 1;
    dut->eval();
    if (tfp) tfp->dump(main_time++);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);
    auto* dut = new V<top_module>;

#ifdef VM_TRACE
    Verilated::traceEverOn(true);
    auto* tfp = new VerilatedVcdC;
    dut->trace(tfp, 99);
    tfp->open("dump.vcd");
#else
    VerilatedVcdC* tfp = nullptr;
#endif

    dut->rst_n = 0;
    tick(dut, tfp);
    tick(dut, tfp);
    dut->rst_n = 1;
    tick(dut, tfp);

    // Drive one concrete scenario here.
    // Assert the few timing facts that matter.

#ifdef VM_TRACE
    tfp->close();
    delete tfp;
#endif
    delete dut;
    return 0;
}
```

Replace `<top_module>` before use.

## Scenario Checklists

### Ready/Valid

Check:

- transfer only when `valid && ready`
- payload holds while `valid && !ready`
- output payload holds while `out_valid && !out_ready`
- same-cycle consume/refill
- no data loss or duplication
- reset clears valid state
- flush/abort priority when present

### FIFO

Check:

- empty after reset
- push into empty
- pop to empty
- full boundary
- push blocked when full unless simultaneous pop is allowed
- pop blocked when empty unless simultaneous push behavior is defined
- simultaneous push/pop count update
- pointer wrap
- FIFO ordering

### Arbiter

Check:

- no grant when no request
- one-hot or zero-one-hot grant
- grant stability when protocol requires hold-until-accept
- fixed priority order or round-robin order
- round-robin pointer updates only on accepted grant
- backpressure does not rotate grant early
- fairness over repeated requests

### FSM

Check:

- reset state
- legal transition path
- invalid input hold behavior
- done/ack response timing
- timeout path
- abort/flush priority
- outputs for each state
- no unexpected early completion

## WaveDrom Validation

When validating a WaveDrom scene:

1. identify the scenario file
2. identify the RTL signals drawn
3. build a tiny directed test for that scenario
4. drive the same handshake or event sequence
5. assert the key signal timing
6. optionally compare generated waveform manually

The test should be named after the WaveDrom scenario:

```text
waves/rv_stall_hold.wave.json
sim/tb_rv_stall_hold.cpp
```

## When Verilator Is Not Suitable

Use VCS or Xcelium when the design requires:

- UVM class-based testbench
- unsupported DPI features
- encrypted vendor IP
- vendor primitive libraries
- gate-level netlist with specify/SDF
- simulator-specific system tasks
- company run scripts or full project environment

Still keep the directed-test mindset: one scenario, few signals, precise assertion, waveform only when useful.

VCS sketch:

```sh
vcs -full64 -sverilog -timescale=1ns/1ps \
  +incdir+./rtl \
  <rtl_files> \
  <tb_files> \
  -o simv
./simv
```

Xcelium sketch:

```sh
xrun -64bit -sv \
  -timescale 1ns/1ps \
  +incdir+./rtl \
  <rtl_files> \
  <tb_files>
```

Adjust to repository scripts when available.

## Final Report Format

```markdown
## Check Result

| Item | Result | Note |
|---|---|---|
| Syntax | PASS/FAIL/NOT RUN | ... |
| Lint | PASS/FAIL/NOT RUN | ... |
| Directed scenario | PASS/FAIL/NOT RUN | ... |
| Waveform | generated/not generated | ... |

## Important Findings

1. ...

## Suggested Fix

...
```

If no command actually ran, state clearly:

```text
未实际运行命令；以下是建议命令和预期检查点。
```

Never imply the design passed unless a check actually ran.
