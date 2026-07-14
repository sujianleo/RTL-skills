# Control and Datapath Correctness

## Ready/Valid

Define transfer only on the qualified event:

```systemverilog
assign in_fire = in_vld && in_rdy;
```

- Hold `vld` and payload stable while `vld && !rdy` unless the protocol
  explicitly permits withdrawal.
- Change consumed payload/state only on `fire`.
- Do not create a combinational path from downstream `rdy` through upstream
  `vld`, or from upstream `vld` through downstream `rdy`, when composition can
  close a combinational loop.
- State whether a pipeline is fall-through, registered, skid-buffered, or
  elastic. Verify latency and backpressure for each mode.

## Request/Acknowledge

State whether `req` is a level held until `ack` or a one-cycle action pulse.
Do not infer the behavior from the suffix alone. For level handshake, keep the
request and associated payload stable until acknowledgement. Define whether a
new request may be accepted on the same cycle as `ack`.

## Pipeline Context

Capture payload together with every mode, type, lane, FEC, removal, or
configuration fact that qualifies it. Use the captured context when processing
the delayed payload. Align status/error/ordered-set outputs with the data and
valid boundary they describe.

## Combinational Completeness

- Use `always_comb` for combinational procedural logic and assign every written
  signal on every path.
- Set defaults before `if`/`case` overrides.
- Use `always_latch` only for an intentional latch contract.
- Give each combinational signal one owner.
- Avoid combinational feedback and zero-delay ready/valid loops.

## Width and Signedness

- Size constants and counter terminals explicitly when implicit sizing could
  change comparison or arithmetic width.
- Avoid mixing signed and unsigned expressions without an explicit cast.
- Derive counter width from the maximum representable terminal value, including
  zero and exact-boundary parameter cases.
- Decide whether completion occurs at `limit`, `limit - 1`, or after increment;
  prove the first and last active cycles with a timing table or test.
- Check truncation, extension, shift width, part-select bounds, and concatenation
  width during lint.
- Keep parameter arithmetic elaboration-safe. Do not add simulation-only
  parameter guards inside synthesizable RTL unless requested; test legal
  boundary parameterizations externally.

## FSM Safety

- Give `n_st` a complete default and cover every state used by the encoding.
- Define recovery behavior for illegal or unexpected state values when the
  implementation technology or project requires it.
- Keep transition decisions separate from unrelated output/register updates.
- Do not encode timing in comments; encode it in events, counters, and tests.

## Clocking

Do not generate clocks with ordinary combinational gates or data logic. Use a
clock enable for RTL behavior or a project-approved integrated clock-gating
cell. Follow the cell's enable-latching, test-enable, reset, and CDC contract.

## Refactor Preservation

Preserve ports, reset values, latency, valid/status alignment, priority, and
parameter behavior unless the requested change explicitly alters them. For a
behavior-preserving rewrite, compare the new RTL against the baseline with a
miter, formal equivalence, or cycle-by-cycle reference test.
