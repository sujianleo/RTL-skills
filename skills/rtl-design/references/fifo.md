## Contents

1. Module-first questions
2. State selection
3. Behavioral derivation order
4. Common design choices
5. Checks before finishing

## Module-first Questions

State these items before writing RTL:

- Is the FIFO synchronous or asynchronous?
- What is the depth and how is it encoded?
- Is first-word fall-through required?
- Are `full` and `empty` combinational views or registered status signals?
- What happens on simultaneous push and pop?

If the user does not specify, assume synchronous single-clock FIFO unless the interface clearly spans clock domains.

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

1. Reset state
2. Push-only cycle
3. Pop-only cycle
4. Simultaneous push/pop cycle
5. Boundary behavior at empty and full

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
