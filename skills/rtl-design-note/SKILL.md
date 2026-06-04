---
name: rtl-design-note
description: Use this skill to create or update a human-readable Markdown design note for an RTL module. The note teaches the module from first principles, explains timing hazards, derives registers as cross-cycle facts, and links related WaveDrom scenario files.
metadata:
  source: "RTL skill set"
  category: rtl
---

# RTL Design Note

Use this skill to write or update a companion Markdown design note for an RTL module.

The design note is not a code dump. It should teach a human how the module is derived.

Default language: plain Chinese.

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

- RTL design note
- Markdown explanation
- module principle
- human-readable design document
- zero-base explanation
- review note for RTL
- companion `.md` next to RTL
- explanation of register meaning and timing scenarios

Do not use this skill for pure RTL code generation. Use `rtl-design` instead.

Do not use this skill for pure WaveDrom generation. Use `rtl-wavedrom` instead.

## Core Goal

The note should answer:

1. What real-world job the module performs.
2. Which sides may disagree in timing, ownership, rate, ordering, or latency.
3. What timing hazard appears because of that disagreement.
4. What facts must survive into later cycles.
5. Which register remembers each fact.
6. When each register sets, clears, or holds.
7. What bugs this structure prevents.
8. What timing scenarios should be checked.

## Document Structure

Use this structure by default.

```markdown
# <module_name> 设计说明
## 1. 模块职责
## 2. 接口语义
## 3. 模块原理
## 4. 关键时序场景
## 5. 跨拍事实
## 6. 寄存器推导
## 7. 数据通路优先级
## 8. 事件线定义
## 9. WaveDrom 时序图
## 10. RTL 对照检查
## 11. 可复用设计检查表
```

For small modules, sections may be shorter.

For complex modules, keep the same section order.

## Writing Style

Use plain Chinese by default.

Prefer patient, zero-base derivation.

Good style:

```text
这个模块卡在 upstream 和 downstream 中间。upstream 可能先把数据送来，但 downstream 不一定马上 ready。
如果没有暂存寄存器，stall 期间 payload 可能被上游换掉，导致下游最终接走错误数据。
因此模块至少需要一个 valid_reg 记录“当前是否有一笔数据还没被消费”，再用 data_reg 记录这笔数据本身。
```

Avoid expert shorthand without mechanism:

```text
本模块实现一个 ready/valid register slice，用于提升时序和吞吐。
```

## Module Principle Section

The `模块原理` section is mandatory for non-trivial modules.

It should usually be 6-12 lines.

Explain:

1. The overall storage or pipeline shape.
2. The exact data path in time order.
3. The control rule that decides advance, stall, refill, rotate, wrap, or retire.
4. Which facts must be held across cycles.
5. Where those facts are stored.
6. Why this structure is required instead of a simpler one.
7. The latency, buffering, or control-complexity cost.

Recommended order:

1. Start from the architectural picture.
2. Explain the main datapath in time order.
3. Explain cross-cycle state.
4. Explain how edge cases are absorbed.
5. End with the tradeoff.

Use concrete mechanism words: `直通`, `暂存`, `回填`, `仲裁`, `轮转`, `计数`, `占用`, `释放`, `跨拍保留`, `边界吸收`.

## Timing Hazard First

Before naming a solution, name the concrete problem.

Good:

```text
写地址和写数据可能不在同一拍到达。如果地址先到而数据后一拍才到，模块必须记住“哪个 entry 已经被地址占用但还没填入数据”。
因此需要 pending_slot 和 payload_pending。
```

Bad:

```text
使用 pending_slot 和 payload_pending 实现地址数据对齐。
```

## Cross-Cycle Fact Rule

Every important register must be explained as memory of one unfinished fact.

For each register, include:

```markdown
### <reg_name>

记录的事实：
- ...

置位条件：
- ...

清除条件：
- ...

保持条件：
- ...

防止的问题：
- ...
```

If the register meaning cannot be written in one sentence, the RTL is probably not clean enough.

## Key Timing Scenarios

Pick scenarios from the real module contract.

Common scenarios:

- first transfer
- steady-state flow
- stall hold
- stall release
- simultaneous consume/refill
- delayed payload alignment
- read/response wait
- posted request
- pipelined request
- FIFO full boundary
- FIFO empty boundary
- pointer wrap
- arbiter grant hold
- arbiter round-robin rotation
- clock-enable pause
- flush/abort
- timeout/error response

For confusing behavior, use cycle language.

```text
第 N 拍：upstream 发来 command，downstream 暂时不能接收，模块先把 command 暂存起来。
第 N+1 拍：payload 才到，模块用 pending bit 知道它属于上一拍的 command。
第 N+2 拍：downstream ready，模块把已经对齐的 command/payload 一起送出。
```

If the prose says timing alignment, cycle N / cycle N+1, address phase versus data phase, stall hold, response wait, or simultaneous consume/refill, then link a WaveDrom file generated by `rtl-wavedrom`.

## WaveDrom Link Section

Do not embed long WaveDrom JSON directly in the design note unless the user asks.

Prefer links:

```markdown
## 9. WaveDrom 时序图

- `waves/<module>_first_transfer.wave.json`: 第一笔传输。
- `waves/<module>_stall_hold.wave.json`: 下游 stall 时 payload 保持。
- `waves/<module>_simul_consume_refill.wave.json`: 同拍消费和回填。
```

Each linked diagram should support one specific timing story.

## RTL Comparison Section

End with a signal-by-signal check.

```markdown
## 10. RTL 对照检查

| 信号/寄存器 | 类型 | 改变条件 | stall 下行为 | 对应 RTL |
|---|---|---|---|---|
| `valid_q` | register | accept/set, consume/clear | hold | `always_ff ...` |
| `data_q` | register | capture on accept | hold | `always_ff ...` |
| `accept_fire` | comb event | `in_valid && in_ready` | recompute | `assign ...` |
```

Check:

1. Input, combinational event, or register-backed value.
2. What code makes it change.
3. Whether it holds under stall/backpressure.
4. Whether reset/flush/abort priority is correct.
5. Whether same-cycle events are handled.
6. Whether any payload can change while owned by another side.

## Reusable Checklist

End with a checklist a reader can reuse.

```markdown
## 11. 可复用设计检查表

- [ ] 接口契约是否先定义清楚？
- [ ] 哪两个时序侧可能不同步？
- [ ] 是否明确了最小跨拍事实？
- [ ] 每个寄存器是否有一句话含义？
- [ ] 每个寄存器是否有 set/clear/hold？
- [ ] stall 下 payload 是否保持？
- [ ] 同拍 consume/refill 是否安全？
- [ ] full/empty 边界是否安全？
- [ ] reset/flush/abort 优先级是否明确？
- [ ] WaveDrom 是否能追溯到 RTL 表达式？
```

## What Not To Do

Do not:

- paste the whole RTL as the design note
- repeat the port list without explaining behavior
- say "use FSM" without explaining state meaning
- say "improves timing" without explaining which path or storage boundary
- draw diagrams that are not traceable to RTL
- hide important behavior only inside WaveDrom footnotes
- generate long textbook background unrelated to this module

## Handoff To Other Skills

Use `rtl-design` if RTL code needs to be written or changed.

Use `rtl-wavedrom` if timing diagrams need to be created or validated.

Use `rtl-verilator-check` if lint, syntax check, or directed simulation is needed.
