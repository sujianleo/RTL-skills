# Problem Decomposition and Standard Components

## Contents

- Decomposition method
- Component boundary test
- Reuse workflow
- Standard component contracts
- Integration and verification

## Decomposition Method

Start from the externally observable contract, then split the design by real
hardware ownership:

```text
external contract
  -> independent flows or protocol phases
  -> current-cycle events and remembered facts
  -> standard control/datapath components
  -> integration priority and output boundary
```

For every candidate subproblem, write down:

```text
input and output contract
clock and reset domain
accepted cycle and output latency
state or payload that survives an edge
clear, abort, disable, and restart behavior
same-cycle priority
parameter and error behavior
```

Split when a part has independent timing ownership, reuse value, a stable
interface, a separate verification surface, or implementation risk worth
isolating. Keep logic together when separation would hide same-cycle priority,
create a combinational loop, duplicate state, or add accidental latency.

## Component Boundary Test

A useful component should answer one clear question, for example:

- Has the qualified interval elapsed?
- Did a synchronized level change?
- Has the input remained stable long enough?
- Can this transaction be accepted or emitted?
- Which requester owns the resource this cycle?

Do not extract a submodule merely because an expression is long. First split
the expression into meaningful local facts; extract only when the resulting
contract remains independently useful or testable.

Follow repository rules for one module per file, library placement, parameter
style, clock/reset naming, and permitted dependencies.

## Reuse Workflow

Before implementing a helper:

1. Search the current repository and approved IP/library paths with `rg`.
2. Read the candidate module, tests, reset/latency contract, parameters, and
   supported corner cases.
3. Compare its exact behavior against the required contract.
4. Reuse it directly when the contract matches.
5. Wrap it only when the wrapper adds a real interface or policy boundary.
6. Create a new standard component only when no approved implementation fits;
   give it a focused unit test and a single responsibility.

Do not copy a component and make a private near-duplicate for one caller.
Extend the shared component only when all existing users remain compatible and
the task authorizes that scope.

## Standard Component Contracts

### Counter or Timer

Define enable, synchronous clear, load/restart, terminal value, comparison
cycle, wrap versus saturation, done pulse versus level, and width/parameter
boundaries. A simple local counter may stay inline; use a component when the
same policy repeats or needs focused verification.

### Edge Detector

Define rising, falling, or both-edge behavior and the reset value of the saved
sample. Detect edges only after the signal is synchronous to the consuming
clock. For asynchronous or cross-domain inputs, use the correct synchronizer
or event-crossing primitive first. Do not add a previous-sample register when
FSM state plus a synchronized level already expresses the event.

### Digital Filter, Deglitcher, or Debouncer

Define sample rate, accepted polarity, consecutive-sample/majority/integrator
algorithm, assertion and deassertion thresholds, hysteresis, output latency,
reset value, and behavior when samples alternate around the threshold. Do not
call a fixed delay a filter without stating which glitch patterns it rejects.

### Pulse Helper

For pulse synchronizers, stretchers, one-shots, or interval detectors, define
input event assumptions, exact output width, retrigger behavior, back-to-back
event behavior, and whether events can be lost while busy. Use CDC-safe pulse
crossing when clocks differ.

### Buffer, FIFO, or Queue

Define capacity, ready/valid or push/pop fire, fall-through versus registered
read behavior, backpressure, full/empty timing, simultaneous transfer, reset
flush behavior, and CDC architecture. Reuse a proven skid/elastic buffer or
async FIFO rather than rebuilding its control around each caller.

### Arbiter

Define fixed versus rotating priority, grant stability, hold-until-accept
behavior, fairness expectation, reset owner, and simultaneous request policy.

## Integration and Verification

Verify both the component contract and its integration boundary:

- unit-test legal parameters and component-specific corners;
- check the first and last counter/filter cycles and exact pulse width;
- test glitches just below/at/above a filter threshold;
- test back-to-back and simultaneous events;
- check reset during active operation and restart behavior;
- verify added module boundaries did not change latency or priority;
- run syntax/lint for every new module and the integrated top;
- use a miter or cycle-by-cycle comparison when replacing existing inline logic
  with a standard component.
