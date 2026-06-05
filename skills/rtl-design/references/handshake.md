## Contents

1. Port semantics
2. Five-essential reading
3. Core timing scenarios
4. Design categories
5. Derivation order
6. Register checklist
7. Common mistakes
8. AXI channel guidance

## Port Semantics

For `valid/ready` style interfaces, keep the port meanings strict:

- `s_valid`: upstream presents a beat this cycle
- `s_ready`: this module can accept a beat this cycle
- `m_valid`: this module presents a beat downstream this cycle
- `m_ready`: downstream accepts a beat this cycle
- `data` or `payload`: the beat associated with the handshake

Do not mix external meaning with internal cause. Example: `s_ready` means "can accept now", not "skid slot is empty". The latter is an internal reason.

## Five-Essential Reading

Use this table before choosing simple slice, skid buffer, or elastic buffer.

| Core | Handshake Question | Typical RTL |
|---|---|---|
| Fact | Which beat is owned by this module after the edge? | `valid_q`, `data_q`, skid/queue occupancy |
| Event | Which transfer happened this cycle? | `in_fire = s_valid && s_ready`, `out_fire = m_valid && m_ready` |
| Priority | If consume and refill happen together, which data becomes visible next? | refill-before-load or consume-before-clear ordering |
| Boundary | What happens when downstream stalls or upstream sends one more beat? | hold payload, skid slot, full/empty guard |
| Contract | What must upstream/downstream see? | payload stable while `valid && !ready`, transfer only on `valid && ready` |

## Core Timing Scenarios

Always reason through these cases:

1. Idle to first transfer
2. Steady-state one beat per cycle
3. Downstream stall edge
4. Recovery after stall
5. Same-cycle consume-and-refill
6. Empty / full boundary if buffering depth is greater than one

## Design Categories

### Simple Register Slice

Use when the main goal is to cut the forward `data/valid` path.

Typical structure:

- one payload register
- one valid register
- `s_ready` often still combinationally depends on `m_ready`

Tradeoff:

- simple
- good for forward timing
- does not necessarily break the reverse `ready` path

### Skid Buffer

Use when the main goal is to break the reverse `ready` path while safely absorbing one extra beat.

Typical structure:

- one main output register
- one skid register
- one skid-valid flag
- often registered `s_ready`

Key idea:

- once `ready` feedback is delayed by a register, upstream may legally send one extra beat on the stall edge
- the skid register stores that extra beat

Tradeoff:

- solves ready feedback timing
- one extra beat of elasticity
- more control logic than a simple slice

### Full Register Slice

Use when both forward and reverse timing should be cleaned up.

In practice this often means:

- a slice implementation with skid-buffer behavior
- or a vendor IP mode that internally behaves like one

Treat it as a stronger form of slice, not just "one more register".

### N-Deep Elastic Buffer

Use when one beat of elasticity is not enough and a deeper decoupling buffer is needed.

Typical structure:

- small FIFO or elastic queue
- write pointer
- read pointer
- occupancy count or equivalent state

Tradeoff:

- stronger decoupling
- better tolerance of bursty backpressure
- higher latency and more area

## Derivation Order

For any handshake buffer, use this order:

1. State the external contract: when can input be accepted and output consumed?
2. Name the event wires: `in_fire`, `out_fire`, and any refill/bypass event.
3. List the facts: output beat valid, payload value, skid/queue occupancy.
4. Decide same-cycle priority: reset, flush, consume/refill, accept, hold.
5. Identify boundaries: stall edge, recovery, full/empty, simultaneous consume/refill.
6. Map outputs: `m_valid`, `m_data`, `s_ready`.
7. Check stall-edge and recovery scenarios.

## Register Checklist

For each register, write:

- fact it records
- set or load event
- clear or invalidate event
- hold reason

Examples:

- `valid_reg`: does the current output register hold a valid beat
- `skid_en`: does the skid register currently hold a deferred beat
- `count`: how many beats are buffered in the elastic queue

For each of those, write:

- Fact: what ownership or payload fact survives.
- Event: what sets/loads or clears it.
- Priority: what happens on same-cycle consume and accept.
- Boundary: what happens under stall or full.
- Contract: which external signal observes the fact.

For data registers, write load-source priority explicitly:

- refill from older buffered data first
- direct input next

## Common Mistakes

- Calling a simple register slice a skid buffer even though `ready` still propagates combinationally
- Deriving `valid` before understanding how data actually moves
- Forgetting that registered `ready` can allow one extra beat on the stall edge
- Allowing the design to accept more beats than explicit storage can hold
- Using too many helper wires that restate conditions without expressing events

## AXI Channel Guidance

AXI channels are just handshake channels with protocol-specific payloads.

Use these mappings:

- `AW`, `W`, `AR`: usually forward command/data paths
- `B`, `R`: return paths from downstream back to upstream

When inserting timing stages in AXI:

- apply the same handshake reasoning per channel
- keep channels independent unless protocol coupling explicitly requires shared control
- choose the structure by timing need:
  - simple slice for forward path relief
  - skid/full slice for reverse `ready` path relief
  - elastic buffer for deeper decoupling

When the user asks for "AXI register slice", clarify internally which of these three they really need, then implement that behavior explicitly.
