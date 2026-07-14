---
name: rtl-design
description: Design, debug, review, or refactor non-trivial synthesizable SystemVerilog RTL involving cycle timing, FSMs, ready/valid or req/ack handshakes, CDC/RDC, FIFOs, CSR/IRQ, counters, pipelines, or protocol control. Use for behavior and architecture work; do not use for formatting-only edits, trivial one-line datapath expressions, or testbench-only requests.
---

# RTL Design

## Authority and Scope

Obey the current user request and the repository's `AGENTS.md`, coding guide,
public interface, and verification flow before this skill. Treat this skill as
the default only where project rules are silent.

Preserve user changes and the current RTL baseline. Do not rename public ports,
change reset style, alter latency, or change protocol behavior during a
refactor unless the user authorizes that change. Keep edits within the named
module and supporting tests.

## Core Principle

```text
Less is more.
Think from the timing contract before coding.
Use the smallest structure that exposes the real hardware behavior clearly.
```

Translate the timing contract into current-cycle events, remembered facts,
explicit update priority, and observable outputs.

Trace important behavior in both directions:

```text
input condition
  -> qualified current-cycle event
  -> remembered fact or state
  -> registered update with explicit priority
  -> observable level, pulse, status, or protocol action

observable output
  <- output origin
  <- remembered fact or state
  <- set / clear / hold rule
  <- current-cycle event
  <- input condition
```

Do not add state, abstraction, aliases, or comments unless they reveal a real
timing boundary, owner, priority, CDC boundary, or waveform checkpoint.

## Reference Routing

Read only the references required by the task, but read each selected file
completely before editing RTL:

- Read [naming.md](references/naming.md) before naming or renaming ports,
  internal facts, FSM state, events, CSR/IRQ, `cfg_`, or `dbg_` signals.
- Read [event-structure.md](references/event-structure.md) for many input
  events, event structs, event-owned register groups, long combinational logic,
  FSM layout, or source-order refactors.
- Read [control-correctness.md](references/control-correctness.md) for
  ready/valid, req/ack, pipelines, combinational completeness, arithmetic
  widths, counters, clock enables, or parameterized control logic.
- Read [cdc-fifo-rdc.md](references/cdc-fifo-rdc.md) for any CDC, RDC,
  synchronizer, async FIFO, pulse crossing, or cross-domain payload.
- Read [csr-reset-direction.md](references/csr-reset-direction.md) for CSR,
  status, IRQ, sticky bits, functional clear, reset behavior, or physical versus
  logical direction mapping.

## Design Workflow

Before coding, define:

1. **Job** — what the module receives, remembers, and drives.
2. **Contract** — pulse/level meaning, owner, valid cycle, clock/reset domain,
   clear behavior, latency, and observable effect.
3. **Timing** — acceptance edge, context capture, first/last counter cycle,
   completion cycle, and simultaneous-event priority.
4. **Events** — meaningful current-cycle facts such as `accept_fire`, done,
   timeout, abort, clear, and consume.
5. **Remembered facts** — only information that must survive an edge: state,
   pending, seen, saved context, sticky status, or active transaction.
6. **Priority** — reset, disable/abort/clear, completion/consume, new event,
   and hold, adjusted to the actual contract.
7. **Outputs** — the exact event, register, state, counter, or encoding that
   owns every observable signal.
8. **Corners** — busy, stall, timeout, abort, disable, simultaneous set/clear,
   reset release, skewed inputs, duplicate events, and counter boundaries.

When a cycle boundary is uncertain, draw a mental waveform, cycle table, or
small WaveDrom before coding. Resolve whether each output is same-cycle
combinational, registered, sustained, or a one-cycle pulse.

## Source Order and Single-Pass Reading

Arrange non-trivial RTL so the reader can follow the hardware story without
jumping backward:

```text
static tables / local helper functions
  -> input context capture
  -> input qualification / current-cycle events
  -> register updates and FSM
  -> output origin / encoding / boundary
```

Capture payload and the mode/configuration facts that qualify it at the same
pipeline boundary. Do not combine delayed payload with current-cycle mode
inputs.

Keep each registered output with the event-owned `always_ff` block that updates
it. Put the `// Outputs` section last to show observable origin and
combinational encoding. Put a standalone output pipeline last only when that
pipeline itself owns the output boundary and has no hidden priority dependency
on an earlier register group.

Use one short `// Flow:` comment only when it materially clarifies a large
module. Use short section labels such as:

```systemverilog
// Input events
// Register updates
// FSM
// Outputs
```

## Naming Core

Use the shortest semantic name that remains unambiguous. Public/project-defined
names always win over this default.

- Use `c_st/n_st` for one FSM and `<scope>_c_st/<scope>_n_st` for multiple
  FSMs. Do not use `c_<scope>_st`, `n_<scope>_st`, or `state_q/state_d`.
- Reserve `_q/_q2` for CDC synchronizer stage order; do not add `_q` to
  ordinary registers.
- Use `_nxt` for a simple candidate next value, not FSM state.
- Use `_fire` for a meaningful qualified current-cycle event.
- Use `_pending` only for a captured unconsumed event.
- Prefer `_vld`, `_rdy`, `_err`, `_req`, `_ack`, `_lvl`, `_pls`, and `_sty`.
- Prefer `clr`, `en`, and `grp` in internally owned names.
- Use `cfg_` for configuration and `dbg_` for debug/observability interfaces.
- Avoid `_prev`, `reg_`, `r_`, `wire_`, `w_`, and stacked suffixes unless the
  contract truly needs them.
- Determine IRQ pulse, pending, sticky, or level behavior from the interface
  contract. Use `*_irq_pls`, `*_irq_pending`, or `*_irq_sty` only after that
  behavior is known; never choose pulse behavior from naming preference alone.

Read [naming.md](references/naming.md) for the complete naming contract.

## Events and Combinational Logic

Name a current-cycle event when it drives multiple fact groups or makes the
timing contract clearer. Do not repeat one complex raw condition across state,
counter, output, CSR, and IRQ logic.

Stage a large event chain in causal order. Keep a small obvious expression
direct. Split long logic only when the named intermediate is independently
meaningful in a waveform, such as selected terminal count, elapsed condition,
received condition, owner, or completion. Keep fixed mathematical transforms
and lookup logic compact when individual terms have no independent timing
meaning, such as LFSR, CRC, or constant decode equations.

In every `always_comb`, assign every written signal on every path. Set defaults
before conditional overrides. Use `always_latch` only when a latch is an
intentional part of the contract.

Keep a simple single-meaning continuous assignment on one line. Align short
related declaration and assignment groups by name and `=`/`<=`; do not pad or
flatten a multi-stage expression merely for visual columns.

## Register Updates

Group registers by owning event, lifetime, clear behavior, and same-cycle
priority. One `always_ff` should answer one coherent question; do not make one
block per register or one giant block for unrelated facts.

Place one short comment before each non-obvious event-owned sequential block
stating what facts it updates. Do not comment every assignment.

Keep the FSM current-state `always_ff` and next-state `always_comb` separate but
adjacent under one `// FSM` label. Put the state register first. Do not insert
unrelated counters, synchronizers, or outputs between the pair.

Do not create a history register only to manufacture an edge event when a
level condition in the owning FSM state already expresses the event.

## Priority and Outputs

Name shared cleanup conditions once and reuse them consistently. Treat the
following as a starting point, not a universal rule:

```text
reset
  > disable / abort / clear / kill
  > consume / complete
  > set new event
  > hold
```

Define set-versus-clear dominance explicitly for every pending or sticky fact;
use set-dominant behavior when losing a new event would violate the contract.

For every output, identify its owner and timing class: current event,
registered fact, state, counter, combinational encoding, pending/sticky status,
or pipeline boundary. Never hide a state transition or unrelated update inside
output encoding.

## Generated RTL Boundaries

Keep synthesizable module RTL compact. Do not add `SYNTHESIS` guards,
`initial $fatal`, assertions, or other simulation-only logic inside the design
unless the user asks for verification logic. Put test-only checks in the
testbench or formal harness.

Do not gate a clock with ordinary combinational RTL. Use a clock enable or a
project-approved integrated clock-gating cell and follow its test-enable and
CDC requirements.

## Verification

For generated or changed RTL:

1. Run the repository's syntax check and lint, or the closest available
   equivalent.
2. Run the targeted directed testbench for the changed behavior.
3. Run the relevant active regression when behavior changes; report anything
   not run and why.
4. For a refactor intended to preserve behavior, compare against the baseline
   with a miter, formal equivalence, or cycle-by-cycle reference test when
   practical. Check payload, qualifiers, status, and latency.
5. Do not relax assertions, narrow stimulus, or remove edge cases merely to
   make the RTL pass.

For review-only work, report findings and verification gaps without modifying
RTL unless the user asks for a fix.

## Final Check

Before finishing, confirm:

1. Project rules and public interfaces were preserved.
2. Every output traces back to a defined event/fact and exact cycle.
3. Event, register lifetime, and same-cycle priority are explicit.
4. Handshake, CDC/RDC, reset, width, and counter boundaries are safe.
5. Source order reads input/context -> events -> updates -> output origin.
6. Complex logic is split only at meaningful waveform checkpoints.
7. Busy, stall, timeout, abort, clear, disable, and simultaneous events were
   considered.
8. Required syntax, lint, directed tests, equivalence checks, and regression
   were run or explicitly reported as not run.
