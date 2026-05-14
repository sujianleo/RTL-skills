# vibe_soc Reference

## 来源

- Source repository: `siliconpeasant/vibe_soc`
- Source URL: `https://github.com/siliconpeasant/vibe_soc`
- Observed branch: `main`
- Useful snapshot commit: `556fbc4872ff4feed87aaa1c3fb2d0ef34dd8fc6`

This page records `vibe_soc` as an RTL-skill reference/example, not as a vendored project dependency.

## 这个例子适合学什么

`vibe_soc` 是一个小型 SoC 前端工程骨架。它的价值不在于 IP 复杂度，而在于目录组织、模块分层、filelist、模块级 Makefile、顶层自动集成和生成物隔离。

适合参考：

1. 如何把 chip-level RTL、第三方 IP、自研 IP、脚本和文档拆成清晰目录。
2. 如何让每个模块拥有自己的 `de/rtl`、`dv/tb`、`de/run`、`dv/sim` 区域。
3. 如何用 `$SOC` 和 `PROJECT_ROOT` 管理可迁移 filelist。
4. 如何让 top-level 只做模块例化和信号连接，不把子模块逻辑揉进去。
5. 如何把生成物放进 `run/`、`sim/` 并通过 `.gitignore` 排除。

## 源工程结构

```text
vibe_soc/
├── chip/
│   ├── core/
│   ├── bus/
│   ├── periph/
│   ├── interconnect/
│   ├── top/
│   └── lib/
├── ip/
│   ├── third_party/uart/
│   └── digital/timer/
├── scripts/
│   ├── setup.sh
│   └── common.mk
├── doc/
├── Makefile
└── README.md
```

## 核心文件

- `README.md`: explains project layout and quick-start commands.
- `Makefile`: top-level setup/lint/clean entry.
- `scripts/setup.sh`: exports `PROJECT_ROOT`, `SOC`, `CHIP_PATH`, `IP_PATH`, and default simulator.
- `scripts/common.mk`: shared simulation rules for VCS, Verilator, Iverilog, and Xcelium.
- `chip/core/de/rtl/core.v`: simple core placeholder.
- `chip/bus/de/rtl/bus.v`: simple bus placeholder.
- `ip/third_party/uart/de/rtl/uart.v`: simplified APB UART placeholder.
- `ip/digital/timer/de/rtl/timer.v`: simplified APB timer placeholder.
- `chip/top/de/rtl/vibe_soc_top.v`: generated top-level integration wrapper.

## 作为 RTL skill 的参考原则

When using this repository as inspiration for future skill output:

1. Keep generated SoC scaffolding under an example/reference path, not in the skill root.
2. Prefer `de/rtl` for design source and `dv/tb` for verification source.
3. Generate deterministic `filelist.f` files, but do not commit simulator outputs.
4. Make top integration explicit: shared clocks/resets, named internal wires, and clear module-instance boundaries.
5. Treat placeholder RTL as skeleton code only. For real IP, replace it with behavior-derived, reviewed RTL and matching design notes.

## 我的判断

这个仓库适合放进 `RTL-skills` 作为 SoC 工程组织范例；不适合当成生产 IP 直接复用。`core`、`bus`、`periph`、`interconnect`、`lib` 当前都是模板级逻辑，真正有一点接口意义的是 APB 风格的 `uart`、`timer` 和 `vibe_soc_top` 连接关系。

后续如果要把它升级成真正可用的 SoC skill，我建议拆成三层：

1. `project-scaffold`: 只负责目录、Makefile、filelist、ignore 规则。
2. `ip-template`: 负责 APB/IP 模板、寄存器说明和模块级仿真。
3. `soc-integrate`: 负责端口扫描、shared signal mapping、top wrapper 生成和集成检查。
