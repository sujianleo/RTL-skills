---
name: rtl-design
description: Use this skill to write or refactor synthesizable synchronous RTL by deriving behavior first and coding second. Useful for RTL modules, ready/valid or request/response datapaths, FIFOs, arbiters, FSMs, CDC-adjacent control, bus bridges, and pipeline stages.
metadata:
  source: "RTL skill set"
  category: rtl
---

# RTL Module Design

Use this skill to write or refactor synthesizable synchronous RTL.

Core rule: do not start from `if` / `else` syntax. Start from timing behavior, interface contract, and the facts that must survive into later cycles.

## Reference Guide

Keep these references available. Do not remove or rename them.

- `references/module-template.md`: generic module-design checklist and register-derivation template.
- `references/handshake.md`: skid buffer, register slice, full register slice, pipeline relay, and elastic buffer.
- `references/fifo.md`: pointer logic, full or empty generation, and simultaneous push or pop.
- `references/arbiter.md`: fairness policy, grant timing, and backpressure interaction.
- `references/fsm.md`: state decomposition, transition rules, and output strategy.
- `references/zero-base-design-note.md`: universal Markdown explanation framework for designing any RTL module from first principles.

## Code Examples

Use `examples/` only as concrete RTL patterns after the behavior has already been derived from the references.

- `examples/skid.md`, `examples/reg_slice.md`, `examples/vr_stage.md`: valid/ready buffering patterns.
- `examples/cdc_toggle.md`, `examples/toggle_pulse_cdc.md`, `examples/req_ack.md`, `examples/req_ack_4phase.md`: CDC event-transfer patterns.
- `examples/async_fifo.md`: minimal Gray-pointer async FIFO.
- `examples/rst_sync.md`: async assert, sync deassert reset synchronizer.
- `examples/rr_arb.md`: round-robin arbiter.
- `examples/strobe.md`, `examples/strobe_hold_tx.md`: one-way strobe/data patterns.
- `examples/pulse_width_det.md`, `examples/debounce_filter.md`, `examples/nand_tree.md`: small reusable RTL blocks.

## Trigger This Skill When

Use this skill for:

- writing a new RTL module
- refactoring synchronous RTL
- designing ready/valid, req/ack, request/response, or bus bridge logic
- designing FIFO, arbiter, FSM, pipeline stage, register slice, skid buffer, or elastic buffer
- reviewing whether RTL state and datapath behavior are correct
- deriving register update rules from timing scenarios

Do not overuse this skill for:

- one-line syntax fixes
- pure formatting
- pure testbench work
- pure documentation without RTL logic changes

For pure design notes, use `rtl-note`.
For WaveDrom timing diagrams, use `rtl-wavedrom`.
For Verilator lint or small directed checks, use `rtl-check`.

## Output Level

Choose the smallest useful output level.

### Light Mode

Use for small patches, bug fixes, or local refactors.

Deliver:

1. short behavior summary
2. changed RTL only
3. affected registers and set/clear/hold rules
4. key bug prevented

### Standard Mode

Use for normal RTL modules.

Deliver:

1. module job
2. interface contract
3. module principle
4. key timing scenarios
5. cross-cycle facts
6. register list
7. set/clear/hold rules
8. RTL implementation
9. signal-by-signal check

### Full Mode

Use for non-trivial FIFO, arbiter, bus bridge, request/response datapath, CDC-adjacent control, or complex FSM.

Deliver:

1. everything in Standard Mode
2. companion Markdown design note, or clear instruction to use `rtl-note`
3. WaveDrom scenario files, or clear instruction to use `rtl-wavedrom`
4. lint/simulation commands, or clear instruction to use `rtl-check`

Do not generate extra files unless the user asks, the repository convention requires them, or the module is complex enough that the extra file materially helps.

## Core Method

Think like a careful RTL designer.

1. Start from the two sides that may disagree: producer versus consumer, valid versus ready, request versus response, address phase versus data phase, command versus delayed payload, or upstream ownership versus downstream ownership.
2. Name the concrete timing hazard before naming the solution. Example: "write address can arrive before write data", then "therefore a pending bit is needed".
3. Explain each register as memory of one unfinished fact. Good: "`payload_pending` remembers that the command has been accepted but its payload has not arrived yet." Bad: "`payload_pending` is a flag used in the FSM."
4. Use cycle-by-cycle stories for confusing cases: 第 N 拍先占座, 第 N+1 拍回填 payload, 后续某拍 downstream consume 后释放.
5. End each key scenario by stating what bug the structure prevents: wrong payload paired with command, early response completion, stalled payload changing, FIFO boundary corruption, or grant changing before accept.

## Design Template

Use this order unless the user asks otherwise.

1. Module job in one sentence.
2. Interface semantics.
3. Module principle.
4. Key timing scenarios.
5. Cross-cycle facts.
6. State or register list.
7. Set, clear, hold for each register.
8. Datapath priority.
9. Meaningful event wires.
10. RTL implementation.
11. Optional design note.
12. Optional WaveDrom diagrams.
13. Final signal-by-signal RTL check.

## Interface Contract First

Before writing RTL, define the contract.

For ready/valid:

- transfer happens only when `valid && ready`
- source must hold payload stable while `valid && !ready`
- destination may apply backpressure by deasserting `ready`
- payload cannot be recomputed under stall unless explicitly buffered

For req/ack:

- define whether request is level or pulse
- define whether ack is same-cycle, delayed, or pulse
- define whether request must hold until ack
- define whether new request can arrive while old one is pending

For bus-like protocols:

- define address/control phase, data phase, and response phase
- define whether phases can be decoupled
- define whether outstanding transactions are allowed
- define the ordering rule

For CDC-adjacent logic:

- do not cross clock domains with raw ready/valid or raw pulses
- explicitly identify synchronizer, toggle, async FIFO, or handshake boundary
- this skill may design the single-clock side around the CDC boundary, but must not invent unsafe CDC transfer logic

## Module Principle

Before listing scenarios, explain the working principle clearly enough that a reader can sketch the block diagram before seeing RTL.

For non-trivial modules, default to 6-12 lines. The section should answer:

1. What structural idea the module uses.
2. Why that structure solves the timing problem.
3. What tradeoff it introduces.
4. How data or ownership moves through the structure.
5. Which elements are combinational and which are state-holding.
6. Where the boundary conditions are absorbed.

Recommended order:

1. Start from the architectural picture.
2. Explain the main datapath in time order.
3. Explain which state elements remember cross-cycle facts.
4. Explain how edge cases are absorbed.
5. End with the key tradeoff.

Prefer concrete mechanism words: `直通`, `暂存`, `回填`, `仲裁`, `轮转`, `计数`, `占用`, `释放`, `跨拍保留`, `边界吸收`.

Avoid vague words such as: improves performance, handles timing, controls flow, uses FSM, optimizes logic.

## Register Derivation Rule

For each register, state four things:

1. What fact the register records.
2. What event makes that fact become true.
3. What event makes that fact become false.
4. All other cases hold.

If the register meaning cannot be explained in one sentence, the update logic is not ready.

Template:

```text
寄存器: xxx_reg
记录的事实:
- ...
置位条件:
- ...
清除条件:
- ...
保持条件:
- ...
防止的问题:
- ...
```

## Event Wire Rule

Use meaningful event wires.

Good examples:

```systemverilog
assign accept_fire     = in_valid && in_ready;
assign consume_fire    = out_valid && out_ready;
assign push_fire       = push_valid && push_ready;
assign pop_fire        = pop_valid && pop_ready;
assign response_done   = rsp_valid && rsp_ready;
assign payload_capture = payload_valid && payload_ready;
```

Avoid exposing raw boolean expressions everywhere.

Do not name an event wire until the behavior is already clear.

For combinational event wires, distinguish:

- value before the sampling edge
- value after registers update

This matters for diagrams, assertions, and directed tests.

## Datapath Priority

Always define priority when multiple events can happen in one cycle.

Common examples:

- reset
- sync clear / flush / abort
- simultaneous consume and refill
- accept while output is stalled
- FIFO push and pop at boundary
- response done while new request arrives
- timeout versus normal completion

Write the priority in behavior first, then encode it.

Example priority:

```text
reset > sync_clear > consume/refill same cycle > accept only > consume only > hold
```

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

Do not mix functional clear, abort cleanup, phase-exit clear, or context cleanup inside the async reset branch.

This is safer for code review, CDC, DFT, and maintenance.

## Synthesizable RTL Rules

Generated RTL should be synthesizable by default.

Prefer:

- `always_ff` for registers
- `always_comb` for combinational logic
- explicit default assignments in combinational blocks
- no inferred latches
- no multiple drivers
- no combinational loops
- clear FSM default behavior
- clear reset value for all state-holding registers
- stable payload under backpressure
- clear separation of state, event wires, and datapath

Avoid:

- unsized constants in critical logic
- implicit nets
- blocking assignment in sequential logic
- nonblocking assignment in pure combinational logic
- simulation-only delay
- `force` / `release`
- unsafe cross-clock logic
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

For non-obvious timing, include a compact `模块原理` comment section, but do not dump the whole design note into RTL.

Detailed teaching belongs in the companion Markdown note.

## Final RTL Check

Before finishing, perform a final signal-by-signal check.

For each important signal, ask:

1. Is it input, combinational event, or register-backed value?
2. Exactly what code makes it change?
3. Under stall/backpressure, does it hold, clear, or recompute?
4. Under reset/flush/abort, what happens?
5. Is there any combinational loop?
6. Is payload stable while protocol requires it?
7. Can same-cycle consume/refill corrupt ordering?
8. Are full/empty or boundary conditions correct?
9. Are all state elements reset or intentionally unreset?
10. Is the code synthesizable?

## When to Call Other Skills

Use `rtl-note` when the user asks for:

- companion `.md`
- zero-base explanation
- design derivation document
- review-friendly design note

Use `rtl-wavedrom` when the user asks for:

- WaveDrom
- timing diagram
- cycle N / N+1 explanation
- alignment, stall, response wait, simultaneous push/pop visualization

Use `rtl-check` when the user asks for:

- lint
- syntax check
- Verilator command
- small directed simulation
- waveform-assisted timing validation
