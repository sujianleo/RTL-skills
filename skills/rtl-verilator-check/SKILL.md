---
name: rtl-verilator-check
description: Use this skill to run or propose Verilator-based RTL syntax checks, lint checks, and small directed simulations for synthesizable RTL modules and timing scenarios. Prefer Verilator by default, but allow VCS or Xcelium when the design depends on unsupported simulator-specific behavior.
metadata:
  source: "RTL skill set"
  category: rtl
---

# RTL Verilator Check

Use this skill for RTL syntax checks, lint checks, and small directed simulations.

Default tool: Verilator.

If the repository or design depends on unsupported simulator-specific behavior, macros, encrypted IP, vendor primitives, UVM-only environment, or company simulation flow, use VCS or Xcelium instead when the user asks or the context requires it.

## Reference Guide

This skill reuses the original RTL module design references.

- `../rtl-design/references/module-template.md`: generic module-design checklist and register-derivation template.
- `../rtl-design/references/handshake.md`: skid buffer, register slice, full register slice, pipeline relay, and elastic buffer.
- `../rtl-design/references/fifo.md`: pointer logic, full or empty generation, and simultaneous push or pop.
- `../rtl-design/references/arbiter.md`: fairness policy, grant timing, and backpressure interaction.
- `../rtl-design/references/fsm.md`: state decomposition, transition rules, and output strategy.
- `../rtl-design/references/zero-base-design-note.md`: universal Markdown explanation framework for designing any RTL module from first principles.

If the repository already contains these files under another path, keep the existing path and update links consistently.

## Trigger This Skill When

Use this skill when the user asks for:

- Verilator check
- lint
- syntax check
- compile check
- small directed simulation
- waveform-assisted timing check
- validate WaveDrom against RTL
- test ready/valid stall behavior
- test FIFO boundary behavior
- test FSM transition behavior

Do not use this skill for full UVM regressions.

Do not use this skill as a replacement for project signoff.

## Default Lint Command

For simple SystemVerilog RTL:

```sh
verilator --lint-only --Wall --timing -sv <rtl_files>
```

For pure synthesizable RTL without delays:

```sh
verilator --lint-only --Wall -sv <rtl_files>
```

For include directories:

```sh
verilator --lint-only --Wall -sv \
  +incdir+./rtl \
  +incdir+./include \
  <rtl_files>
```

For defines:

```sh
verilator --lint-only --Wall -sv \
  +define+SIM \
  +define+VERILATOR \
  <rtl_files>
```

## Common Verilator Options

Use only when needed.

- `--lint-only`: lint/syntax only
- `--Wall`: enable common warnings
- `-sv`: enable SystemVerilog parsing
- `--timing`: support timing controls where needed
- `-Wno-fatal`: do not treat warnings as fatal
- `-Wno-DECLFILENAME`: ignore filename/module-name mismatch
- `-Wno-UNUSED`: suppress unused warning when intentional
- `-Wno-WIDTH`: suppress width warning only after review
- `--top-module xxx`: specify top module
- `-I<dir>`: include directory
- `+incdir+<dir>`: include directory
- `+define+NAME`: define macro

Do not suppress warnings blindly.

If suppressing, explain why the warning is harmless or unavoidable.

## Lint Review Priority

When reading Verilator output, prioritize:

1. syntax error
2. missing include or macro
3. multiple drivers
4. inferred latch
5. combinational loop
6. width mismatch
7. uninitialized state
8. unused signal caused by design bug
9. unreachable case or incomplete assignment
10. filename/module-name mismatch

Do not treat all warnings equally.

Width warnings must be reviewed carefully in RTL.

## Directed Simulation Goal

Small directed simulations should support one timing scenario, not broad coverage.

Good test names:

```text
tb_<module>_stall_hold.cpp
tb_<module>_stall_release.cpp
tb_<module>_simul_consume_refill.cpp
tb_<module>_fifo_full_boundary.cpp
tb_<module>_fifo_empty_boundary.cpp
tb_<module>_response_wait.cpp
```

Each test should:

1. reset DUT
2. drive only the needed handshake
3. assert the few signals that could be drawn wrong
4. optionally dump VCD/FST
5. match one WaveDrom scene

Use tests to support the diagram, not replace signal-by-signal RTL reasoning.

## Minimal Verilator Simulation Command

Example C++ harness flow:

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

Open waveform:

```sh
gtkwave dump.vcd
```

## Minimal C++ Testbench Pattern

Use this shape for tiny directed tests.

```cpp
#include "V<top_module>.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
#include <cassert>
#include <cstdint>

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
    V<top_module>* dut = new V<top_module>;

#ifdef VM_TRACE
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
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

    // Drive scenario here.
    // Use assert() for the few timing facts that matter.

#ifdef VM_TRACE
    tfp->close();
    delete tfp;
#endif
    delete dut;
    return 0;
}
```

Replace `<top_module>` before use.

## Ready/Valid Checks

For ready/valid modules, directed tests should check:

1. transfer only when `valid && ready`
2. source payload holds stable while `valid && !ready`
3. output payload holds stable while `out_valid && !out_ready`
4. same-cycle consume/refill behavior
5. no data loss
6. no duplicated data
7. reset clears valid state
8. flush/abort priority if present

Useful assertions in C++:

```cpp
assert(dut->out_valid == 1);
assert(dut->out_data == expected_data);
assert(dut->in_ready == expected_ready);
```

## FIFO Checks

For FIFO modules, directed tests should check:

1. empty after reset
2. push into empty
3. pop to empty
4. full boundary
5. push blocked when full unless simultaneous pop allowed
6. pop blocked when empty unless simultaneous push behavior is defined
7. simultaneous push/pop preserves count correctly
8. pointer wrap
9. first-in-first-out ordering

## Arbiter Checks

For arbiters, directed tests should check:

1. no grant when no request
2. one-hot or zero-one-hot grant
3. grant stability if protocol requires holding until accept
4. priority order for fixed-priority arbiter
5. round-robin pointer update only on accepted grant
6. backpressure does not rotate grant early
7. fairness over repeated requests

## FSM Checks

For FSMs, directed tests should check:

1. reset state
2. legal transition path
3. invalid input hold behavior
4. done/ack response timing
5. timeout path if present
6. abort/flush priority
7. outputs are correct for each state
8. no unexpected early completion

## WaveDrom Validation

When validating a WaveDrom scene:

1. identify the scenario file
2. identify the RTL signals drawn
3. create a tiny directed test for that scenario
4. drive the same handshake
5. assert the key signal timing
6. optionally compare generated waveform manually

The test should be named after the WaveDrom scenario.

Example:

```text
waves/rv_stall_hold.wave.json
sim/tb_rv_stall_hold.cpp
```

## When Verilator Is Not Suitable

Use VCS or Xcelium instead if the design requires:

- UVM class-based testbench
- DPI features unsupported by the local Verilator version
- encrypted vendor IP
- vendor primitive libraries
- gate-level netlist with specify/SDF
- simulator-specific system tasks
- company run scripts
- large project build environment

In those cases, still keep the directed-test mindset: one scenario, few signals, precise assertion/check, waveform only when useful.

## VCS / Xcelium Handoff

When user environment is VCS or Xcelium, provide commands in that style instead of forcing Verilator.

VCS sketch:

```sh
vcs -full64 -sverilog -timescale=1ns/1ps \
  +v2k \
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

After a check, report in this format:

```markdown
## Check Result

| Item | Result | Note |
|---|---|---|
| Syntax | PASS/FAIL | ... |
| Lint | PASS/FAIL | ... |
| Directed scenario | PASS/FAIL/NOT RUN | ... |
| Waveform | generated/not generated | ... |

## Important Findings

1. ...

## Suggested Fix

...
```

If no command was actually run, say clearly:

```text
未实际运行命令；以下是建议命令和预期检查点。
```

Do not imply the design passed unless a check actually ran.
