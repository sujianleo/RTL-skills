## Contents

1. Module-first questions
2. Five-essential FIFO model
3. State selection
4. Behavioral derivation order
5. Common design choices
6. Checks before finishing

## Module-first Questions

State these items before writing RTL:

- Is the FIFO synchronous or asynchronous?
- What is the depth and how is it encoded?
- Is first-word fall-through required?
- Are `full` and `empty` combinational views or registered status signals?
- What happens on simultaneous push and pop?

If the user does not specify, assume synchronous single-clock FIFO unless the interface clearly spans clock domains.

## Five-Essential FIFO Model

| Core | FIFO Question | Typical RTL |
|---|---|---|
| Fact | Which entries are currently owned by the FIFO? | memory, write pointer, read pointer, count/wrap/full-empty state |
| Event | Which operation was legally accepted this cycle? | `push_fire`, `pop_fire` |
| Priority | How do push and pop interact in one cycle? | count hold, pointer advance rules, bypass/FWFT rules |
| Boundary | What happens at empty, full, and pointer wrap? | block, allow simultaneous opposite op, wrap bit |
| Contract | What can producer/consumer assume? | `full` means cannot push, `empty` means cannot pop, unless contract defines bypass |

## State Selection

Choose the smallest state that fully explains behavior:

- Storage array: payload memory
- Write pointer: next write position
- Read pointer: next read position
- Occupancy or equivalent full/empty disambiguation state

Use one of these patterns:

1. Pointer + count
2. Pointer + extra wrap bit
3. Read/write pointer plus explicit empty/full flags

Prefer pointer + count for readability when depth is modest and timing is not critical.
Prefer wrap-bit schemes when matching common hardware implementation patterns matters.

## Behavioral Derivation Order

Derive FIFO logic in this order:

1. Define contract: registered output or FWFT, push/pop allowed at full/empty or not.
2. Define events: `push_fire` and `pop_fire` after full/empty gating.
3. List facts: payload storage, write position, read position, occupancy/disambiguation.
4. Set same-cycle priority: reset, push/pop combined, push-only, pop-only, hold.
5. Check boundaries: empty, full, wrap, simultaneous push/pop at boundary.

For each register, write set/clear/hold rules:

- Write pointer advances on accepted push
- Read pointer advances on accepted pop
- Count increments on push without pop
- Count decrements on pop without push
- Count holds on simultaneous push and pop

Never derive `full` and `empty` independently from ad hoc conditions after the fact. Derive them from the chosen state model.

## Common Design Choices

### Accepted Operations

Define accepted operations explicitly:

- `push_fire`: write request accepted this cycle
- `pop_fire`: read request accepted this cycle

These should reflect gating against `full` and `empty`, not raw user intent.

### Output Path

For registered-output FIFO:

- `rdata_valid` or equivalent follows the output register, not raw memory contents
- Handle the last item consumption carefully so valid deasserts only when no replacement exists

For first-word fall-through FIFO:

- Empty-to-nonempty transition may need a direct path from write side to output side
- Re-check same-cycle push/pop when empty

### Full and Empty

`empty` should answer whether a pop can legally occur.
`full` should answer whether a push can legally occur.

When simultaneous push/pop occurs:

- A full FIFO may still accept push if a pop also happens in the same cycle, depending on interface contract
- An empty FIFO may still provide data if a push also happens in the same cycle, depending on output mode

Make that contract explicit in the code comments.

## Checks Before Finishing

Verify these scenarios:

1. Reset to empty
2. Fill from empty to full
3. Drain from full to empty
4. Simultaneous push/pop in steady state
5. Simultaneous push/pop on full boundary
6. Simultaneous push/pop on empty boundary
7. Pointer wraparound

If readability is the user's priority:

- Prefer one register per `always` block when practical
- Use comments that name cycles such as push-only, pop-only, and push-pop
- Avoid helper wires that merely restate short conditions without adding meaning
