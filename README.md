# Codex RTL Skills

```text
██████╗ ████████╗██╗
██╔══██╗╚══██╔══╝██║
██████╔╝   ██║   ██║
██╔══██╗   ██║   ██║
██║  ██║   ██║   ███████╗
╚═╝  ╚═╝   ╚═╝   ╚══════╝
```

Codex skills for RTL design, notes, WaveDrom diagrams, and verification checks.

The core selling point is the RTL five-essence method:

```text
facts -> events -> priority -> boundaries -> contracts
```

Instead of starting from `if / else` or tool commands, these skills help Codex
reason about RTL as concrete behavior:

| Essence | Question |
|---|---|
| Facts | What must be remembered across clock cycles? |
| Events | What makes a fact become true, false, or consumed? |
| Priority | If multiple events happen in one cycle, who wins? |
| Boundaries | What happens under busy, stall, late input, abort, reset, or skewed done? |
| Contracts | How does the module hand off responsibility through pulse, level, valid-ready, or req-done interfaces? |

Each skill uses the same five essentials from a different angle:

- `rtl-design`: derive and write RTL from facts, events, priority, boundaries, and contracts.
- `rtl-note`: read existing RTL and turn it into a reusable five-essence learning note.
- `rtl-wavedrom`: draw timing evidence for one concrete RTL scenario.
- `rtl-check`: prove the five essentials with lint, small directed simulations, assertions, and waveform evidence.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/sujianleo/RTL-skills/main/install.sh | sh
```

Default install path:

```text
~/.codex/skills
```

Custom install path:

```sh
CODEX_HOME=/path/to/.codex curl -fsSL https://raw.githubusercontent.com/sujianleo/RTL-skills/main/install.sh | sh
```

## Skills

- `rtl-design`: design or refactor synthesizable RTL by deriving behavior before coding.
- `rtl-note`: explain existing RTL through facts, events, priority, boundaries, and contracts.
- `rtl-wavedrom`: draw WaveDrom timing diagrams as scenario-level timing evidence.
- `rtl-check`: verify concrete RTL behavior with minimal controllable scenarios.
