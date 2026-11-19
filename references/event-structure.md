# Event and Register Structure

## Event Chains

For a long control decision, derive each fact where its inputs become available.
A typical order is input qualification, effective context and clear, flow and
resource selection, timing terminals, phase completion, then final done or
abort. Keep parallel lane, direction, and read/write paths comparable at each
step. These steps describe same-cycle dependencies unless the timing contract
calls for a register.

Name intermediates that are useful in a waveform. For example, select the
terminal count in `tx_last`, compare it with the counter in `tx_elapsed`,
and combine that fact with phase ownership to derive `tx_done_fire`. Keep
LFSR, CRC, parity, and lookup equations compact when individual terms have no
timing identity.

## Packed Event Structs

Use a packed struct when many parallel current-cycle events share one scope,
lifetime, and derivation flow. Name the container `<scope>_evt` and omit that
scope from its fields. Give it one combinational owner and a complete default.

```systemverilog
typedef struct packed {
  logic enter_fire;
  logic done_fire;
  logic clr_fire;
} lp_evt_t;

lp_evt_t rx_evt;

always_comb begin
  rx_evt = '0;
  rx_evt.enter_fire = rx_req && rx_rdy;
  rx_evt.done_fire  = rx_on && rx_done;
  rx_evt.clr_fire   = flow_kill || rx_evt.done_fire;
end
```

Keep cross-scope priority and cleanup, registered state, sticky facts, public
ports, and events with different owners or lifetimes outside the struct.
