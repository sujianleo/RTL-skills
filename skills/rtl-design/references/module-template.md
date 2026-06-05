## Purpose

Use this template when designing any new synchronous RTL module from scratch or when refactoring a messy module into a clearer structure.

Do not start by writing `if/else`. Fill this template first.

## Quick Rule

Use the same five essentials for every module:

| Core | Question | RTL Output |
|---|---|---|
| Fact | What information must survive after this clock edge? | register / flag / counter / state |
| Event | What makes a fact become true or false? | fire / pulse / done / timeout |
| Priority | If events happen in the same cycle, who wins? | ordered `if/else` update |
| Boundary | What absorbs late input, busy state, stall, abort, or reset? | pending / buffer / clear / hold |
| Contract | How does the module hand off responsibility externally? | valid-ready / req-done / pulse-level |

For each register, answer only these questions:

1. What unfinished fact does this register remember?
2. What event makes that fact become true?
3. What event consumes, clears, or invalidates the fact?
4. Which same-cycle priority decides set versus clear?
5. Why is hold correct at the boundary?

If these answers are unclear, the RTL is not ready to be written.

## Fill-In Template

```plain text
[Module Name]
____________________________

1. Module job in one sentence
- __________________________

2. Interface contract
- in/out signal: ____________
- in/out signal: ____________
- in/out signal: ____________
- port groups:
  - clock/reset: ____________
  - request/bus side: ________
  - response/status side: ____
  - config/register side: ____

3. Five essentials
- Fact: _____________________
- Event: ____________________
- Priority: _________________
- Boundary: _________________
- Contract: _________________

4. Module principle
- structural idea: __________
- why it works: _____________
- main tradeoff: ____________

5. Key timing scenarios
- idle -> first transfer: ___
- steady-state flow: ________
- stall edge: _______________
- recovery after stall: _____
- boundary case: ____________

6. Cross-cycle facts
- fact_a: must survive because ____________
- fact_b: must survive because ____________
- fact_c: must survive because ____________

7. State / register list
- reg_a: records ____________
- reg_b: records ____________
- reg_c: records ____________

8. Register derivation
- reg_a
  - fact: ___________________
  - set/load: _______________
  - clear/invalidate: _______
  - hold: otherwise hold

- reg_b
  - fact: ___________________
  - set/load: _______________
  - clear/invalidate: _______
  - hold: otherwise hold

- reg_c
  - fact: ___________________
  - set/load: _______________
  - clear/invalidate: _______
  - hold: otherwise hold

9. Same-cycle priority
- 1. ________________________
- 2. ________________________
- 3. ________________________

10. Meaningful event wires
- ev_a = ____________________
- ev_b = ____________________
- ev_c = ____________________

11. Output mapping
- output_a comes from: _______
- output_b comes from: _______
- done/ready clears: ________

12. RTL structure
- parameters / ports
- grouped ports with short comments
- state registers
- event wires
- one always block per register when practical
- output assigns

13. Post-write checks
- reset: ____________________
- normal flow: ______________
- stall: ____________________
- recovery: _________________
- boundary: _________________
- same-cycle in/out: ________
```

## Code Comment Skeleton

```verilog
/*
1. 模块一句话职责
- ...

2. 接口语义
- ...

3. 五要素
- 事实:
- 事件:
- 优先级:
- 边界:
- 契约:

4. 模块原理
- ...

5. 关键时序场景
- ...

6. 跨拍事实
- ...

7. 状态 / 寄存器
- ...

8. 每个寄存器的 set / clear / hold
- reg_a: ...

9. 输出映射
- ...

10. 结构说明
- 先讲行为和跨拍事实，再在这里补充对应的事件线名字
*/
```

- Put this comment inside the RTL code block instead of leaving the explanation only in prose above or below the code.
- Number the sections explicitly in the RTL block comment.
- Put this module-level `1..8` block comment before the `module` declaration.
- If multiple modules are combined into one system, add an ASCII module-connection block at the very beginning of the code block before the RTL modules.
- Do not add that ASCII block when the extra modules are only tiny helper modules or unrelated examples.
- In the design-derivation stage, describe only behavior and cross-cycle facts. Do not use implementation event-wire names too early.
- In the port list, group ports by function and add short comments for each group; add brief end-of-line comments to key ports when useful.
- Unless the user explicitly asks for otherwise, keep the final RTL limited to synthesizable logic only.
- If the example is very small, compress the text but keep `模块原理` and the register intent.
- By default, write RTL comments in Chinese unless the user explicitly asks for English or the repository already standardizes on English comments.

## Code-Area Comment Minimum

Besides the top block comment, add local comments in the RTL body for the places where intent is not obvious.

At minimum, comment these when present:

- port groups and key interface ports
- direct pass-through or gated interface paths
- key event wires and what behavioral event each one represents
- each `always` block or register bank and what fact it records
- debug / assertion / consistency-check blocks and what they validate

If the user wants synthesizable RTL only, omit non-synthesizable helpers such as:

- `initial` parameter checks
- `` `ifndef SYNTHESIS`` guarded logic
- `$error` / assertion-only checker blocks

## Working Order

Use this order every time:

1. Write the module job.
2. Define the external contract for each important port.
3. Fill the five essentials table: Fact, Event, Priority, Boundary, Contract.
4. Explain the module principle in plain language.
5. Act out the timing scenarios without forcing register names or event-wire names too early.
6. Extract the facts that must survive across cycles.
7. Turn those facts into the minimal register set.
8. Derive each register with `set / clear / hold`.
9. Decide same-cycle priority.
10. Create only meaningful event wires.
11. Map outputs back to state, facts, events, or contract.
12. Write RTL.
13. Re-run the scenarios mentally or in simulation.

## Good Habits

- Derive data movement before deriving `valid` or status flags.
- Derive `valid` from whether a data register truly contains usable content.
- In code comments, place `模块原理` before the timing scenarios so readers understand the structure first.
- Treat counters, flags, and pointers as stored facts, not arithmetic first.
- Prefer one register per `always` block when readability is the user's priority.
- Use comments to describe timing intent such as capture, refill, drain, rotate, or consume.
- Keep the design-derivation phase separate from the RTL implementation phase: first explain behavior, then name event wires.
- If the user asks for RTL output, default to returning only code blocks; avoid extra explanatory prose outside the code unless explicitly requested.

## Notion Export Rule

- If this template is exported to Notion as code, use the `verilog` fence directly.
- Do not export this template to Notion as `systemverilog` or `javascript`.
- If many code pages are placed under one Notion index page, keep them flat on that page rather than creating extra grouping pages.
- Separate different code types with `---`.
- Use colored headings to distinguish code types, without adding extra explanatory prose around those headings.

## Anti-Patterns

- Starting the key timing scenarios by naming registers before the required behavior is clear
- Starting the design-derivation section by naming event wires before the behavior is clear
- Creating helper wires that do not represent meaningful events
- Letting one register carry multiple unrelated meanings
- Writing `valid` and `ready` before deciding how data actually moves
- Skipping boundary scenarios such as empty, full, wrap, last item, or simultaneous in/out
