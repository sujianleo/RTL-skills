---
name: rtl-check
description: Use this skill to run or propose RTL syntax/lint checks and small directed simulations. The goal is to verify RTL facts, events, priorities, boundaries, and interface contracts, not just run a tool command.
metadata:
  source: "RTL skill set"
  category: rtl
---
# RTL Check

Use this skill to verify RTL behavior with lint, syntax checks, and small directed simulations.

Core idea:

```text
RTL check = scenario -> stimulus -> observed facts/events -> pass/fail conclusion
```

Do not just run a tool.

Use the tool to prove a concrete RTL behavior.

## 1. Check Essence

| Core | Check Question | RTL Evidence |
|---|---|---|
| Fact | Did the register remember the required cross-cycle fact? | register/state value |
| Event | Did fire/pulse/done/timeout happen in the correct cycle? | event wire / pulse |
| Priority | If two events happen in one cycle, who wins? | next state / register update |
| Boundary | Does the design handle late input, busy, stall, abort, reset? | pending/buffer/clear behavior |
| Contract | Does the module obey its external handshake contract? | req/done/valid-ready behavior |

## 2. When To Use

Use this skill when the user asks for:

- Verilator check
- lint / syntax / compile check
- small directed simulation
- waveform-assisted timing check
- validation of a WaveDrom scenario
- ready/valid, FIFO, arbiter, FSM, timeout, abort, or pending behavior check

Do not use this skill for full UVM regressions or signoff.

## 3. Check Flow

Use this order:

1. Identify module and files.
2. Identify clock/reset, include dirs, defines, and top module.
3. State the contract being checked.
4. Pick one concrete scenario.
5. Name the bug this scenario prevents.
6. List observed signals.
7. Run or propose lint/sim command.
8. Report only what actually ran.

## 4. Scenario Template

```text
Scenario:
- ...
Bug prevented:
- ...
Stimulus:
- cycle N:
- cycle N+1:
- cycle N+2:
Expected behavior:
- event:
- register:
- output:
Pass condition:
- ...
```

## 5. Default Lint Command

Simple SystemVerilog RTL:

```sh
verilator --lint-only --Wall -sv <rtl_files>
```

With timing controls:

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

- `--top-module <name>`
- `-Wno-fatal`
- `-Wno-DECLFILENAME`
- `-Wno-UNUSED`
- `-Wno-WIDTH`

Do not suppress warnings blindly. Explain why each suppression is safe.

## 6. Lint Priority

Prioritize:

1. syntax error
2. missing include or macro
3. multiple drivers
4. inferred latch
5. combinational loop
6. width mismatch
7. uninitialized state
8. unused signal caused by design bug
9. incomplete assignment
10. unreachable branch

Width warnings must be reviewed, not blindly ignored.

## 7. Directed Simulation Principle

One test should prove one timing story.

Good scenarios:

- `pending_event_while_busy`
- `skewed_done_latch`
- `abort_vs_done_priority`
- `timeout_vs_done_priority`
- `stall_hold_payload`
- `simultaneous_consume_refill`
- `fifo_full_boundary`
- `fifo_empty_boundary`

Each test should:

1. reset DUT
2. drive only the required inputs
3. assert the few signals that prove the behavior
4. optionally dump waveform
5. map to one WaveDrom scenario if available

Bad checks:

- one huge random test
- waveform with no assertion
- lint only while claiming function is correct

## 8. Minimal Verilator Simulation

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

Open waveform:

```sh
gtkwave dump.vcd
```

## 9. Minimal C++ Testbench Shape

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

## 10. Five-Essence Checklists

### Fact Check

Ask:

- What fact should this register remember?
- When does it set?
- When does it clear?
- Can it stay stale?
- Can it be lost?

### Event Check

Ask:

- Is this event pulse or level?
- Can it arrive while busy?
- Can two events arrive in the same cycle?
- Is the event sampled before or after state update?

### Priority Check

Ask:

- If abort and done happen together, who wins?
- If timeout and done happen together, who wins?
- If set and clear happen together, who wins?
- Does RTL if/else encode the same priority?

### Boundary Check

Ask:

- What if input arrives late?
- What if input arrives while busy?
- What if external done pulses are skewed?
- What if output side stalls?
- What if reset/abort happens in the middle?

### Contract Check

Ask:

- Is req pulse or level?
- Is done pulse or level?
- Does req hold until done?
- Can new req arrive before old done?
- Who owns clearing the transaction?

## 11. Common Scenario Checks

### Ready/Valid

Check:

- transfer only when `valid && ready`
- payload holds while `valid && !ready`
- output payload holds while `out_valid && !out_ready`
- same-cycle consume/refill
- no data loss or duplication
- reset clears valid state
- flush/abort priority

### FIFO

Check:

- empty after reset
- push into empty
- pop to empty
- full boundary
- push blocked when full unless simultaneous pop is allowed
- pop blocked when empty unless simultaneous push is defined
- simultaneous push/pop count update
- pointer wrap
- FIFO ordering

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

### Pending / Done-Seen Logic

Check:

- input pulse while busy sets pending
- pending clears when consumed
- pending clears when context becomes invalid
- same-cycle set/clear priority is intentional
- skewed done pulse is latched until all required sides complete

## 12. When Verilator Is Not Suitable

Use VCS or Xcelium when the design requires:

- UVM class-based testbench
- encrypted vendor IP
- vendor primitive libraries
- gate-level netlist with specify/SDF
- simulator-specific system tasks
- company run scripts or full project environment

Still keep the directed-test mindset:

```text
one scenario
few signals
precise assertion
waveform only when useful
```

## 13. Final Report Format

```markdown
## Check Result

| Item | Result | Evidence |
|---|---|---|
| Syntax | PASS/FAIL/NOT RUN | command/output |
| Lint | PASS/FAIL/NOT RUN | command/output |
| Scenario | PASS/FAIL/NOT RUN | checked signals |
| Waveform | generated/not generated | file |

## Important Findings

1. ...

## Suggested Fix

...
```

If no command actually ran, say:

```text
未实际运行命令；以下是建议命令和预期检查点。
```

Never imply the design passed unless a check actually ran.

## 14. Final Principle

The soul of `rtl-check` is not Verilator.

It is using the smallest scenario to prove that a specific fact, event, priority, boundary, or contract is really implemented.
