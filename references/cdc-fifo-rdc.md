# CDC, RDC, and Async FIFO

## CDC Selection

Choose a crossing structure from the signal contract:

- stable single-bit level: two-flop synchronizer
- one-cycle or sparse event: toggle/pulse synchronizer or req/ack handshake
- coherent multi-bit payload: handshake-held payload or async FIFO
- continuously changing counter/pointer: Gray encoding with local decode

Never directly synchronize a multi-bit bus bit-by-bit, feed a raw pulse into an
unrelated clock domain, or create a combinational CDC path.

Name two synchronizer stages with the semantic root plus `_q/_q2`, such as
`done_q/done_q2`. Do not use `_q` for ordinary registers. Add project-approved
CDC attributes only when required by the flow.

For a handshake-held payload, keep the source payload stable from request
launch until destination acknowledgement returns. Synchronize control, not
each payload bit.

Avoid reconverging separately synchronized signals when their relative arrival
cycle matters. Cross the combined fact through one protocol or tolerate and
verify all legal skew.

## RDC and Reset Release

- Follow the repository reset architecture first.
- Permit asynchronous assertion only where the design and library support it.
- Deassert an asynchronous reset synchronously in every receiving clock domain.
- Do not reuse one domain's synchronized reset release in an unrelated clock
  domain.
- Analyze logic driven by different resets even when clocks are identical.
- Prevent independently reset facts from reconverging into a false event during
  assertion or release.
- Define what happens to pending handshakes, toggles, and FIFO pointers when one
  side resets while the other continues running.

A classic async FIFO cannot preserve data consistency when only one pointer
domain resets to zero while the other keeps operating. Define any-side reset as
a FIFO-wide flush, or add a cross-domain flush/epoch request-ack protocol that
blocks push/pop until both domains have reinitialized. Do not reopen traffic
from one independently synchronized `reset_done` level without proving that it
belongs to the current reset epoch.

Keep functional clear, abort, disable, phase cleanup, and software clear out of
the asynchronous reset expression.

## Async FIFO

Use local binary pointers for address/arithmetic and Gray pointers for crossing.
Use an extra pointer bit for wrap tracking. Generate full in the write domain
from synchronized read Gray pointer; generate empty in the read domain from
synchronized write Gray pointer.

For the classic Gray full comparison, compare the next write Gray pointer with
the synchronized read Gray pointer after inverting its two most-significant
bits. Handle minimum-depth slice boundaries explicitly; do not implement this
as a blind negative-width part-select.

For the classic Gray full test, require a power-of-two depth and document that
constraint. Do not silently apply the classic pointer equations to arbitrary
depths.

Define:

```text
w_push_fire = w_en && !w_full
r_pop_fire  = r_en && !r_empty
```

Write memory only on `w_push_fire`; advance local pointers only on their fire
events. State whether read data is registered-on-pop, first-word fall-through,
or combinational. Verify empty read, full write, simultaneous traffic, wrap,
near-full/near-empty, and independent reset release.

Do not synchronize payload bits. Treat the memory array as a dual-clock RAM
model and replace/infer it according to the target FPGA or foundry flow.

## Required Documentation and Checks

For each crossing, record source domain, destination domain, crossed fact,
chosen mechanism, payload stability assumption, reset behavior, and why
reconvergence is safe. Run the project's CDC/RDC analysis when available; lint
and simulation alone do not prove crossing safety.
