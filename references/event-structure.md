# Event and Register Structure

## Contents

- Event staging
- Event structs
- Combinational decomposition
- Event-owned register groups
- FSM placement
- Comments

## Event Staging

When many inputs form a multi-step decision, derive events in causal order:

```text
raw input qualification
  -> effective context / disable / clear boundary
  -> flow or transaction selection
  -> physical direction or resource ownership
  -> counter terminal / timing decode
  -> phase completion
  -> terminal done / abort
```

Use concise numbered labels only when the chain is genuinely large. A stage is
a reading aid, not a pipeline; preserve necessary same-cycle dependencies.
Name shared clear, abort, owner, and terminal facts at the earliest point where
their inputs are available, then reuse them.

Keep symmetric UPHY/DPHY, read/write, or lane paths parallel within each stage
so direction and priority are easy to compare. Do not add staged aliases to a
small obvious expression.

## Event Structs

Use a packed event struct only when many parallel current-cycle events share
one scope, lifetime, and derivation flow.

```systemverilog
typedef struct packed {
  logic enter_fire;
  logic done_fire;
  logic clr_fire;
} lp_evt_t;

lp_evt_t uphy_evt;

always_comb begin
  uphy_evt = '0;
  uphy_evt.enter_fire = uphy_req && uphy_rdy;
  uphy_evt.done_fire  = uphy_on && uphy_done;
  uphy_evt.clr_fire   = flow_kill || uphy_evt.done_fire;
end
```

Name the container `<scope>_evt`; do not repeat the scope in its fields. Give
the struct one combinational owner and a complete default. Keep cross-scope
priority and cleanup facts outside it.

Do not put registered state, sticky facts, externally defined ports, or events
with different lifetime/ownership into one event struct.

## Combinational Decomposition

Split a long decision when each intermediate has independent waveform meaning:

```systemverilog
assign tx_last      = tx_mode == TX_CL0S ? cl0s_last : cl12_last;
assign tx_elapsed   = tx_cnt >= tx_last;
assign lfps_done    = lfps_seen || lfps_accept_fire;
assign tx_done_fire = tx_on && (tx_timed ? tx_elapsed : lfps_done);
```

Keep simple comparisons, packing, and single-purpose ternaries on one line.
Keep LFSR, CRC, parity, and lookup equations compact when their individual terms
have no timing identity. Do not create an alias only to shorten a line.

In `always_comb`, assign all outputs on all paths and default them before
overrides. Keep one combinational owner per signal.

## Event-Owned Register Groups

Map each event to its remembered facts, shared clear/hold behavior, and
same-cycle priority. Group registers when they share owner, lifetime, update
events, clear, and priority. Split them when combining them hides the hardware
story.

Good groups include:

```text
state / flow phase
saved type, direction, or transaction context
pending / seen / done facts
counter and timer facts
completed payload and status pulses
CSR-visible or debug sticky facts
```

Do not create one giant clocked block containing state, timing, payload,
status, and CSR facts. Do not create one `always_ff` per register when several
registers form one coherent fact group.

Place one short comment before every non-obvious event-owned `always_ff` block:

```systemverilog
// Timeout: updates the active counter and timeout-pending fact.
always_ff @(posedge clk or negedge rst_n) begin
  // ...
end
```

The comment must explain what facts are updated, not restate clock/reset or
each assignment.

## FSM Placement

Keep the current-state register and next-state decode separate but adjacent
under one `// FSM` label. Put the `c_st` `always_ff` first and the `n_st`
`always_comb` immediately after it. Default `n_st = c_st` before transitions.
Do not insert counters, synchronizers, payload logic, or outputs between them.

## Comments

Use comments for intent, timing contract, priority reason, CDC safety, and
non-obvious protocol behavior. Avoid decorative dividers, long section
headers, comments inside condition expressions, and comments that restate code.
