---
name: rtl-wavedrom
description: Use this skill to create, edit, or validate WaveDrom JSON timing diagrams for RTL behavior. The diagrams must explain concrete timing scenarios and be traceable to actual RTL expressions, event wires, and register update logic.
metadata:
  source: "RTL skill set"
  category: rtl
---

# RTL WaveDrom

Use this skill to create, edit, or validate WaveDrom `.wave.json` timing diagrams for RTL modules.

The diagram must explain one concrete timing scenario, not a vague protocol overview.

## Reference Guide

This skill reuses the original RTL module design references.

- `../rtl-design/references/module-template.md`: generic module-design checklist and register-derivation template.
- `../rtl-design/references/handshake.md`: skid buffer, register slice, full register slice, pipeline relay, and elastic buffer.
- `../rtl-design/references/fifo.md`: pointer logic, full or empty generation, and simultaneous push or pop.
- `../rtl-design/references/arbiter.md`: fairness policy, grant timing, and backpressure interaction.
- `../rtl-design/references/fsm.md`: state decomposition, transition rules, and output strategy.
- `../rtl-design/references/zero-base-design-note.md`: universal Markdown explanation framework for designing any RTL module from first principles.

If the repository already contains these files under another path, keep the existing path and update links consistently.

## Trigger This Skill When

Use this skill when the user asks for:

- WaveDrom
- `.wave.json`
- timing diagram
- cycle N / cycle N+1 waveform
- ready/valid stall diagram
- request/response wait diagram
- command/payload alignment
- FIFO full/empty timing
- simultaneous push/pop
- arbiter grant timing
- FSM transition waveform

Do not use this skill for RTL code generation. Use `rtl-design`.

Do not use this skill for pure design prose. Use `rtl-design-note`.

Do not use this skill for lint/simulation commands. Use `rtl-verilator-check`.

## Core Rule

Draw from actual RTL behavior, not protocol intuition.

Every transition must be traceable to one of:

- input stimulus
- combinational `assign`
- meaningful event wire
- `always_comb`
- `always_ff`
- register update condition

After drawing, perform signal-by-signal validation.

## Scenario Selection

Pick one concrete scenario per file.

Good scenario files:

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

Prefer multiple small files over one crowded diagram.

## Minimal Signal Set

Include only signals needed for the timing story.

Order signals by story flow:

1. clock
2. upstream control/data
3. meaningful event wire
4. stored cross-cycle fact register
5. downstream wait/done
6. final output/release

Good signals:

- `clk`
- `in_valid`
- `in_ready`
- `in_data`
- `accept_fire`
- `valid_q`
- `data_q`
- `out_valid`
- `out_ready`
- `consume_fire`

For FIFO, include `push_fire`, `pop_fire`, `fifo_count`, `full`, and `empty`.

For request/response, include `req_fire`, `response_wait`, `rsp_valid`, `rsp_ready`, and `response_done`.

Avoid raw booleans that do not teach the timing decision.

## WaveDrom Style

Keep JSON small.

Prefer:

- no nested groups unless necessary
- no `I` / `O` / `int` direction labels
- no `head.text` by default
- no bottom note pseudo-signals
- no long `foot.text`
- short data labels: `A0`, `D0`, `R0`, `IDLE`, `WAIT`, `DONE`
- `config: { "hscale": 2 }` when labels are close

Use colored data/state bands with WaveDrom symbols `2`-`9` only for important stored facts or payloads.

Do not color everything.

## Backpressure Rule

In any backpressure diagram, show payload stability.

If protocol says the source is stalled, then payload must hold stable.

Examples:

- `valid && !ready`
- bus `ready` output held low
- downstream `ready=0`
- clock-enable pause
- sink owns payload but has not completed

If stimulus changes address/control/data during stall, call it a source/BFM violation. Do not draw it as accepted DUT behavior.

## Event Wire Timing Rule

For combinational event wires, explicitly distinguish value before the sampling edge from value after registers update.

Signals such as `accept_fire`, `consume_fire`, `payload_capture`, `done_fire`, `push_fire`, and `pop_fire` may be true before an edge and change immediately after state updates.

The diagram and adjacent explanation must say which side of the edge is being shown if ambiguity matters.

## Alignment Rule

If prose says timing alignment, cycle N / cycle N+1, address phase versus data phase, command arrives before payload, response data returns later, delayed done, or wait state, then create or update a dedicated `.wave.json` file.

Example names:

```text
module_payload_align.wave.json
module_response_wait.wave.json
module_stall_hold.wave.json
```

## JSON Validity Rule

Before finishing, validate the generated JSON.

Checklist:

1. JSON parses correctly.
2. Every signal has a name.
3. Every signal has a wave.
4. All wave strings have equal length.
5. Every wave string ends with trailing hold `.`.
6. No ragged right edge.
7. Data labels match data/state symbols.
8. Arrows use continuous node letters if used.
9. Edge labels are short.
10. No long prose inside `foot.text`.

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

## Arrows

Use arrows only when they clarify causality.

If used:

- node letters should be continuous in reading order: `a`, `b`, `c`, `d`
- keep number of nodes small
- prefer official edge-label style

```json
"edge": [
  "a->b push",
  "c->d pop"
]
```

Keep labels short, usually one word.

Long explanation belongs in the adjacent Markdown design note.

## Example: Ready/Valid Stall Hold

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

After drawing, explain:

- `in_data` stays `D0` while accepted/stalled behavior requires stability.
- `valid_q` remembers that one payload is waiting.
- `consume_fire` clears the stored fact.

## Final Signal-by-Signal Check

After creating or editing WaveDrom, check every drawn signal against RTL.

For each signal:

1. Is it input, combinational event, or register-backed value?
2. What exact RTL makes it change?
3. Under stall/backpressure, does it hold, clear, or recompute?
4. Under reset/flush/abort, what happens?
5. Is this transition before or after the clock edge?
6. Does the diagram show accepted DUT behavior or illegal stimulus?
7. Does the diagram match the register update priority?

If uncertain, create a tiny directed simulation scenario with `rtl-verilator-check`.

## Handoff To Other Skills

Use `rtl-design` if the RTL needs to be written or fixed.

Use `rtl-design-note` if the diagram needs a companion explanation.

Use `rtl-verilator-check` if the diagram should be validated by lint or directed simulation.
