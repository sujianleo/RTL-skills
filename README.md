# RTL Skills

```text
+--------------------------------------------------+
|  ____  _____ _        ____  _  ___ _     _       |
| |  _ \|_   _| |      / ___|| |/ (_) | __| |___   |
| | |_) | | | | |      \___ \| ' /| | |/ _` / __|  |
| |  _ <  | | | |___    ___) | . \| | | (_| \__ \  |
| |_| \_\ |_| |_____|  |____/|_|\_\_|_|\__,_|___/  |
|                                                  |
|        behavior -> facts -> registers -> RTL     |
+--------------------------------------------------+
```

Codex skills for practical RTL design work.

This repository collects reusable prompts, reference notes, and small RTL examples for designing, explaining, drawing, and checking synthesizable SystemVerilog / Verilog modules. The main intent is to make RTL work start from behavior and timing, not from ad hoc `if` / `else` code.

## What Is Included

| Skill | Purpose |
|---|---|
| `rtl-design` | Write or refactor synthesizable RTL from interface contract, timing scenarios, stored facts, and register update rules. |
| `rtl-note` | Produce review-friendly Markdown design notes that explain an RTL module from first principles. |
| `rtl-wavedrom` | Create or validate WaveDrom timing diagrams that match real RTL signals and register updates. |
| `rtl-check` | Run or propose Verilator lint, syntax checks, and small directed simulations. |

## Repository Layout

```text
skills/
  rtl-design/
    SKILL.md
    references/
    examples/
  rtl-note/
    SKILL.md
  rtl-wavedrom/
    SKILL.md
  rtl-check/
    SKILL.md
```

`references/` contains design rules and derivation checklists for module templates, handshake paths, FIFOs, arbiters, FSMs, and zero-base design notes.

`examples/` contains concrete RTL pattern examples such as valid/ready stages, skid buffers, CDC event transfers, async FIFO, reset synchronizer, round-robin arbiter, strobe/data transfer, pulse-width detection, debounce filtering, and scan helpers.

## Install

Run this from the repository root:

```sh
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills" && cp -R skills/rtl-design skills/rtl-note skills/rtl-wavedrom skills/rtl-check "${CODEX_HOME:-$HOME/.codex}/skills/"
```

Expected result:

```text
${CODEX_HOME:-$HOME/.codex}/skills/rtl-design
${CODEX_HOME:-$HOME/.codex}/skills/rtl-note
${CODEX_HOME:-$HOME/.codex}/skills/rtl-wavedrom
${CODEX_HOME:-$HOME/.codex}/skills/rtl-check
```

## Typical Use

Use `rtl-design` when you want to create or refactor RTL. It should derive the module in this order:

1. module job
2. interface contract
3. timing scenarios
4. facts that must survive across cycles
5. register set / clear / hold rules
6. RTL implementation
7. signal-by-signal check

Use `rtl-note` when the output should be a human-readable design explanation.

Use `rtl-wavedrom` when a timing diagram is needed.

Use `rtl-check` when lint or small scenario verification is needed.

## Design Principle

The core rule is:

```text
derive behavior first, then write RTL
```

For every important register, the skill should be able to answer:

1. What fact does this register remember?
2. What event makes that fact true?
3. What event makes that fact false?
4. Why is hold correct in all other cycles?

If those answers are not clear, the RTL is not ready to be written.

## Notes

- The example RTL is for reference and review practice. Treat it as design material, not drop-in production IP.
- The skills prefer synthesizable RTL, explicit timing intent, meaningful event wires, and Verilator-based checks.
- The repository intentionally avoids auth files, local memory databases, logs, tokens, private paths, and generated caches.
