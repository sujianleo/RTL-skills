# CDC, RDC, and Async FIFO

## Crossing Selection

| Crossed fact | Structure |
|---|---|
| Stable single-bit level | Two-flop synchronizer |
| Sparse pulse or event | Toggle or pulse synchronizer with a defined event rate, or req/ack |
| Coherent multi-bit payload | Handshake-held payload or async FIFO |
| Counter or pointer advancing one Gray step at a time | Gray encoding with local decode |

Never send a raw pulse or combinational path across an unrelated clock domain,
or synchronize a payload bus bit by bit. For a held payload, synchronize the
control and keep the source payload stable from request launch until
acknowledgement returns. If the relative arrival cycle matters, cross the
combined fact through one protocol or verify tolerance of all legal skew,
including loss of same-cycle alignment. Add only project-approved synchronizer
attributes required by the flow.

## Reset Domains

- Follow the project reset architecture. Use asynchronous assertion only
  where the design and library support it. Synchronize deassertion in each
  receiving domain using that domain's own clock. Never reuse another
  domain's synchronized release. Keep
  [functional clears](csr-reset-direction.md#functional-clear) synchronous.
- Analyze logic across different resets even on one clock. Prevent false
  events when independently reset facts reconverge during assertion or
  release. Define what happens to pending handshakes, toggles, and pointers
  when one side resets while the other keeps running. Exercise this case in
  both directions when the design permits independent reset.
- In a classic async FIFO, resetting one pointer while the other side runs
  invalidates the contents. Define any-side reset as a FIFO-wide flush, or use
  a cross-domain flush/epoch handshake that blocks push and pop until both
  sides reinitialize. A synchronized `reset_done` may reopen traffic only if
  it is proven to belong to the current reset epoch.

## Classic Gray-Pointer FIFO

Require and document a power-of-two depth. Use local binary pointers for
addresses and arithmetic, and Gray pointers with an extra wrap bit for
crossing. Generate full in the write domain by comparing the next write Gray
pointer with the synchronized
read Gray pointer with its top two bits inverted. Generate empty in the read
domain from the synchronized write Gray pointer. Handle minimum-depth slices
without invalid part-selects.

```text
w_push_fire = w_en && !w_full
r_pop_fire  = r_en && !r_empty
```

Write memory only on `w_push_fire`. Advance each local pointer only on its
corresponding event during normal operation.
Specify registered-on-pop, fall-through, or combinational read behavior.
Use the target's dual-clock RAM model or inference rules for payload. Verify
empty read, full write, simultaneous traffic, wrap, near-full/near-empty,
and independent reset release.

## Crossing Evidence

For each crossing, record source and destination domains, crossed fact,
mechanism, payload stability, reset behavior, and reconvergence reasoning.
Run project CDC/RDC analysis when available. Lint and simulation alone do not
prove crossing safety.
