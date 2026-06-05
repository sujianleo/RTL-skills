---
name: rtl-wavedrom
description: Use this skill to create, edit, or validate WaveDrom JSON timing diagrams for RTL behavior. Diagrams must explain concrete timing scenarios and be traceable to actual RTL expressions, event wires, and register update logic.
metadata:
  source: "RTL skill set"
  category: rtl
---

# RTL WaveDrom

Use this skill to create, edit, or validate WaveDrom `.wave.json` timing diagrams for RTL modules.

Core rule: draw one concrete timing scenario from actual RTL behavior, not a vague protocol overview.

## When To Use

Use this skill when the user asks for:

- WaveDrom or `.wave.json`
- RTL timing diagram
- cycle N / N+1 waveform explanation
- ready/valid stall or release diagram
- request/response wait diagram
- command/payload alignment
- FIFO boundary timing
- simultaneous push/pop
- arbiter grant timing
- FSM transition waveform

Do not use this skill for RTL code generation; use `rtl-design`. For design prose use `rtl-note`. For lint or simulation use `rtl-check`.

## Reference Guide

Reuse the RTL design references:

- `../rtl-design/references/module-template.md`
- `../rtl-design/references/handshake.md`
- `../rtl-design/references/fifo.md`
- `../rtl-design/references/arbiter.md`
- `../rtl-design/references/fsm.md`
- `../rtl-design/references/zero-base-design-note.md`

## Core Method

A good waveform answers three questions:

1. What scenario is being tested?
2. Which event wire or register update causes each transition?
3. What bug would appear if the timing were wrong?

Every transition must trace back to one of:

- input stimulus
- combinational `assign`
- meaningful event wire
- `always_comb`
- `always_ff`
- register set / clear / hold rule

After drawing, perform signal-by-signal validation.

## Scenario Selection

Create one file per concrete scenario. Prefer several small diagrams over one crowded diagram.

Good names:

```text
<module>_first_transfer.wave.json
<module>_steady_flow.wave.json
<module>_stall_hold.wave.json
<module>_stall_release.wave.json
<module>_payload_align.wave.json
<module>_response_wait.wave.json
<module>_simul_consume_refill.wave.json
<module>_fifo_full_boundary.wave.json
<module>_fifo_empty_boundary.wave.json
<module>_arb_grant_hold.wave.json
<module>_timeout_error.wave.json
```

## Minimal Signal Set

Include only signals needed for the timing story.

Order signals by story flow:

1. clock
2. upstream control/data
3. meaningful event wire
4. stored cross-cycle fact register
5. downstream wait/done
6. final output/release

Ready/valid example signals:

- `clk`
- `in_valid`, `in_ready`, `in_data`
- `accept_fire`
- `valid_q`, `data_q`
- `out_valid`, `out_ready`
- `consume_fire`

For FIFO, include `push_fire`, `pop_fire`, `fifo_count`, `full`, and `empty`.

For request/response, include `req_fire`, `response_wait`, `rsp_valid`, `rsp_ready`, and `response_done`.

Avoid raw booleans that do not teach the timing decision.

## Style Rules

Keep JSON small.

Prefer:

- no nested groups unless necessary
- no `I` / `O` / `int` direction labels
- no `head.text` by default
- no bottom note pseudo-signals
- no long `foot.text`
- short data labels: `A0`, `D0`, `R0`, `IDLE`, `WAIT`, `DONE`
- `config: { "hscale": 2 }` when labels are close
- colored data/state bands only for important stored facts or payloads

Do not color every signal.

## Backpressure Rule

In any backpressure diagram, show payload stability.

If a protocol says the source is stalled, payload must hold stable. Examples:

- `valid && !ready`
- downstream `ready=0`
- clock-enable pause
- sink owns payload but has not completed

If stimulus changes address/control/data during stall, call it a source/BFM violation. Do not draw it as accepted DUT behavior.

## Event Wire Timing Rule

For combinational event wires, explicitly distinguish:

```text
before sampling edge
vs
right after registers update
```

Signals such as `accept_fire`, `consume_fire`, `done_fire`, `push_fire`, and `pop_fire` may be true before an edge and change immediately after state updates. The diagram or adjacent explanation must say which side of the edge is shown when ambiguity matters.

## Wave Length Rule

Avoid ragged right edges.

Every wave string in one file must:

- have equal length
- end with trailing hold `.`
- not end with the last visible state/data/0/1 token

Good:

```json
{ "name": "valid_q", "wave": "0.1..0." }
```

Bad:

```json
{ "name": "valid_q", "wave": "0.1..0" }
```

## JSON Validity Rule

Before finishing, validate:

1. JSON parses correctly.
2. Every signal has a name.
3. Every signal has a wave.
4. All wave strings have equal length.
5. Every wave string ends with trailing hold `.`.
6. Data labels match data/state symbols.
7. Arrows use continuous node letters if used.
8. Edge labels are short.
9. No long prose is hidden inside `foot.text`.

## Arrows

Use arrows only when they clarify causality.

If used:

- node letters should be continuous in reading order: `a`, `b`, `c`, `d`
- keep nodes few
- keep labels short

Example:

```json
"edge": [
  "a->b push",
  "c->d pop"
]
```

Long explanation belongs in the adjacent Markdown note.

## Minimal Example: Ready/Valid Stall Hold

```json
{
  "config": { "hscale": 2 },
  "signal": [
    { "name": "clk",          "wave": "p......" },
    { "name": "in_valid",     "wave": "01...0." },
    { "name": "in_ready",     "wave": "01.0.1." },
    { "name": "in_data",      "wave": "x2...x.", "data": ["D0"] },
    { "name": "accept_fire",  "wave": "01.0.1." },
    { "name": "valid_q",      "wave": "0.1..0." },
    { "name": "data_q",       "wave": "x.2..x.", "data": ["D0"] },
    { "name": "out_ready",    "wave": "0..1..." },
    { "name": "consume_fire", "wave": "0..1.0." }
  ]
}
```

Adjacent explanation should state:

- `in_data` stays `D0` while stalled.
- `valid_q` remembers one payload is waiting.
- `consume_fire` clears the stored fact.

## Final Signal Check

For every drawn signal, check:

1. Is it input, combinational event, or register-backed value?
2. What RTL makes it change?
3. Under stall/backpressure, does it hold, clear, or recompute?
4. Under reset/flush/abort, what happens?
5. Is this transition before or after the clock edge?
6. Does the diagram show accepted DUT behavior or illegal stimulus?
7. Does the diagram match register update priority?

If uncertain, create a tiny directed simulation with `rtl-check`.

## Handoff

Use `rtl-design` if RTL needs to be written or fixed. Use `rtl-note` if the diagram needs a companion explanation. Use `rtl-check` if the diagram should be validated by lint or directed simulation.
