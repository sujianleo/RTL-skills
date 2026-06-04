# RTL Skills

```text
+----------------------------------------------------------------+
| RRRRRRRRRR   TTTTTTTTTTTT   LL                                 |
| RR      RR       TTT        LL                                 |
| RR      RR       TTT        LL                                 |
| RRRRRRRRR        TTT        LL                                 |
| RR    RR         TTT        LL                                 |
| RR     RR        TTT        LL                                 |
| RR      RR       TTT        LLLLLLLLLLLL                       |
|                                                                |
|          behavior -> facts -> registers -> RTL                 |
+----------------------------------------------------------------+
```

Codex skills for RTL design, notes, WaveDrom diagrams, and Verilator checks.

## Skills

| Skill | Use |
|---|---|
| `rtl-design` | Design or refactor synthesizable RTL. |
| `rtl-note` | Write review-friendly RTL design notes. |
| `rtl-wavedrom` | Draw or check RTL timing diagrams. |
| `rtl-check` | Run lint, syntax checks, or small directed simulations. |

## Install

Run from the repository root:

```sh
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills" && cp -R skills/rtl-design skills/rtl-note skills/rtl-wavedrom skills/rtl-check "${CODEX_HOME:-$HOME/.codex}/skills/"
```

## Contents

- `skills/rtl-design/references/`: design rules and checklists.
- `skills/rtl-design/examples/`: small RTL reference examples.

## Principle

```text
derive behavior first, then write RTL
```

Each register should have a clear fact, set event, clear event, and hold rule.
