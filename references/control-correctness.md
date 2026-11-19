# Control and Datapath Correctness

## Handshakes and Pipeline Context

- In ready/valid, transfer only on `vld && rdy`. Change consumed payload or
  state on that event. Hold valid and payload stable under stall unless the
  protocol permits withdrawal. Omit combinational paths from downstream
  ready to upstream valid or from upstream valid to downstream ready where
  composition can close a loop. Verify latency and backpressure for each
  fall-through, registered, skid-buffered, or elastic mode.
- In request/acknowledge, specify whether request is a pulse or a held level.
  For a held request, keep request and payload stable through acknowledgement.
  Define whether a new request can be accepted on the acknowledgement cycle.
- Capture payload and all qualifying context at the same boundary, including
  mode, type, lane, and configuration. Use that context with delayed data.
  Align status, errors, and protocol markers with the data and valid boundary
  they describe.

## Width and Signedness

- Size constants and terminals explicitly where implicit sizing can change
  comparison or arithmetic width. Use explicit casts when signed and
  unsigned values interact.
- Derive counter width from the maximum representable terminal. Cover zero
  and exact-boundary parameters. Specify whether completion occurs at
  `limit`, at `limit - 1`, or after increment, then check the first and last
  active cycles.
- Check truncation, extension, shift width, part-select bounds, and
  concatenation width in lint. Keep parameter expressions elaboration-safe and
  test legal boundary configurations in the harness.

## FSM Coverage

Cover every legal state and define recovery from unexpected encodings when
required by the technology or project. Keep transitions separate from
unrelated updates. Implement timing in events and counters and verify it in
tests.
