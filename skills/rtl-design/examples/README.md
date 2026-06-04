# RTL Design Code Examples

These examples are imported from the user's RTL code reference notes.

They are intentionally stored as review examples, not production-ready reusable IP.
Use `references/` for design rules and `examples/` for concrete RTL patterns.

## Files

- `skid.md`: 1-entry skid buffer.
- `reg_slice.md`: simple valid/ready register slice.
- `vr_stage.md`: compact valid/ready stage.
- `cdc_toggle.md`: toggle-based pulse CDC.
- `toggle_pulse_cdc.md`: compact toggle pulse CDC.
- `req_ack.md`: CDC req/ack closed-loop event transfer.
- `req_ack_4phase.md`: compact four-phase req/ack CDC.
- `strobe.md`: one-way strobe/data sender.
- `strobe_hold_tx.md`: compact strobe/data sender.
- `async_fifo.md`: minimal Gray-pointer async FIFO.
- `rst_sync.md`: async assert, sync deassert reset synchronizer.
- `rr_arb.md`: round-robin arbiter.
- `pulse_width_det.md`: high/low pulse width detector.
- `debounce_filter.md`: stable-cycle debounce filter.
- `nand_tree.md`: walk-one PAD scan and NAND tree observation.
