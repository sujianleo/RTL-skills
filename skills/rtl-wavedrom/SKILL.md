---
name: rtl-wavedrom
description: Use this skill to create, edit, or validate WaveDrom JSON timing diagrams as timing evidence for RTL notes. Each diagram must prove one concrete scenario and trace back to actual RTL events, registers, priority, boundaries, and contracts.
metadata:
  source: "RTL skill set"
  category: rtl
---

# RTL WaveDrom

Use this skill to create, edit, or validate WaveDrom `.wave.json` timing diagrams for RTL behavior.

Core idea:

```text
WaveDrom = timing evidence for one RTL scenario
```

Do not draw vague protocol overviews.

A diagram must prove one concrete behavior from the RTL note.

## 1. Role In The Skill Set

`rtl-note` owns the learning note and decides which timing scenarios need evidence.

`rtl-wavedrom` owns:

- valid WaveDrom JSON
- cycle-level signal timing
- equal-length waves
- readable labels
- traceability to RTL expressions and register update rules

`rtl-check` can later validate the same scenario through lint or directed simulation.

## 2. When To Use

Use this skill when the user asks for:

- WaveDrom
- `.wave.json`
- RTL timing diagram
- cycle N / N+1 waveform
- timing evidence for a design note
- ready/valid stall diagram
- pending / busy / abort timing
- skewed done pulse timing
- FSM transition waveform

Do not use this skill for RTL code generation; use `rtl-design`.

Do not use this skill for standalone prose; use `rtl-note`.

Do not use this skill for lint/simulation; use `rtl-check`.

## 3. Reference Guide

Reuse the RTL design references:

- `../rtl-design/references/module-template.md`
- `../rtl-design/references/handshake.md`
- `../rtl-design/references/fifo.md`
- `../rtl-design/references/arbiter.md`
- `../rtl-design/references/fsm.md`
- `../rtl-design/references/zero-base-design-note.md`

## 4. Five-Essence Timing Evidence

Every diagram should prove at least one of the five essentials.

| 核心 | WaveDrom 要证明什么 |
|---|---|
| 事实 | 哪个寄存器跨拍记住了某个事实 |
| 事件 | 哪个 pulse/fire/done 触发 set/clear |
| 优先级 | 同拍多个事件时谁赢 |
| 边界 | busy/stall/abort/skewed done 如何被吸收 |
| 契约 | input/output pulse/level handshake 如何交接 |

Before drawing, write:

```text
Scenario:
- ...

Proves:
- fact/event/priority/boundary/contract

Bug prevented:
- ...
```

## 5. Scenario Selection

One file should explain one concrete scenario.

Good names:

```text
waves/<module>_first_transfer.wave.json
waves/<module>_stall_hold.wave.json
waves/<module>_pending_when_busy.wave.json
waves/<module>_skewed_done.wave.json
waves/<module>_abort_priority.wave.json
waves/<module>_timeout_priority.wave.json
waves/<module>_simul_consume_refill.wave.json
waves/<module>_state_release.wave.json
```

Avoid one large diagram that tries to explain the whole module.

## 6. Minimal Signal Set

Include only signals needed for the timing story.

Order signals by story flow:

1. `clk`
2. key input pulse/level
3. meaningful event wire
4. cross-cycle fact register
5. FSM state or counter, only if needed
6. downstream wait/done
7. final output/release

Good examples:

```text
clk
wake_pulse_i
exit_busy
pending_wake_q
start_fire
state_q
req_o
done_i
```

Avoid raw boolean signals that do not teach the timing decision.

## 7. Traceability Rule

Every transition in the diagram must trace to RTL.

For each important signal, know:

```text
input stimulus:
- driven by test/scenario

event wire:
- assign expression

register:
- always_ff set/clear/hold rule

output:
- state phase / registered fact / event mapping
```

The adjacent note should include:

```markdown
RTL 对照：
- `start_fire` comes from `assign ...`
- `pending_q` sets in `always_ff ...`
- `req_o` is driven by `state_q == S_REQ`
```

## 8. Event Wire Timing Rule

For combinational event wires, distinguish:

```text
before sampling edge
vs
after register update
```

Signals such as `accept_fire`, `consume_fire`, `start_fire`, `done_fire`, `push_fire`, and `pop_fire` may be true before the edge and change immediately after state updates.

If ambiguity matters, explain which side of the clock edge the diagram shows.

## 9. Backpressure / Hold Rule

In any stall or backpressure diagram, show stability.

If the protocol says a side owns data, that data must hold.

Examples:

- `valid && !ready`
- `out_valid && !out_ready`
- busy FSM cannot accept a new pulse unless pending is provided
- request must hold until done if contract says level request

If stimulus changes payload under stall, call it illegal BFM/source behavior.

## 10. Priority Rule

Use WaveDrom to prove priority when same-cycle events are tricky.

Common priority scenarios:

```text
abort vs done
timeout vs done
set pending vs clear pending
consume vs refill
push vs pop at boundary
start vs busy
```

The diagram must make clear which event wins and which register value appears after the edge.

## 11. JSON Style Rule

Keep JSON small.

Prefer:

- no nested groups unless needed
- no `I` / `O` / `int` direction labels
- no `head.text` by default
- no long `foot.text`
- short data labels: `A0`, `D0`, `R0`, `IDLE`, `WAIT`, `DONE`
- `config: { "hscale": 2 }` when labels are close
- color only important state/data bands

Do not color everything.

## 12. Wave Length Rule

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

## 13. JSON Validity Rule

Before finishing, validate:

1. JSON parses correctly.
2. Every signal has a name.
3. Every signal has a wave.
4. All wave strings have equal length.
5. Every wave string ends with trailing hold `.`.
6. Data labels match data/state symbols.
7. Arrows use continuous node letters if used.
8. Edge labels are short.
9. Long explanation is outside JSON, in the note.

## 14. Arrows

Use arrows only when they clarify causality.

If used:

```json
"edge": [
  "a->b set",
  "c->d clear"
]
```

Rules:

- node letters should be continuous in reading order
- keep nodes few
- keep labels short

Long explanation belongs in the adjacent RTL note.

## 15. Minimal Example: Pending Wake While Busy

```json
{
  "config": { "hscale": 2 },
  "signal": [
    { "name": "clk",          "wave": "p......." },
    { "name": "wake_i",       "wave": "010...." },
    { "name": "busy",         "wave": "01...0." },
    { "name": "pending_q",    "wave": "0.1..0." },
    { "name": "start_fire",   "wave": "0....10" },
    { "name": "req_o",        "wave": "0.....10" }
  ]
}
```

Adjacent note should state:

```text
Fact:
- pending_q remembers wake_i arrived while busy.

Event:
- wake_i pulse sets pending_q.
- start_fire consumes it.

Boundary:
- busy would otherwise lose a one-cycle pulse.

Bug prevented:
- wake event lost while FSM was busy.
```

## 16. Final Signal Check

For every drawn signal, check:

1. Is it input, event wire, register, state, counter, or output?
2. What RTL expression or always_ff block changes it?
3. What clock edge causes the update?
4. What happens under reset/abort/clear?
5. What happens if set and clear happen in the same cycle?
6. Does the diagram match the module contract?
7. Does the diagram show accepted DUT behavior, not illegal stimulus?
8. Are all wave strings equal length and ended with `.`?

## 17. Handoff

Use `rtl-note` to explain why this scenario matters.

Use `rtl-design` if RTL must be changed.

Use `rtl-check` if the diagram should be validated with lint or directed simulation.
