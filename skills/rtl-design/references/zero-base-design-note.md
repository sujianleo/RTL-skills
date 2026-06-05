# Zero-Base RTL Design Note

## Purpose

Use this framework when producing a Markdown explanation for any non-trivial RTL module. The audience is a human who may know almost no RTL, so the note must teach the design from behavior and timing facts before it names registers or `always` blocks.

The goal is not only to explain one module. The goal is to give the reader a reusable way to design the next module.

## Required Shape

Write the note in this order:

1. What problem does this module solve?
2. What is the external contract?
3. What are the five essentials?
   - Fact: what must survive across cycles?
   - Event: what changes each fact?
   - Priority: who wins in same-cycle conflicts?
   - Boundary: what absorbs late input, stall, abort, reset, or skew?
   - Contract: who owns each request, response, or payload?
4. What storage is the smallest honest memory for those facts?
5. What are the event wires, and what real event does each one mean?
6. What are the key scenarios?
7. How does each register set, clear, and hold?
8. How do outputs come from stored facts and events?
9. What checks prove the explanation matches the RTL?
10. What reusable design recipe can be applied to another module?

## Universal Questions

Before writing RTL, answer these questions in plain language:

- What enters this module?
- What leaves this module?
- Can the input side move faster than the output side?
- Can the output side stall?
- Does any command arrive before its payload?
- Does any response arrive after its request?
- Must ordering be preserved?
- Can one item be accepted while another item is completed?
- What happens at empty, full, first item, last item, and wraparound?
- What exact event means an item was accepted?
- What exact event means an item was consumed or completed?

## Storage Derivation

For each piece of storage, use this form:

```text
Register:
  remembers:
  becomes true or loads when:
  becomes false or invalid when:
  same-cycle priority:
  holds otherwise because:
  bug prevented:
```

If the `remembers` line is vague, the register is probably not well derived.

Good examples:

- `valid_reg` remembers whether the output payload is meaningful.
- `pending_slot` remembers which buffer slot is waiting for delayed payload.
- `fifo_count` remembers how many items are currently owned by the module.
- `state` remembers which phase of a multi-cycle protocol owns the output.

Bad examples:

- `flag` remembers a condition.
- `tmp` stores intermediate data.
- `state` controls everything.

## Scenario Checklist

Choose the scenarios that match the module contract:

- Reset to idle or empty
- First accepted item
- Steady one-per-cycle flow
- Downstream stall
- Stall release
- Delayed payload alignment
- Delayed response return
- Full boundary
- Empty boundary
- Simultaneous accept and consume
- Pointer wraparound
- Error, timeout, or illegal request
- Clock-enable pause

Each scenario should say what is true before the edge, what registers update on the edge, and what outputs mean after the edge.

## WaveDrom Guidance

Use WaveDrom only to support the prose, not to replace it.

- One `.wave.json` per scenario.
- Include only the signals needed for the story.
- Use event wires such as `accept_fire`, `consume_fire`, `payload_capture`, `done_fire`, `push_fire`, or `pop_fire`.
- Make every `wave` string in a file the same length.
- End every `wave` string with `.` so the rendered right edge is aligned.
- After drawing, trace every transition back to RTL code.

## Output Explanation

For every important output, write a short data path:

```text
input or stored fact
  -> event or selector
  -> register or state
  -> output
```

Then explain what holds during backpressure. If a protocol says payload must stay stable while stalled, the note must say which register or pointer makes it stable.

## Final Reusable Recipe

End the note with a compact recipe:

1. Identify the producer and consumer sides.
2. Define the external contract.
3. Fill the five essentials: Fact, Event, Priority, Boundary, Contract.
4. Allocate one clear storage element per fact.
5. Define accept and consume events.
6. Derive pointers, counters, wait bits, and states from those events.
7. Encode same-cycle priority before writing `if/else`.
8. Derive outputs from stored facts, event wires, or state phases.
9. Check reset, steady flow, stall, release, boundary, and simultaneous events.
10. Draw only the WaveDrom scenes that prove confusing timing.
11. Run lint and a tiny directed simulation for uncertain scenes.
