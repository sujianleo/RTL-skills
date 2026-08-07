# RTL Skills

`rtl-design` is a Codex skill for designing, debugging, reviewing, and
refactoring synthesizable SystemVerilog RTL.

It helps turn a timing contract into clear, cycle-accurate hardware: qualified
events, state and register updates, priority rules, and observable outputs.

## Covers

- FSMs, counters, pipelines, and protocol control
- Ready/valid and request/acknowledge handshakes
- CDC, RDC, synchronizers, and asynchronous FIFOs
- CSR, IRQ, reset, sticky-status, and direction-mapping behavior
- RTL structure, naming, reusable control blocks, and verification corners

## Use

Install this repository as a Codex skill, then invoke it when working on
non-trivial RTL:

```text
Use $rtl-design to review this SystemVerilog module.
```

The skill preserves existing interfaces and timing behavior unless a change is
explicitly requested. Supporting references provide focused guidance for
naming, event structure, control correctness, CDC/RDC, component decomposition,
and CSR/reset behavior.
