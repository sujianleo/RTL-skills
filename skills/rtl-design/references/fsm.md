## Contents

1. State-first questions
2. Five-essential FSM model
3. State decomposition
4. Behavioral derivation order
5. Coding patterns
6. Checks before finishing

## State-First Questions

State these items before writing RTL:

- What are the observable phases of the behavior?
- What event causes entry into each phase?
- What event causes exit from each phase?
- Are outputs Moore-style, Mealy-style, or mixed?
- Is single-process, two-process, or three-process coding preferred by the codebase?

If the user only says "write an FSM", first define the states in natural language before choosing an encoding.

## Five-Essential FSM Model

| Core | FSM Question | Typical RTL |
|---|---|---|
| Fact | Which phase must survive into the next cycle? | `state_q`, target/source registers, counters |
| Event | What causes phase entry or exit? | `start_fire`, `done_fire`, `timeout_fire`, `abort_fire` |
| Priority | Which transition wins in the same cycle? | reset > abort/timeout > completion > start > hold |
| Boundary | What if input arrives while busy, done is skewed, or timeout races done? | pending bits, done_seen latches, explicit timeout rule |
| Contract | Which outputs are level per state and which are one-cycle pulses? | Moore/Mealy output mapping, req/done contract |

## State Decomposition

Choose states by behavior, not by implementation steps.

Good state names describe a stable mode such as:

- `IDLE`
- `WAIT_REQ`
- `ISSUE`
- `DRAIN`
- `ERROR`

Bad state names usually describe a single assignment or micro-step that should have been combinational logic instead.

Add explicit datapath registers only when information must survive across cycles. Do not encode payload history into the FSM state if a separate register is clearer.

## Behavioral Derivation Order

Derive FSM logic in this order:

1. Reset and initial state
2. External contract for start/done/abort/timeout
3. Events that enter and leave each phase
4. Facts besides state that must be remembered
5. Same-cycle priority for competing events
6. Steady-state behavior in each active state
7. Error or recovery behavior

For each state, answer three questions:

1. What must already be true to enter this state?
2. What outputs must hold while in this state?
3. What exact event causes transition out?

Only after that should you write `case (state)`.

## Coding Patterns

### Two-Process Style

Use when readability is the priority:

- One sequential block for `state <= next_state`
- One combinational block for `next_state` and, if desired, combinational outputs

### Three-Process Style

Use when you want maximum separation:

- One sequential block for state register
- One combinational block for next-state logic
- One combinational or sequential block for outputs

### Single-Process Style

Use only when the team already prefers it or the FSM is tiny.

Keep these rules:

- Default every combinational output
- Default `next_state = state`
- Keep transition comments grouped by current state
- Use enumerated types in SystemVerilog when available

## Checks Before Finishing

Verify these scenarios:

1. Reset enters the intended state
2. Every state has defined exit conditions
3. No illegal state causes silent latch-like behavior
4. Outputs in each state match the written intent
5. Error and timeout paths return somewhere defined
6. Back-to-back triggers do not skip required states

If the user asks for explanation:

- Explain the states in plain language first
- Then explain the transitions
- Only then discuss encoding or `always` block structure
