# RTL Skills

```text
██████╗ ████████╗██╗
██╔══██╗╚══██╔══╝██║
██████╔╝   ██║   ██║
██╔══██╗   ██║   ██║
██║  ██║   ██║   ███████╗
╚═╝  ╚═╝   ╚═╝   ╚══════╝
```

Codex skills for RTL design, notes, WaveDrom diagrams, and Verilator checks.

## Skills

| Skill | Use |
|---|---|
| `rtl-design` | Design or refactor synthesizable RTL. |
| `rtl-note` | Write review-friendly RTL design notes. |
| `rtl-wavedrom` | Draw or check RTL timing diagrams. |
| `rtl-check` | Run lint, syntax checks, or small directed simulations. |

## Install All Skills

Run from the repository root. This installs every skill under `skills/`:

```sh
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills" && cp -R skills/* "${CODEX_HOME:-$HOME/.codex}/skills/"
```

## Contents

- `skills/rtl-design/references/`: design rules and checklists.
- `skills/rtl-design/examples/`: small RTL reference examples.

## Principle

```text
derive behavior first, then write RTL
```

Each register should have a clear fact, set event, clear event, and hold rule.
