---
name: rtl-module-design
description: Use this skill to write or refactor synchronous RTL by deriving behavior first and coding second. Useful for RTL modules, ready/valid or request/response datapaths, FIFOs, arbiters, FSMs, CDC-adjacent control, bus bridges, pipeline stages, and RTL-oriented WaveDrom timing diagrams.
metadata:
  source: "local Codex skill backup"
  category: personal
---

# RTL Module Design

Use this skill to write or refactor synchronous RTL by deriving behavior first and coding second.

## Reference Guide

- `references/module-template.md`: generic module-design checklist and register-derivation template.
- `references/handshake.md`: skid buffer, register slice, full register slice, pipeline relay, and elastic buffer.
- `references/fifo.md`: pointer logic, full or empty generation, and simultaneous push or pop.
- `references/arbiter.md`: fairness policy, grant timing, and backpressure interaction.
- `references/fsm.md`: state decomposition, transition rules, and output strategy.

## Core Method

Do not start from `if` or `else` syntax. Start from timing behavior and the facts that must survive into later cycles.

When writing explanations or top-of-file comments, make the reasoning feel like a careful human designer thinking through the problem:

1. Start from the two sides that may disagree, such as producer versus consumer, address phase versus data phase, valid versus ready, or request versus response.
2. Name the concrete timing hazard before naming the solution. Example: "the write address arrives before write data" before "use a pending bit."
3. Explain each register as a memory of one unfinished fact, not as an implementation detail. Example: "`pending_slot` remembers which buffer entry is still waiting for its delayed payload."
4. Use a small cycle-by-cycle story for confusing cases: "cycle N reserves the slot; cycle N+1 fills the payload; the downstream side consumes it later."
5. When the explanation discusses timing alignment, provide a separate WaveDrom `.json` file for each distinct scenario, such as command/payload alignment, response wait, stall hold, or simultaneous consume/refill.
6. End each section by saying what bug this structure prevents, such as pairing the wrong payload with a command, completing a response before data is valid, or changing downstream payload while stalled.

For each register:

1. State what fact the register records.
2. State what event makes that fact become true.
3. State what event makes that fact become false.
4. Treat all other cases as hold.

If the register meaning cannot be explained in one sentence, its update logic is not ready to be written.

## Design Template

1. Module job in one sentence.
2. Interface semantics.
3. Module principle.
4. Key timing scenarios.
5. Cross-cycle facts.
6. State or register list.
7. Set, clear, hold for each register.
8. Data-path priority.
9. Meaningful event wires only.
10. RTL implementation.
11. Final signal-by-signal RTL check.

## WaveDrom Timing Diagrams

When drawing WaveDrom for RTL, make the diagram explain the same timing facts used to derive the RTL.

1. Pick one concrete scenario, such as first transfer, steady-state flow, stall, stall recovery, simultaneous accept/consume, response return, or error response.
2. If the prose says "timing alignment", "cycle N / cycle N+1", or "address phase versus data phase", create or update a dedicated `.wave.json` file for that scenario instead of leaving the timing only in prose.
3. Name files by scenario, for example `module_payload_align.wave.json`, `module_response_wait.wave.json`, or `module_stall_hold.wave.json`.
4. For learning/explanation diagrams, keep JSON as small as possible: no nested groups, no `I`/`O`/`int` direction labels, and usually no `edge` arrows.
5. Include only signals that support the prose timing story: the upstream data/control that starts the event, the named event wire, the stored fact register, the downstream completion, and the final release/return.
6. Order signals by story flow: clock, upstream phase, event wire, stored cross-cycle fact, downstream wait/done, final output.
7. Use short data labels in narrow cycles. Prefer `A0`, `D0`, `R0`, `RDATA`, `IDLE`, `SETUP`, `ENABLE`; explain full names in prose instead of forcing them into the waveform.
8. Show meaningful event wires such as `accept_fire`, `consume_fire`, `done_fire`, `response_done`, `payload_capture`, `push_fire`, or `pop_fire`; avoid exposing raw booleans that do not teach the timing decision.
9. For stored facts, show the register whose fact survives across cycles, such as `payload_pending`, `pending_slot`, `response_wait`, `fifo_count`, `state`, `valid_reg`, or `grant_reg`.
10. Important signals may be highlighted, but only to clarify the story. Prefer colored data/state bands with WaveDrom symbols `2`-`9` for the 2-4 most important stored facts or payloads, such as `response_wait=WAIT`, `payload_slot0=D0 backfill`, or `state=ENABLE`.
11. Keep diagrams visually quiet by default: omit `head.text`; use arrows only when they clarify causality. If arrows are used, omit arrow text labels unless the user asks for them.
12. If arrows are needed, node letters should be continuous in reading order (`a`, `b`, `c`, `d`, ...). Keep the number of nodes small. Use different arrow colors only when the target WaveDrom renderer supports it; otherwise use colored data/state bands plus unlabeled arrows.
13. Do not rely on `foot.text` for multi-line notes; some WaveDrom renderers collapse newlines into one long line. Avoid bottom `note` pseudo-signals too, because they render as ugly empty waveform rows.
14. Prefer the official edge-label style for concise annotations, such as `"a->b push"` or `"e->f ready"`. Keep labels very short, usually one word.
15. Put longer explanations in the adjacent Markdown design note, one bullet per edge label, instead of forcing them into the waveform.
16. Do not color or annotate every signal. If color, arrows, or labels make the diagram harder to read, remove them and explain in prose instead.
17. For stall diagrams, keep the stalled payload stable across the wait window and show the exact completion event that releases it.
18. Add `"config": { "hscale": 2 }` when labels are close together; if text still overlaps, shorten labels before increasing diagram complexity.
19. Avoid ragged right edges in rendered WaveDrom. Before finishing, make every `wave` string in a `.wave.json` file the same length and end every signal with a trailing hold `.`. Do not leave the last visible state/data/0/1 token as the final character; otherwise rendered state bands can stop early and look misaligned.
20. Prefer multiple small scenario files over one crowded omnibus diagram. Choose scenarios from the module's real contract: single transfer, delayed payload alignment, read/response wait, posted or pipelined requests, full/empty stall and release, upstream-after-downstream ordering, simultaneous consume/refill, downstream-ready wait, clock-enable pause, and error or timeout response.
21. In any backpressure diagram, show the upstream payload holding stable while the protocol says it is stalled. Examples: `valid && !ready`, a bus `ready` output held low, a downstream `ready`/`done` input held low while payload is owned by the sink, or a clock-enable pause. If the stimulus changes address/control/data during a stall, call that out as a source/BFM violation instead of drawing it as accepted DUT behavior.
22. Validate generated `.json` with a JSON parser before handing it off, then run a small structural check that all `wave` strings in each file have equal length and end with `.`.
23. Strongest rule: after drawing or editing any WaveDrom, do a final signal-by-signal check against the actual RTL expressions and register update logic. Do not draw from protocol intuition alone; every transition must be traceable to an `assign`, event wire, or always block.
24. During that final check, ask for each signal: is it an input, combinational event, or register-backed value; exactly what code makes it change; and under stall/backpressure such as `valid && !ready`, downstream `ready=0`, clock-enable pause, or bus wait state, does the code hold, clear, or recompute it?
25. When visual inspection is uncertain, create a tiny directed simulation scenario that matches the diagram and use its waveform, `$display`, assertion, or checker output to confirm the signal timing. Good helper cases include: delayed downstream ready, delayed response data, stall hold, stall release, simultaneous accept/consume, full/empty boundary, pointer wrap, and protocol error response. Use tests to support the diagram, not to replace the signal-by-signal RTL trace.
26. Use Verilator as the mandatory default for RTL syntax checks, lint, and small directed simulations unless the user explicitly asks for another simulator or the design depends on unsupported simulator-specific behavior. Prefer `verilator --lint-only --Wall` for lint and Verilator-driven testbenches for waveform-assisted timing checks.
27. For combinational event wires, explicitly distinguish the value before the sampling edge from the value after registers update. Signals such as `accept_fire`, `consume_fire`, `payload_capture`, `done_fire`, `push_fire`, and `pop_fire` may be true before an edge and change immediately after state updates; diagrams and tests must say which side of the edge they are checking.
28. Organize helper tests by the diagram scenario, not by broad protocol coverage. Each small test should name the WaveDrom scene it supports, drive only the needed handshake, and assert the few signals that could be drawn wrong. Keep the commands in the adjacent design note so the scenario is easy to rerun.

## Module Principle

Before listing timing scenarios, explain the module's working principle in enough detail that a reader can sketch the block diagram before seeing any RTL. Default to 6-12 lines for non-trivial modules. Two to four lines is only acceptable for tiny wrappers.

For user-facing RTL comments, prefer a plain-language derivation section when the design has non-obvious timing:

1. "What is this module stuck between?" Describe both protocol sides or pipeline stages.
2. "Where do the timings not line up?" Call out the exact phase mismatch, stall, or ownership handoff.
3. "What is the smallest state needed?" Introduce FIFO slots, pending bits, wait bits, counters, or FSM states only after the problem is visible.
4. "What does each state element remember?" One sentence per register group.
5. "When does the stored fact clear?" Tie clearing to a named completion event, such as `consume_fire`, `done_fire`, `response_done`, `pop_fire`, or `ready && valid`.
6. "What failure would happen without it?" Close the loop in everyday language.

This section should answer:

1. What structural idea the module uses.
2. Why that structure solves the problem.
3. What tradeoff it introduces, if any.
4. How data or ownership moves through the structure.
5. Which elements are combinational and which are state-holding.
6. Where the important boundary conditions are absorbed.

Do not stop at naming the textbook pattern. Push the explanation down to mechanism level. A good `模块原理` section should usually cover:

1. The overall storage or pipeline shape.
2. The exact data path in time order.
3. The control rule that decides advance, stall, refill, rotate, wrap, or retire.
4. Which facts must be held across cycles and where they are stored.
5. Why this structure is required instead of a simpler one.
6. The latency, buffering, or control-complexity cost introduced by the structure.

Recommended writing order:

1. Start from the architectural picture in one sentence.
2. Explain the main data path in time order.
3. Explain which state elements remember cross-cycle facts.
4. Explain how the edge cases are absorbed.
5. End with the key tradeoff.

What to avoid in `模块原理`:

- naming a structure without explaining the mechanics
- repeating the port list in prose
- vague claims such as "improves performance" without stating how
- abstract comments that do not tell the reader where data is buffered or how control evolves over time

## Writing Rules

- Derive logic from scenarios such as idle, steady-state flow, stall edge, and stall recovery.
- Describe behavior first, then implementation conditions.
- Reason in terms of facts stored by registers, not raw boolean expressions.
- For explanations aimed at learning or review, use通俗的推导口吻: 先讲遇到的问题，再讲为什么需要这个寄存器，最后讲它防住了什么错。
- Prefer "第 N 拍 / 第 N+1 拍" or "先占座 / 再回填 / 后消费" style timing stories for cross-cycle behavior.
- When using that cycle-by-cycle timing style, also provide the matching WaveDrom JSON files and mention their paths near the prose.
- Keep delivered RTL synthesizable unless the user explicitly asks for checks.
- By default, use Chinese RTL comments.
- When adding explanatory comments, include a detailed `模块原理` section so the reader sees the core structure before the register-by-register derivation.
- In `模块原理`, prefer concrete mechanism words such as `直通`, `暂存`, `回填`, `仲裁`, `轮转`, `计数`, `占用`, `释放`, `跨拍保留`, and `边界吸收` over abstract summary words.
- If the design has more than one stage, explain each stage's job and handoff explicitly instead of compressing the explanation into one sentence.
- Keep comments close to timing intent, not syntax narration.
