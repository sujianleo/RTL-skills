# RTL Skills

Reusable Codex skills for RTL design, documentation, timing diagrams, and Verilator checks.

## Contents

- `skills/rtl-design/`: main synthesizable RTL design and refactor skill.
- `skills/rtl-design/references/`: shared RTL references for module templates, handshake paths, FIFOs, arbiters, FSMs, and zero-base design notes.
- `skills/rtl-design-note/`: Markdown design-note skill for review-friendly RTL explanations.
- `skills/rtl-wavedrom/`: WaveDrom `.wave.json` timing-diagram skill.
- `skills/rtl-verilator-check/`: Verilator lint and small directed simulation skill.

## Recommended Local Install

Copy or sync the skill directories into:

```text
$CODEX_HOME/skills/
```

Expected local layout:

```text
$CODEX_HOME/skills/rtl-design
$CODEX_HOME/skills/rtl-design-note
$CODEX_HOME/skills/rtl-wavedrom
$CODEX_HOME/skills/rtl-verilator-check
```

## Safety

This repository intentionally stores only skill instructions and reference notes.

Do not add Codex auth files, memory databases, logs, tokens, user secrets, or generated caches.
