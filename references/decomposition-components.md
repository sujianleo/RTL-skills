# Problem Decomposition and Standard Components

## Block Boundaries and Reuse

Split by flow, protocol phase, or ownership of remembered facts. For each
block, define inputs and outputs, clock/reset domain, acceptance cycle,
latency, retained state, same-cycle priority, clear/abort/disable/restart
behavior, and parameter or error behavior. A counter, timer, filter, arbiter,
or buffer can be a local block.

Search the repository and approved libraries with `rg`. Read the candidate
RTL and tests and compare latency, reset, priority, wrap or saturation, legal
parameters, and CDC behavior. Reuse a match where the project permits it.
Avoid private copies. Change a shared component only when the task allows it
and existing callers remain compatible.

Give each extracted module one responsibility. Extract when required by the
user or project, or when there is a real reuse, independent interface, CDC/IP
ownership, or focused verification boundary.
Keep tightly coupled priority and transaction context together. Check that
extraction adds no loop, duplicate state, or accidental latency. Follow
project rules for file layout and dependencies.

## Component Contracts

- **Counter or timer.** Define enable, synchronous clear, load or restart,
  terminal value and comparison cycle, wrap or saturation, and whether done
  is a pulse or level.
  Apply [width and boundary checks](control-correctness.md).
- **Edge detector.** Define the observed transitions and saved sample's reset
  value. Use the appropriate level synchronizer or event-crossing primitive
  before detection in the consuming domain. Keep the sample and event logic
  together. Skip the sample register if FSM state and the synchronized level
  already express the event.
- **Filter or debouncer.** Define sample rate, polarity, qualification algorithm,
  assertion and deassertion thresholds, hysteresis, latency, reset value, and
  behavior near the threshold, including alternating samples. State which
  glitches the filter rejects. Keep qualification, history, and the filtered
  output together.
- **Pulse helper.** Define legal input spacing, exact output width, retrigger
  and back-to-back behavior, and whether busy events are lost. Use a
  [CDC-safe crossing](cdc-fifo-rdc.md) when clocks differ.
- **Buffer or FIFO.** Define capacity, transfer events, fall-through or
  registered read behavior, backpressure, full and empty timing, simultaneous
  transfer, reset flush behavior, and CDC architecture where applicable.
  Prefer a proven skid buffer, elastic buffer, or async FIFO with the required
  contract.
- **Arbiter.** Define priority policy, grant stability, hold-until-accept
  behavior, fairness, reset owner, and simultaneous request handling.

## Targeted Checks

Cover legal parameter boundaries, first and last counter or filter cycles,
exact pulse width, glitches below/at/above the threshold, back-to-back and
simultaneous events, and reset during activity followed by restart. For an
extracted block, check latency and priority at the integration boundary. Use
the [baseline comparison](../SKILL.md#verification) when replacing inline
logic with a behavior-preserving implementation.
