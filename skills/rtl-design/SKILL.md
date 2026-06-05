---
name: rtl-design
description: Use this skill to write or refactor synthesizable synchronous RTL by deriving behavior first and coding second. The core method is to turn input events into remembered facts, prioritize updates, and drive outputs according to an explicit interface contract.
metadata:
  source: "RTL skill set"
  category: rtl
---
# RTL Module Design
Use this skill to design or refactor synthesizable synchronous RTL.
Core idea:
```text
RTL design = input events -> remembered facts -> prioritized update -> output behavior
```

Do not start from if / else.

Start from:

1. external contract
2. input events
3. facts that must survive across cycles
4. set / clear / hold rules
5. same-cycle priority
6. output mapping

## 1. RTL Design Essence

| Core | Essential Question | RTL Form |
|---|---|---|
| Fact | Does this information need to survive across cycles? | register / flag / counter / state |
| Event | What makes a fact become true or false? | fire / pulse / done / timeout |
| Priority | If multiple events happen in one cycle, who wins? | if-else priority |
| Boundary | What happens when input is late, output is blocked, abort/reset occurs? | pending / buffer / clear |
| Contract | How does this module hand off responsibility to external logic? | valid-ready / req-done / level-pulse |

## 2. Design Flow

For any RTL module, derive behavior in this order.

### Step 1: Module job

This module receives `<input/events>`, remembers `<cross-cycle facts>`, and drives `<output/actions>`.

### Step 2: Interface contract

For every important input/output, define:

input:
- pulse or level?
- same clock domain or CDC-synchronized?
- can it arrive while FSM is busy?
- does it need to be remembered?

output:
- pulse or level?
- who consumes it?
- does it hold until done?
- what external done/ack clears it?

### Step 3: Timing hazards

Name the concrete problem before naming the solution.

Good:

```text
wake pulse can arrive while the FSM is busy.
Therefore a pending bit is needed.
```

Bad:

```text
add a pending flag.
```

### Step 4: Cross-cycle facts

For each possible fact, ask:

```text
Does this fact need to be remembered after this clock edge?
```

If yes, create a register.

Examples:

```text
pending_wake:
  remembers that a wake pulse arrived while FSM was busy and has not been consumed.

done_seen:
  remembers that one side completed while the other side has not.

target_state:
  remembers which state this flow is entering.

source_dir:
  remembers which RX side triggered this flow.
```

### Step 5: Register set / clear / hold

For every register, write:

```text
Register:
- <name>
Remembered fact:
- what unfinished fact this register stores
Set condition:
- what event makes the fact true
Clear condition:
- what event consumes, invalidates, or aborts the fact
Hold condition:
- all other cases
Bug prevented:
- lost pulse / stale event / wrong direction / early done / duplicated action
```

### Step 6: Same-cycle priority

Before coding, write priority explicitly.

Common pattern:

```text
reset > abort/clear > consume/done > set new pending > hold
```

or:

```text
reset > timeout/abort > normal completion > new start > hold
```

Then encode RTL with the same priority order.

### Step 7: Output mapping

Outputs should come from one of:

- state phase
- registered fact
- event wire
- external contract

Example:

```systemverilog
assign tx_req_o = (state_q == S_SEND) && active_dir_q;
assign done_o   = (state_q == S_DONE);
assign busy_o   = (state_q != S_IDLE);
```

## 3. Event Wire Rule

Use meaningful event wires.

```systemverilog
assign accept_fire  = in_valid && in_ready;
assign consume_fire = out_valid && out_ready;
assign done_fire    = done_pulse_i;
assign start_fire   = idle && req_i;
assign timeout_fire = cnt_q >= TIMEOUT_LIMIT;
```

Avoid scattering raw expressions everywhere.

For event wires, distinguish:

- value before the clock edge
- value after registers update

## 4. Boundary Rule

For every module boundary, ask:

- What if input arrives early?
- What if input arrives while busy?
- What if output side is not ready?
- What if done pulses are skewed?
- What if abort happens in the same cycle as done?
- What if timeout and done happen together?

Typical RTL structures:

| Boundary Problem | RTL Structure |
|---|---|
| input arrives while busy | pending bit |
| done pulses are skewed | done_seen latch |
| output side is blocked | valid/data hold |
| abort/reset occurs | clear context |
| payload arrives later | payload buffer |
| state decision needed later | target/state register |

## 5. Reset Rule

For async-reset sequential logic, keep async reset dedicated to reset only.

Good:

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    state_q <= IDLE;
  end else if (sync_clear) begin
    state_q <= IDLE;
  end else begin
    state_q <= state_d;
  end
end
```

Do not mix functional clear, abort cleanup, phase-exit clear, or context cleanup inside the async reset branch.

## 6. RTL Coding Rules

Generated RTL should be synthesizable by default.

Prefer:

- `always_ff` for registers
- `always_comb` for combinational logic
- explicit default assignments
- no inferred latches
- no multiple drivers
- no combinational loops
- clear reset values for state-holding registers
- clear separation of state, event wires, and datapath

Avoid:

- unsized constants in critical logic
- implicit nets
- blocking assignment in sequential logic
- nonblocking assignment in pure combinational logic
- simulation-only delays
- unsafe CDC transfer logic
- over-designed FSMs for simple datapaths

## 7. Comments

Use Chinese comments by default.

Keep comments close to timing intent.

Good:

```text
// out_valid=1 且 out_ready=0 时，下游还没有接走数据，payload 必须保持不变。
```

Bad:

```text
// if valid and not ready then hold data
```

Detailed teaching belongs in a design note, not inside RTL.

## 8. Output Level

Choose the smallest useful output.

### Light Mode

Use for small fixes or local refactors.

Deliver:

1. behavior summary
2. changed RTL only
3. affected registers and set / clear / hold rules
4. key bug prevented

### Standard Mode

Use for normal RTL modules.

Deliver:

1. module job
2. interface contract
3. timing hazards
4. cross-cycle facts
5. register list
6. set / clear / hold rules
7. priority rules
8. output mapping
9. RTL code
10. signal-by-signal check

### Full Mode

Use for complex FSM, FIFO, arbiter, bus bridge, request/response datapath, CDC-adjacent control, or non-trivial pipeline.

Deliver Standard Mode plus design note, timing diagrams, or lint/simulation guidance when they materially help.

## 9. Final Signal Check

For each important signal, ask:

1. Is it input, event wire, register, or output?
2. What fact does it represent?
3. What event sets it?
4. What event clears it?
5. What happens under abort/reset?
6. What happens if set and clear happen in the same cycle?
7. Does the output match the external contract?
8. Can a stale fact survive too long?
9. Can a pulse be lost while FSM is busy?
10. Is the code synthesizable?

## 10. Final Principle

A register is not just a flag.

A register is:

```text
memory of an unfinished fact
```

If the remembered fact cannot be written in one sentence, the RTL is not ready.
