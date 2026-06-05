---
name: rtl-design
description: Use this skill to write or refactor synthesizable synchronous RTL by deriving behavior first and coding second. Useful for RTL modules, ready/valid or request/response datapaths, FIFOs, arbiters, FSMs, CDC-adjacent control, bus bridges, and pipeline stages.
metadata:
  source: "RTL skill set"
  category: rtl
---

# RTL Module Design

Use this skill to design or refactor synthesizable synchronous RTL.

Core rule: do not start from `if` / `else` syntax. Start from the module contract, timing hazards, and the cross-cycle facts that must be remembered by registers.

## When To Use

Use this skill for:

- writing or refactoring synthesizable RTL modules
- deriving FSMs, counters, pending bits, buffers, arbiters, FIFOs, and pipeline stages
- designing ready/valid, req/ack, request/response, bus-like, or CDC-adjacent control logic
- reviewing whether RTL state, datapath, and update priority are correct

Do not use this skill for pure formatting, one-line syntax fixes, pure testbench work, or standalone documentation without RTL logic changes.

For design notes use `rtl-note`. For WaveDrom diagrams use `rtl-wavedrom`. For lint or small directed checks use `rtl-check`.

## Reference Guide

Keep these references available. Do not remove or rename them.

- `references/module-template.md`: generic module-design checklist and register-derivation template.
- `references/handshake.md`: skid buffer, register slice, full register slice, pipeline relay, and elastic buffer.
- `references/fifo.md`: pointer logic, full or empty generation, and simultaneous push or pop.
- `references/arbiter.md`: fairness policy, grant timing, and backpressure interaction.
- `references/fsm.md`: state decomposition, transition rules, and output strategy.
- `references/zero-base-design-note.md`: universal Markdown explanation framework for designing RTL from first principles.

Use `examples/` only after the behavior has already been derived.

## Output Level

Choose the smallest useful output.

### Light Mode

Use for small patches or local refactors.

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
7. datapath or FSM priority
8. RTL implementation
9. final signal check

### Full Mode

Use for non-trivial FIFO, arbiter, bus bridge, request/response datapath, CDC-adjacent control, or complex FSM.

Deliver Standard Mode plus a companion design note, WaveDrom scenarios, or lint/simulation guidance when they materially help.

## Design Flow

Use this order unless the user asks otherwise.

1. State the module job in one sentence.
2. Define the interface contract.
3. Name the timing hazards before naming the solution.
4. Identify cross-cycle facts.
5. Derive registers from those facts.
6. Write set / clear / hold rules for each register.
7. Define same-cycle priority.
8. Name meaningful event wires.
9. Implement synthesizable RTL.
10. Perform signal-by-signal checks.

## Interface Contract

Before writing RTL, define how the module communicates with its neighbors.

For ready/valid:

- transfer happens only when `valid && ready`
- source holds payload stable while `valid && !ready`
- destination may deassert `ready` for backpressure
- payload cannot be recomputed under stall unless explicitly buffered

For req/ack:

- define whether request is level or pulse
- define whether ack is same-cycle, delayed, or pulse
- define whether request holds until ack
- define whether a new request can arrive while the old one is pending

For bus-like protocols:

- define address/control phase, data phase, and response phase
- define whether phases can be decoupled
- define whether outstanding transactions are allowed
- define ordering rules

For CDC-adjacent logic:

- do not cross clock domains with raw ready/valid or raw pulses
- identify the synchronizer, toggle, async FIFO, or handshake boundary
- design only the single-clock side unless a safe CDC mechanism is specified

## Core Method

Think like a careful RTL designer:

1. Start from two sides that may disagree: producer versus consumer, valid versus ready, request versus response, command versus delayed payload, or upstream ownership versus downstream ownership.
2. Name the concrete timing hazard: for example, `wake pulse can arrive while FSM is busy`.
3. Explain each register as memory of one unfinished fact. Good: `pending_wake` remembers that a wake arrived while the FSM was busy and has not been consumed. Bad: `pending_wake` is a flag used by the FSM.
4. Use short cycle stories for confusing cases: cycle N captures the event, later cycle consumes it, then the pending fact clears.
5. End each key scenario with the bug prevented: lost pulse, wrong pairing, early completion, stale pending state, or boundary corruption.

## Register Derivation Rule

For every state-holding register, state four things:

```text
Register:
- name

Remembered fact:
- what unfinished fact this register stores

Set condition:
- what event makes the fact true

Clear condition:
- what event makes the fact false or obsolete

Hold condition:
- all other cases

Bug prevented:
- what goes wrong without this register
```

If the register meaning cannot be explained in one sentence, the update logic is not ready.

## Event Wire Rule

Use meaningful event wires instead of repeating raw expressions.

Good examples:

```systemverilog
assign accept_fire   = in_valid && in_ready;
assign consume_fire  = out_valid && out_ready;
assign push_fire     = push_valid && push_ready;
assign pop_fire      = pop_valid && pop_ready;
assign response_done = rsp_valid && rsp_ready;
```

For combinational event wires, distinguish the value before the sampling edge from the value after registers update. This matters for timing diagrams, assertions, and directed tests.

## Priority Rule

Always define same-cycle priority before coding.

Common priorities:

```text
reset > sync_clear / abort > consume/refill same cycle > accept only > consume only > hold
```

Examples that require explicit priority:

- abort versus normal completion
- timeout versus done
- simultaneous consume and refill
- push and pop at FIFO boundary
- response done while a new request arrives
- pending event set and clear in the same cycle

## Reset Rule

For async-reset sequential logic, keep async reset dedicated to reset only.

Good style:

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

Do not mix functional clear, abort cleanup, phase-exit clear, or context cleanup inside the async reset branch. This is safer for review, CDC, DFT, and maintenance.

## RTL Coding Rules

Generated RTL should be synthesizable by default.

Prefer:

- `always_ff` for registers
- `always_comb` for combinational logic
- explicit defaults in combinational blocks
- no inferred latches
- no multiple drivers
- no combinational loops
- reset values for all state-holding registers unless intentionally unreset
- clear separation of state, event wires, and datapath

Avoid:

- unsized constants in critical logic
- implicit nets
- blocking assignment in sequential logic
- nonblocking assignment in pure combinational logic
- simulation-only delays
- `force` / `release`
- unsafe CDC transfer logic
- over-designed FSMs for simple datapaths

## Comments

Use Chinese comments by default.

Keep RTL comments close to timing intent, not syntax narration.

Good:

```systemverilog
// out_valid=1 且 out_ready=0 时，下游还没有接走数据，payload 必须保持不变。
```

Bad:

```systemverilog
// if valid and not ready then hold data
```

Detailed teaching belongs in the companion Markdown note, not inside RTL.

## Final Signal Check

Before finishing, check each important signal:

1. Is it input, combinational event, or register-backed value?
2. Exactly what code makes it change?
3. Under stall, does it hold, clear, or recompute?
4. Under reset, flush, or abort, what happens?
5. Can same-cycle set and clear both happen? If so, who wins?
6. Is payload stable while the protocol requires it?
7. Can simultaneous consume/refill corrupt ordering?
8. Are full, empty, timeout, or boundary conditions correct?
9. Are all state elements reset or intentionally unreset?
10. Is the code synthesizable?
