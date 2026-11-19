# CSR, IRQ, Reset, and Direction Mapping

## Software-Visible State

Classify each CSR status as live, sticky, write-one-to-clear, read-clear, or
IRQ pending. Define its owner, set/clear/hold rules, reset value, domain, and
priority when a software clear and a hardware event coincide. Use
[CDC-safe transfers](cdc-fifo-rdc.md) for status in another domain, such as
a coherent snapshot or separately meaningful single-bit facts.

Keep the IRQ source event separate from any pending or sticky state and from
the externally visible encoding. Derive pulse, pending level, sticky status,
or masked level from the interface. Specify masking, clear, re-arm, and
same-cycle event handling. Document how a sustained IRQ is cleared.

## Functional Clear

Keep the asynchronous reset branch dedicated to reset values. Put functional
clear, abort, disable, phase or context cleanup, and software clear in
synchronous branches after the reset condition, with explicit priority.
For example, in an asynchronous-reset `always_ff`, use `if (!rst_n)`
followed by `else if (flow_kill)`. Never combine reset and functional clear
in one reset condition. Use the [RDC rules](cdc-fifo-rdc.md) for release and
reset-domain interactions.

## Direction Mapping

When physical side and logical flow differ, name the mapping before the
register updates and document why it applies. For example, if a downstream RX
abort belongs to upstream-to-downstream flow, use
`assign u2d_abort_fire = dst_rx_abort_fire;`. Verify ownership against the
protocol topology and keep symmetric mappings visible. Do not infer the
observing RX from the TX output name.
