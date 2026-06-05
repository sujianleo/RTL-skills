# Codex RTL Skills

[English README](README.md)

```text
██████╗ ████████╗██╗
██╔══██╗╚══██╔══╝██║
██████╔╝   ██║   ██║
██╔══██╗   ██║   ██║
██║  ██║   ██║   ███████╗
╚═╝  ╚═╝   ╚═╝   ╚══════╝
```

这是一组面向 RTL 设计、RTL 学习笔记、WaveDrom 时序图和最小验证场景的 Codex skills。

主打方法是 RTL 五要素：

```text
事实 -> 事件 -> 优先级 -> 边界 -> 契约
```

这套方法不从 `if / else` 或工具命令开始，而是先把 RTL 拆成可复述、可 review、可验证的具体行为：

| 五要素 | 核心问题 |
|---|---|
| 事实 | 哪些信息必须跨 clock cycle 记住？ |
| 事件 | 什么让事实成立、失效或被消费？ |
| 优先级 | 同一拍多个事件同时发生时，谁赢？ |
| 边界 | busy、stall、late input、abort、reset、skewed done 这些边界怎么处理？ |
| 契约 | 模块如何通过 pulse、level、valid-ready、req-done 等接口和外部交接责任？ |

四个 skill 使用同一套五要素，只是切入角度不同：

- `rtl-design`：从事实、事件、优先级、边界、契约推导并编写 RTL。
- `rtl-note`：阅读已有 RTL，并整理成可复用的五要素学习笔记。
- `rtl-wavedrom`：为一个具体 RTL 场景画出时序证据。
- `rtl-check`：用 lint、小 directed simulation、assertion 和 waveform 证明五要素真的成立。

## 安装

```sh
curl -fsSL https://raw.githubusercontent.com/sujianleo/RTL-skills/main/install.sh | sh
```

默认安装路径：

```text
~/.codex/skills
```

自定义安装路径：

```sh
CODEX_HOME=/path/to/.codex curl -fsSL https://raw.githubusercontent.com/sujianleo/RTL-skills/main/install.sh | sh
```

## Skills

- `rtl-design`：先推导行为，再设计或重构可综合 RTL。
- `rtl-note`：用事实、事件、优先级、边界、契约解释已有 RTL。
- `rtl-wavedrom`：把 WaveDrom 时序图作为场景级 timing evidence。
- `rtl-check`：用最小可控场景验证具体 RTL 行为。

## 适合场景

- 写一个新的同步 RTL 模块。
- review 一段已有 RTL 的设计意图。
- 把复杂 FSM、pending bit、done_seen、valid-ready hold 讲清楚。
- 给面试或学习整理 RTL 复述笔记。
- 为关键边界场景画 WaveDrom。
- 用 Verilator/lint/simulation 证明一个具体行为，而不是只跑工具命令。

## 核心原则

一个寄存器不只是 flag。

一个寄存器是：

```text
memory of an unfinished fact
```

如果这个被记住的事实不能用一句话说清楚，RTL 还没有准备好。
