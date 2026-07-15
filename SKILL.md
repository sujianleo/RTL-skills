---
name: rtl-design
description: Design, debug, review, or refactor non-trivial synthesizable SystemVerilog RTL involving cycle timing, FSMs, ready/valid or req/ack handshakes, CDC/RDC, FIFOs, CSR/IRQ, counters, pipelines, protocol control, functional-block decomposition, or reusable component selection. Use for behavior and architecture work; do not use for formatting-only edits, trivial one-line datapath expressions, or testbench-only requests.
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
- Read [decomposition-components.md](references/decomposition-components.md)
  before splitting a large requirement into clear functional blocks or
  selecting, creating, or reusing standard counters, edge detectors, digital
  filters, pulse helpers, arbiters, buffers, or other control structures.
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
2. **Decomposition** — smaller timing contracts and clear standard functional
   blocks that can own them without changing latency or priority. Keep these
   blocks in the same module by default; decide on submodule extraction later.
3. **Contract** — pulse/level meaning, owner, valid cycle, clock/reset domain,
   clear behavior, latency, and observable effect.
4. **Timing** — acceptance edge, context capture, first/last counter cycle,
   completion cycle, and simultaneous-event priority.
5. **Events** — meaningful current-cycle facts such as `accept_fire`, done,
   timeout, abort, clear, and consume.
6. **Remembered facts** — only information that must survive an edge: state,
   pending, seen, saved context, sticky status, or active transaction.
7. **Priority** — reset, disable/abort/clear, completion/consume, new event,
   and hold, adjusted to the actual contract.
8. **Outputs** — the exact event, register, state, counter, or encoding that
   owns every observable signal.
9. **Corners** — busy, stall, timeout, abort, disable, simultaneous set/clear,
   reset release, skewed inputs, duplicate events, and counter boundaries.

When a cycle boundary is uncertain, draw a mental waveform, cycle table, or
small WaveDrom before coding. Resolve whether each output is same-cycle
combinational, registered, sustained, or a one-cycle pulse.

## Problem Decomposition and Standard Functional Blocks

Break a large requirement into smaller problems with independent, testable
timing contracts. A "standard component" normally means a recognizable local
hardware block—counter, timer, edge detector, filter, arbiter, buffer, or
protocol phase—not automatically a separate SystemVerilog module. Define each
block's inputs, outputs, owner, latency, clock/reset domain, configuration,
clear behavior, and failure behavior before considering a module boundary.

Implement clear functional blocks inside the owning module by default. Give
each block a short purpose comment, meaningful events/facts, and a coherent
`always_ff`, `always_comb`, helper function, or small assignment group. The
reader should be able to see what the block does and how it connects to the
next block without crossing file boundaries.

Search the repository for an approved component before writing new logic.
Prefer proven counters/timers, edge detectors, digital filters or deglitchers,
synchronizers, pulse synchronizers/stretchers, FIFOs, skid/elastic buffers, and
arbiters when their contracts match the requirement. Reusing an existing
approved module is a separate decision from decomposing the behavior into
functional blocks.

Do not default to creating submodules. Keep a local counter, edge detector,
filter, decoder, or protocol-phase block inline when its state and priority
belong to the parent module. Extract a submodule only when the user or project
requires it, an approved reusable implementation already exists, or there is a
real reuse, independent-interface, CDC/IP, or verification boundary that
outweighs the added wiring and file navigation.

Never let component reuse silently change cycle latency, reset behavior,
same-cycle priority, saturation/wrap behavior, or CDC safety. Synchronize an
asynchronous input before synchronous edge detection. Define a digital filter's
sample rate, qualification rule, threshold, assertion/deassertion latency, and
glitch model.

Read [decomposition-components.md](references/decomposition-components.md) for
the decomposition method and standard-component contracts.

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

Let the numbered section titles express a readable source flow. Do not
add a redundant `// Main Flow:` summary when those titles already show the
order. Add a short flow summary only for a genuinely non-linear or branching
module that the numbered sections cannot explain. Collect internal signal
declarations, static constants, types, helper functions, and reference tables
in a `0. Helper` prelude before the runtime stages. Keep a very small module
without internal declarations or utilities free of an empty Helper section.

Number the helper prelude as stage 0 and the primary runtime sections from stage
1 in source order. Use title case, name both the action and its object, and
avoid vague standalone labels such as `Process`, `Update`, or `Events`. For a
compact control/datapath module, prefer the following structure when it
accurately describes the hardware:

```systemverilog
//! 0. Helper
//! ---------

// Internal signals, constants, types, helper functions, and reference tables

//! 1. Input Decode
//! ---------------

// Input capture, filtering, qualification, and event derivation

//! 2. Register Update
//! ------------------

//! 3. Output Generation
//! --------------------
```

Adapt the stage names or count when the real timing flow requires it; never
force behavior into an inaccurate section merely to keep four stages. Use `//!`
for both title and divider, and make the divider reach at least the end of the
complete title line. Do not promote every local register group, counter, helper,
or small decode into another numbered partition; use a normal single-line `//`
purpose comment for those local groups.
Keep all module-scope internal signal declarations in `0. Helper`; do not leave
late declarations inside Input Decode, Register Update, or Output Generation.
After editing, audit that numbered sections are continuous, ordered, unique,
and non-empty. A module using the complete standard flow must contain exactly
stages 0 through 3 with no skipped or duplicated number.
Treat `Input Decode` as the complete input-side causal stage: capture or filter
raw inputs when needed, then qualify them step by step into reusable
current-cycle events and datapath candidates. Keep the derivation in dependency
order. Only minimal input-boundary capture or filter registers belong here;
place functional state, remembered flow context, counters, sticky facts, and
output registers in `Register Update`.
When `Input Decode` contains several causal steps, divide it with short normal
`//` group comments such as input filtering, effective context, start events,
timing terminals, completion events, and clear events. Keep each group in
dependency order and do not create more numbered flow sections for these local
steps. Skip a group comment when the entire decode remains obvious as one small
assignment group.
Keep the two `//!` header lines adjacent, then leave exactly one blank line
after the divider before the section's local comment, declaration, or logic.
Use blank lines between primary flow stages and independent local blocks. One
blank line may separate a coherent declaration group from the assignments or
`always_*` block that implements it, so the transition from named signals to
logic remains visible. Do not use multiple blank lines or insert blank lines
inside one declaration group or one related assignment group.

Place one short English purpose comment immediately above every helper
`function`. State the transform, validation, classification, or lookup the
function provides; do not merely repeat its name or narrate its equations.

## Naming Core

Use the shortest semantic name that remains unambiguous. Public/project-defined
names always win over this default.

- For new ordinary module ports, put direction first: `i_<meaning>` for inputs
  and `o_<meaning>` for outputs, such as `i_pclk`, `i_data_vld`, `o_data_rdy`,
  and `o_done_pls`. Do not use trailing `*_i`/`*_o` or mix both styles on new
  ordinary ports. Preserve an existing public/project interface when it already
  mandates a different convention.
- Use `c_st/n_st` for one FSM and `<scope>_c_st/<scope>_n_st` for multiple
  FSMs. Do not use `c_<scope>_st`, `n_<scope>_st`, or `state_q/state_d`.
- Reserve `_q/_q2` for CDC synchronizer stage order; do not add `_q` to
  ordinary registers.
- Use `_nxt` for a simple candidate next value, not FSM state.
- Use `_fire` for a meaningful qualified current-cycle event.
- Use `_pending` only for a captured unconsumed event.
- Prefer `_vld`, `_rdy`, `_err`, `_req`, `_ack`, `_lvl`, `_pls`, and `_sty`.
- Prefer `clr`, `en`, and `grp` in internally owned names.
- `cfg_` and `dbg_` are leading-prefix exceptions: use `cfg_en`, `cfg_mode`,
  `dbg_force`, and `dbg_state`, without an `i_` or `o_` prefix. Their direction
  remains explicit in the port declaration.
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

Place an English explanation immediately above each non-obvious or complex
combinational block, including a long continuous-assignment group or complex
`always_comb`. Make it detailed enough to identify the input qualification,
causal dependency or priority, and the event, candidate, or next-state result
being produced. Use one concise line when that is sufficient and a few short
lines when the timing or priority would otherwise remain hidden; do not narrate
statements line by line. An obvious comparison, direct connection, short mux,
simple packing expression, or small single-purpose assignment group may pass
without a comment.

During a rule check, keep every short single-meaning combinational expression
on one physical line when it remains clear. Do not split a simple comparison,
single-purpose ternary, packing expression, or short function call only for
formatting. Align related declaration and assignment groups by signal and
`=`/`<=`. Keep a line split only when it exposes a meaningful causal stage or
when one-line form would obscure the expression; do not flatten multi-stage
logic merely for visual columns. Apply this one-line preference to continuous
assignments and simple combinational statements, not to important sequential
priority branches.

## Register Updates

Group registers by owning event, lifetime, clear behavior, and same-cycle
priority. One `always_ff` should answer one coherent question; do not make one
block per register or one giant block for unrelated facts.

Place one short comment before each non-obvious event-owned sequential block
stating what facts it updates. Do not comment every assignment.

Keep reset, disable, abort, clear, completion, new-event, and hold priority
visually expanded in important `always_ff` blocks. Do not compress these
priority branches into one-line `if`/`else` statements merely to reduce lines.

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

### Naming Audit

Before finishing, inspect every public port and internal name, not only newly
added signals. Preserve required public interfaces, then verify direction,
scope, timing meaning, ownership, and lifetime. Check `i_/o_`, `cfg_/dbg_`,
`c_st/n_st`, `_fire`, `_pending`, `_vld/_rdy`, `_lvl/_pls`, `_sty`, `_err`,
`_req/_ack`, and CDC-only `_q/_q2` usage. Confirm that aliases, abbreviations,
and stacked suffixes remain necessary and that symmetric paths use parallel
names. Rename internally owned violations before completion; report public or
project-owned violations that cannot be changed.

Before finishing, confirm:

1. Project rules and public interfaces were preserved.
2. Every output traces back to a defined event/fact and exact cycle.
3. Event, register lifetime, and same-cycle priority are explicit.
4. Handshake, CDC/RDC, reset, width, and counter boundaries are safe.
5. Source order reads input/context -> events -> updates -> output origin.
6. Complex logic is split only at meaningful waveform checkpoints.
7. Busy, stall, timeout, abort, clear, disable, and simultaneous events were
   considered.
8. Large behavior was decomposed into clear local functional blocks at real
   timing boundaries; any extracted submodule has an explicit justification.
9. Existing verified modules were reused only where their exact contracts
   matched.
10. The comprehensive naming audit passed or every preserved exception was
    reported.
11. Required syntax, lint, directed tests, extracted-component tests,
   equivalence checks, and regression were run or explicitly reported as not
   run.
12. Numbered flow sections are continuous, ordered, unique, non-empty, and all
    module-scope internal signal declarations are owned by `0. Helper`.
13. Long Input Decode chains have concise causal group comments, and every
    complex combinational block explains qualification, dependency or priority,
    and its produced result; simple combinational logic is not over-commented.
