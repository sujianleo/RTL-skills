# Problem Decomposition and Standard Components

## Contents

- Terminology and default boundary
- Decomposition method
- Functional block test
- Reuse workflow
- Standard component contracts
- Integration and verification

## Terminology and Default Boundary

Treat a **standard component** first as a standard hardware function with a
clear contract: counter, timer, edge detector, digital filter, pulse helper,
arbiter, buffer, decoder, or protocol phase. It does not imply a separate
SystemVerilog module.

Implement that function as a coherent block inside the owning module by
default. A local functional block may consist of meaningful event/fact signals,
a short assignment group, a helper function, one coherent `always_ff`, or an
adjacent `always_ff`/`always_comb` pair. The block must make ownership, cycle
timing, clear behavior, and priority visible while preserving a single-pass
reading flow.

Treat **submodule extraction** as a later and separate architectural decision.
Extract only when the user or repository requires it, an approved reusable
module already exists, or the function has genuine reuse, independent
interface, CDC/IP, or focused-verification value. Do not turn conceptual
decomposition into file decomposition by default.

## Decomposition Method

Start from the externally observable contract, then split the design by real
hardware ownership:

```text
external contract
  -> independent flows or protocol phases
  -> current-cycle events and remembered facts
  -> standard local control/datapath blocks
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

Split the reasoning and source into functional blocks when a part has a clear
job and timing owner. Keep the blocks in the same module when they share
same-cycle priority or transaction context. Consider a module boundary only
for genuine reuse, a stable external interface, CDC/IP ownership, a separate
verification surface, or implementation risk worth isolating. Never extract
when separation would hide same-cycle priority, create a combinational loop,
duplicate state, or add accidental latency.

## Functional Block Test

A useful local block should answer one clear question, for example:

- Has the qualified interval elapsed?
- Did a synchronized level change?
- Has the input remained stable long enough?
- Can this transaction be accepted or emitted?
- Which requester owns the resource this cycle?

Represent the answer inside the parent module with a compact section such as:

```systemverilog
// Timeout counter: counts accepted wait cycles and raises a terminal event.
assign timeout_last = (timeout_cnt == cfg_timeout);
assign timeout_fire = wait_vld && timeout_last;

always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    timeout_cnt <= '0;
  end else if (wait_clr) begin
    timeout_cnt <= '0;
  end else if (wait_vld && !timeout_last) begin
    timeout_cnt <= timeout_cnt + 1'b1;
  end
end
```

Do not extract a submodule merely because an expression or block is long.
First split it into meaningful local facts and coherent update blocks. Extract
only when the resulting interface remains independently valuable.

Follow repository rules for one module per file, library placement, parameter
style, clock/reset naming, and permitted dependencies.

## Reuse Workflow

Before implementing a functional block:

1. Search the current repository and approved IP/library paths with `rg`.
2. Read the candidate module, tests, reset/latency contract, parameters, and
   supported corner cases.
3. Compare its exact behavior against the required contract.
4. If an approved implementation matches and project boundaries allow it,
   reuse it directly.
5. Otherwise implement the standard function as a clear local block; do not
   create a private helper module merely to make the top shorter.
6. Wrap or extract only when the wrapper/module adds a real interface, reuse,
   CDC, IP, policy, or verification boundary.
7. Give every newly extracted reusable module a focused unit test and one
   responsibility.

Do not copy a component and make a private near-duplicate for one caller.
Extend the shared component only when all existing users remain compatible and
the task authorizes that scope.

## Standard Component Contracts

### Counter or Timer

Define enable, synchronous clear, load/restart, terminal value, comparison
cycle, wrap versus saturation, done pulse versus level, and width/parameter
boundaries. Keep the counter as one clear local block by default. Reuse or
extract a counter module only when its exact policy repeats or needs an
independent interface and focused verification.

### Edge Detector

Define rising, falling, or both-edge behavior and the reset value of the saved
sample. Keep the saved sample and edge facts together as one local block.
Detect edges only after the signal is synchronous to the consuming clock. For
asynchronous or cross-domain inputs, use the correct synchronizer or
event-crossing primitive first. Do not add a previous-sample register when FSM
state plus a synchronized level already expresses the event.

### Digital Filter, Deglitcher, or Debouncer

Define sample rate, accepted polarity, consecutive-sample/majority/integrator
algorithm, assertion and deassertion thresholds, hysteresis, output latency,
reset value, and behavior when samples alternate around the threshold. Keep
sample qualification, history/counter, and filtered output ownership together
as one readable local block. Do not call a fixed delay a filter without stating
which glitch patterns it rejects.

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

Verify each local block's contract through the parent module's directed tests,
and verify every extracted module at both its own and integration boundaries:

- unit-test legal parameters and component-specific corners for an extracted
  reusable module;
- check the first and last counter/filter cycles and exact pulse width;
- test glitches just below/at/above a filter threshold;
- test back-to-back and simultaneous events;
- check reset during active operation and restart behavior;
- verify any added module boundary did not change latency or priority;
- run syntax/lint for the parent and every newly extracted module;
- use a miter or cycle-by-cycle comparison when replacing existing inline logic
  with a different implementation.
