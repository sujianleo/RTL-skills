# Codex RTL Skills

```text
██████╗ ████████╗██╗
██╔══██╗╚══██╔══╝██║
██████╔╝   ██║   ██║
██╔══██╗   ██║   ██║
██║  ██║   ██║   ███████╗
╚═╝  ╚═╝   ╚═╝   ╚══════╝
```

Codex skills for RTL design, notes, WaveDrom diagrams, and Verilator checks.

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

- `rtl-design`: design or refactor synthesizable RTL.
- `rtl-note`: write RTL design notes.
- `rtl-wavedrom`: draw RTL timing diagrams.
- `rtl-check`: run lint and small directed checks.
