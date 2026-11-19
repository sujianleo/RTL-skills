---
name: rtl-design
description: Design, debug, review, or refactor non-trivial synthesizable SystemVerilog RTL involving cycle timing, FSMs, ready/valid or req/ack handshakes, CDC/RDC, FIFOs, CSR/IRQ, counters, pipelines, protocol control, functional-block decomposition, or reusable component selection. Use for behavior and architecture work; do not use for formatting-only edits, trivial one-line datapath expressions, or testbench-only requests.
---

# RTL Design

Follow the user request and the repository's `AGENTS.md`, coding guide, public
interface, and verification flow. These defaults apply where project rules are
silent. Preserve user changes and keep edits scoped to the named module and
supporting tests. In a behavior-preserving refactor, retain ports, reset style
and values, latency, qualifier and status alignment, protocol behavior,
same-cycle priority, and parameter behavior.

## Reference Routing

Read each applicable reference in full before editing RTL.

- [Naming](references/naming.md) for naming, renaming, and the final name audit.
- [Event structure](references/event-structure.md) for multi-step event chains,
  parallel paths, and packed event structs.
- [Decomposition and components](references/decomposition-components.md) for
  splitting a design into functional blocks, choosing components, or extracting
  a submodule.
- [Control correctness](references/control-correctness.md) for handshakes,
  pipeline context, FSM coverage, widths, and parameter boundaries.
- [CDC, RDC, and async FIFO](references/cdc-fifo-rdc.md) for crossings,
  synchronizers, and interactions between reset domains.
- [CSR, reset, and direction](references/csr-reset-direction.md) for status, IRQ,
  functional clear, and physical-to-logical direction mapping.

## Timing Contract

Define the contract before coding.

1. Define what the module accepts, remembers, and drives. Identify owners,
   clock and reset domains, the acceptance edge, captured context, first and
   last active cycles, and completion latency.
2. Derive meaningful current-cycle events from qualified inputs. Keep only the
   state, pending facts, sticky bits, and context that must survive an edge.
   Trace each output back to its owner and valid cycle. Distinguish same-cycle
   encoding, registered facts, sustained levels, and one-cycle pulses.
3. Define the winner for each state or register group when events coincide.
   A starting order is reset, then disable/abort/clear/kill, then
   consume/complete, then new event, then hold. Follow the actual contract
   for each group. For each pending or sticky fact, specify set-versus-clear
   dominance. Let set win when a simultaneous new event must survive. When
   completion and a new request coincide, specify whether the new request is
   accepted and what remains pending after the edge.
4. Resolve uncertain boundaries with a cycle table or waveform. Cover relevant
   busy, stall, timeout, abort, disable, simultaneous set/clear, reset release,
   skew, duplicate events, and counter limits.

## RTL Structure

Use the smallest structure that exposes the timing and ownership. Split large
designs into testable functional blocks inside the owning module by default.
Search approved repository components and reuse only when the contract matches.

Use this source order for a typical control or datapath module.

```systemverilog
//! 0. Helper
//! ---------

//! 1. Input Decode
//! ---------------

//! 2. Register Update
//! ------------------

//! 3. Output Generation
//! --------------------
```

- **Helper** contains all module-scope internal declarations, constants, types,
  helper functions, and tables. Put a short English purpose comment immediately
  above each helper function. Omit the prelude when there is nothing to declare.
- **Input Decode** contains minimal input-boundary capture or filtering followed
  by qualifications, events, and candidates in dependency order. Separate
  multi-step chains with short `//` purpose comments.
- **Register Update** contains functional state, transaction context, counters,
  sticky facts, and registered outputs. Group registers that share an owner,
  lifetime, update events, clear/hold rules, and priority. Keep priority
  branches expanded. Place the state `always_ff` and next-state `always_comb`
  next to each other, register first, under one `// FSM` label. Default next
  state to current state.
- **Output Generation** shows the observable source and combinational encoding.
  Keep state transitions and unrelated updates in their owning blocks. Put a
  standalone output pipeline here only when it owns that boundary and has no
  hidden update priority in an earlier block.

Use title-case stage names that identify the action and its object. Adapt the
stages to the actual flow. Before finishing, check that the stages are ordered,
consecutive, and nonempty, with helpers at 0 and runtime stages from 1. Use
adjacent `//!` title and divider lines, extend the divider through the title,
and leave one blank line after it. Separate independent blocks with one
blank line. Use local comments for local groups, and add a flow summary only
when the numbered stages cannot explain a branching flow.

Name a shared event or cleanup condition once. Split complex expressions at
meaningful waveform checkpoints. Keep simple comparisons, muxes, packing,
and function calls on one line when clear. Align related declarations and
assignments where it aids comparison. Use `always_comb` for procedural
combinational logic. Give each signal one owner, assign it on every path,
and set defaults before overrides. Avoid combinational feedback. Use
`always_latch` only for an intentional latch.

Use concise English comments immediately above non-obvious combinational
groups and nested decisions, including inside `always_*`. Explain the
qualification, dependency or priority, and result. For a non-obvious clocked
group, state which facts it updates. Skip comments that restate simple logic.

Use clock enables or project-approved integrated clock-gating cells. Ordinary
combinational logic must never gate a clock. Follow the cell's enable-latching,
test-enable, reset, and CDC contract. Keep assertions, `SYNTHESIS` guards,
and simulation-only checks in a testbench or formal harness unless requested
in the design.

## Verification

For RTL changes, run the project's syntax and lint checks or the closest
available equivalent, including for the parent and each new submodule. Exercise
the changed local contracts through directed tests at the parent interface.
Unit-test newly extracted submodules at legal parameters and component-specific
corners. Test relevant same-cycle conflicts and check both the observable
result and what survives the edge. Run the relevant active regression when
behavior changes. Keep assertions and corner stimulus intact.

Compare a behavior-preserving change against the original RTL, including
inline logic replaced by a reused or extracted module. Use a miter or formal
equivalence where supported, or run a cycle-by-cycle comparison against the
baseline. Compare payload, qualifiers, status, and latency under the same
stimulus, including relevant reset, stall, and simultaneous-event cases.
Report which comparison ran and its coverage. If any required check cannot
run, report the blocker and the behavior that remains unverified.

Audit all public and internal names in the edited module against the naming
reference, including existing names. Fix internally owned violations within
scope and report public or project-owned exceptions. Review-only work reports
findings and verification gaps without editing RTL.
