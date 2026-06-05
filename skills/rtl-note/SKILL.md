---
name: rtl-note
description: Use this skill to create fast RTL learning notes from existing RTL code. The note explains the module through five essentials: facts, events, priority, boundaries, and contracts. Useful for code reading, review, interview preparation, and reinforcement learning.
metadata:
  source: "RTL skill set"
  category: rtl
---
# RTL Design Note

Use this skill to quickly understand existing RTL code and turn it into a reusable learning note.

Core idea:

```text
Read RTL = find facts -> find events -> find priority -> find boundaries -> find contracts
```

This skill is not for writing new RTL.
It is for understanding, reviewing, and remembering RTL.

Default language: plain Chinese.

## 1. Purpose

The note should help the reader answer:

- 这个模块接收什么？
- 它需要记住什么？
- 什么事件会改变这些事实？
- 同一拍多个事件谁优先？
- 异常、阻塞、晚到、abort 怎么办？
- 它和外部模块如何交接责任？

The final note should be usable for:

- code review
- quick onboarding
- interview explanation
- design replay
- self-test / reinforcement learning

## 2. When To Use

Use this skill when the user asks for:

- RTL 代码讲解
- design note
- 快速理解模块
- 代码 review 笔记
- 按 5 要素拆解 RTL
- 面试讲法
- 强化学习/自测问题
- companion `.md` next to RTL

Do not use this skill for pure RTL code generation. Use `rtl-design`.

Do not use this skill for pure timing diagrams. Use `rtl-wavedrom`.

Do not use this skill for lint or simulation. Use `rtl-check`.

## 3. Core Five Essentials

Every note should revolve around this table.

| 核心 | 本质问题 | RTL 体现 | 阅读时要找什么 |
|---|---|---|---|
| 事实 | 这件事是否需要跨拍记住？ | register / flag / counter / state | 哪些寄存器在保存未完成事实 |
| 事件 | 什么发生了，导致事实成立或失效？ | fire / pulse / done / timeout | 哪些输入/组合事件改变寄存器 |
| 优先级 | 同一拍多个事件同时发生，谁赢？ | if-else priority | reset/abort/done/start/set/clear 顺序 |
| 边界 | 输入晚到、输出阻塞、abort/reset 怎么办？ | pending / buffer / clear | 如何防丢脉冲、防旧状态、防错配 |
| 契约 | 模块和外部如何交接责任？ | valid-ready / req-done / level-pulse | 输入输出是 pulse 还是 level，谁负责 done |

## 4. Default Output Structure

Use this structure by default.

```markdown
# <module_name> RTL 学习笔记
## 1. 一句话职责
## 2. 接口契约
## 3. 五要素总表
## 4. 主流程：input -> event -> register -> output
## 5. 关键寄存器推导
## 6. 同拍优先级
## 7. 边界场景
## 8. 典型时序故事
## 9. 易错点 / Bug 防护
## 10. 自测问题
```

For small modules, keep each section short.
For complex modules, keep the same order.

## 5. 一句话职责

Start with one sentence.

Template:

```text
这个模块负责接收 <input/event>，在 <condition> 下记住 <fact>，并驱动 <output/action>，直到 <done/clear>。
```

Example:

```text
u4_lp_exit 负责接收 LFPS wake，根据 CL0s/CL1/CL2 状态选择 active direction，依次请求 LFPS response、RX restore、CL_WAKE1、clock switch，并在完成后上报 directional exit done。
```

## 6. 接口契约

For each important interface, describe:

输入：

- pulse 还是 level？
- 是否已同步到本模块时钟域？
- 是否可能在 busy 时到达？
- 如果 busy 时到达，是否需要 pending？

输出：

- pulse 还是 level？
- 谁消费？
- 是否需要保持到 done？
- 外部 done/ack 的语义是什么？

Use a compact table:

| Signal | Direction | Pulse/Level | Contract | Consumer/Producer |
|---|---|---|---|---|
| `req_i` | input | pulse | 请求开始一次事务，busy 时可能丢失，需要 pending | upstream |
| `done_i` | input | pulse | 外部完成当前 request 后打一拍 | downstream |
| `busy_o` | output | level | FSM 非 idle 时保持为 1 | upstream |

## 7. 五要素总表

Create a summary table.

| 五要素 | 本模块中的体现 | 说明 |
|---|---|---|
| 事实 | `pending_wake_q` | 记录 wake 来过但还没消费 |
| 事件 | `start_fire`, `done_pulse_i`, `timeout_fire` | 改变状态/寄存器的触发条件 |
| 优先级 | reset > abort > done > start > hold | 同拍事件谁赢 |
| 边界 | busy wake、skewed done、abort | 用 pending/done_seen/clear 处理 |
| 契约 | req/done level/pulse | 外部模块必须满足的交接规则 |

## 8. 主流程：input -> event -> register -> output

Explain the module as a chain.

Template:

```text
input arrives
  -> event wire becomes true
  -> register records cross-cycle fact
  -> FSM/state phase changes
  -> output request/assertion is driven
  -> external done clears the fact
```

Example:

```text
LFPS wake pulse
  -> start_cl0s_uphy
  -> exit_src_uphy 记录本次方向
  -> E_WAIT_LFPS 请求 dphy_tx 发 LFPS
  -> dphy_tx_lfps_done 后进入 E_WAIT_PRE_DATA
```

## 9. 关键寄存器推导

Every important register must be explained as a remembered fact.

Template:

```markdown
### `<reg_name>`
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

Good example:

```markdown
### `pending_u2d_cl0s_wake`
记录的事实：
- U2D 方向在 exit FSM busy 时收到过 CL0s wake，但还没有被 start 消费。
置位条件：
- FSM busy
- U2D 方向仍处于 CL0s
- U2D wake pulse 到达
- 当前没有正在处理同一个 U2D CL0s exit
清除条件：
- reset / abort
- U2D 方向已经离开 CL0s
- `start_cl0s_uphy` 消费了这个 pending wake
保持条件：
- 还没被消费，且方向仍然处于 CL0s
防止的问题：
- FSM busy 时一拍 wake pulse 丢失
- 旧 pending wake 在方向已退出 CL0s 后误触发
```

## 10. 同拍优先级

Always describe priority explicitly.

Template:

```text
reset > abort/clear > consume/done > set new event > hold
```

For each important register, state what happens if set and clear happen in the same cycle.

Example:

```text
pending wake 同拍 set/clear：
- 如果 start 已经消费该方向 wake，clear 优先。
- 如果方向已不在 CL0s，clear 优先。
- 否则 busy 且 wake 到来时 set。
```

## 11. 边界场景

Pick only real boundaries from the RTL.

Common boundaries:

- input pulse arrives while FSM busy
- done pulses from two sides are skewed
- timeout and done same cycle
- abort during active flow
- output request needs to hold until external done
- state changes but external level has not cleared
- one direction exits while the other direction remains low-power

For each boundary, answer:

- 没有这个处理会出什么 bug？
- 当前 RTL 用什么结构吸收这个边界？

Example:

```text
问题：
- CL0s U2D wake 在 FSM 正在处理 D2U exit 时到来，pulse 只有一拍，可能丢失。
结构：
- `pending_u2d_cl0s_wake` 记录这个未消费事件。
防止的问题：
- U2D 方向永远无法退出 CL0s。
```

## 12. 典型时序故事

Use cycle language.

Template:

```text
第 N 拍：
- 输入事件发生。
- 哪个 event wire 为 1。
- 哪个 register 会在时钟沿后更新。
第 N+1 拍：
- FSM 进入哪个状态。
- 哪个 output 拉高。
- 哪个 fact 继续保持。
后续某拍：
- done/clear 到来。
- fact 被清除。
- output 释放。
```

Avoid vague descriptions such as:

```text
然后 FSM 处理这个流程。
```

## 13. 易错点 / Bug 防护

End with a short list.

Example:

```markdown
## 易错点
1. `CL0s_ACK` 只记录目标，不走 ACK shutdown path。
2. `CL1/CL2` 必须两个方向都进入 low power 后，global state 才能报 CL1/CL2。
3. `wake1_req` 如果 Phase2 外置，应保持到 clock switch done 前。
4. async reset 分支只放 reset，同步 clear 另写 else-if。
```

## 14. 自测问题

For reinforcement learning, end with questions.

Use direct questions:

```markdown
## 自测问题
1. 这个模块最重要的跨拍事实有哪些？
2. 哪个寄存器防止 busy 时 pulse 丢失？
3. 如果 done 和 timeout 同拍，谁优先？
4. 哪个输出是 level，哪个输出是 pulse？
5. 外部模块必须保证哪些 done/ack 语义？
6. 如果删掉某个 pending bit，会出现什么 bug？
7. reset、abort、normal done 的优先级是什么？
8. 这个模块的边界条件有哪些？
```

Questions should force the reader to replay the design, not memorize terms.

This skill is not for producing pretty documents. It is for making the reader able to answer:

```text
这个寄存器为什么存在？
如果删掉会出什么 bug？
哪个事件 set？
哪个事件 clear？
同拍谁优先？
外部必须保证什么？
```

## 15. What Not To Do

Do not:

- paste the whole RTL as the note
- repeat the port list without behavior
- say uses FSM without explaining state meaning
- say flag without saying what fact it remembers
- say improves timing without naming the path or storage boundary
- hide key behavior only in diagrams
- generate long textbook background unrelated to this module

## 16. Handoff

Use `rtl-design` if RTL needs to be written or refactored.

Use `rtl-wavedrom` if a timing story needs a diagram.

Use `rtl-check` if behavior should be validated by lint or directed simulation.
