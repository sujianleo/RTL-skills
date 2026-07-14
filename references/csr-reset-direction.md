# CSR, IRQ, Reset, and Direction Mapping

## CSR Status

Classify every software-visible status as one of:

```text
live level
sticky bit
write-1-clear sticky bit
read-clear sticky bit
IRQ pending
```

Define event owner, set condition, clear condition, hold behavior, reset value,
clock domain, and simultaneous set/clear dominance. Use set-dominant behavior
when clearing and receiving a new event together must not lose the new event;
otherwise follow the documented contract.

Do not directly synchronize a multi-bit CSR status bus across domains. Transfer
coherent snapshots, individual safe facts, or use a handshake/FIFO.

## IRQ

Separate the source event from its software-visible or externally visible
interrupt state:

```text
event pulse -> pending/sticky fact -> IRQ line or pulse encoding
```

Determine whether the interface requires a pulse, pending level, sticky status,
or masked level. Do not default to a pulse. Define masking, clear, re-arm, and
same-cycle new-event behavior. Name the result according to its lifetime:
`*_irq_pls`, `*_irq_pending`, or `*_irq_sty`.

## Reset and Functional Clear

Keep the asynchronous reset branch dedicated to reset values:

```systemverilog
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n) begin
    c_st <= S_IDLE;
  end else if (flow_kill) begin
    c_st <= S_IDLE;
  end else begin
    c_st <= n_st;
  end
end
```

Do not write `if (!rst_n || flow_kill)` in an asynchronous reset branch.
Functional clear, abort cleanup, phase exit, context cleanup, and software
clear belong after reset deassertion with explicit priority.

Use the RDC rules in [cdc-fifo-rdc.md](cdc-fifo-rdc.md) for asynchronous reset
release and interactions between reset domains.

## Direction Mapping

When physical side and logical direction differ, expose the mapping with one
named fact and a short reason:

```systemverilog
// DPHY_RX observes downstream-side abort, which maps to U2D logical flow.
assign u2d_abort_fire = dphy_abort_fire;

// UPHY_RX observes upstream-side abort, which maps to D2U logical flow.
assign d2u_abort_fire = uphy_abort_fire;
```

Do not infer RX-side ownership from the TX output name or hide a direction swap
inside sequential assignments. Verify mapping against the protocol topology,
not signal-name intuition.
