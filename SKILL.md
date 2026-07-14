---
name: rtl-design
description: Use when designing, reviewing, or refactoring synthesizable SystemVerilog RTL with timing, state, priority, CDC, FIFO, CSR/IRQ, handshake, FSM, or protocol-control behavior.
---

# RTL Design

## Core Principle

```text
Less is more.
Think from contract before coding.
Use the smallest structure that exposes the real hardware behavior clearly.
```

RTL design translates a timing contract into hardware facts and update rules.
Do not begin by collecting `always_ff` blocks; first decide what can happen in
the current cycle, what must survive the edge, and what the outside world can
observe on each cycle.

Trace every important behavior in both directions:

```text
input condition
  -> qualified current-cycle event
  -> remembered fact or state
  -> registered update with explicit priority
  -> observable level, pulse, status, or protocol action
```

```text
observable output
  <- output origin
  <- remembered fact or state
  <- set / clear / hold rule
  <- current-cycle event
  <- input condition
```

The first trace prevents accidental hidden state; the second prevents an
output whose cycle of validity or owner is unclear.

Design flow:

```text
contract
  -> timing sketch when a cycle boundary is uncertain
  -> captured input context when inputs have pipeline/register boundaries
  -> input / events
  -> remembered facts and same-cycle priority
  -> register updates
  -> output encoding / output boundary
  -> corner-case review
```

## Timing Sketch Rule

For simple local logic, reason through the clock edge directly. For a pulse,
counter, multi-phase flow, CDC boundary, or any question of "this cycle or next
cycle", first draw a rough timing sequence in the head, a cycle table, or a
small waveform. It need not be formal documentation.

The sketch must answer:

```text
When is the request accepted?
Which edge captures context or starts a counter?
When does completion become true?
Is the output a same-cycle combinational value, a registered level, or a one-cycle pulse?
If clear, disable, abort, and done coincide, which result wins?
```

If the answer is not obvious, code is premature. Resolve the timing before
writing the sequential block; use the resulting waveform to check first/last
counter cycles, pulse width, skewed inputs, and simultaneous events.

Do not add abstraction only to match a template.

When generating module RTL, keep the code synthesizable and compact. Do not add
SYNTHESIS-guarded blocks, `initial $fatal` parameter checks, assertions, or
other sim-only guards unless the user explicitly asks for verification logic.

## RTL File Header Rule

When generating SystemVerilog RTL, keep the file header minimal.

Only include:

```text
module name
applicable scope / purpose
```

Preferred:

```systemverilog
//------------------------------------------------------------------------------
// <module_name>
//
// <one-line applicable scope / purpose>
//------------------------------------------------------------------------------
```

Avoid long overview blocks, changelogs, author/version blocks, verbose contracts, or repeated design notes unless explicitly requested.

Keep useful comments near the logic that needs them.

## When to Use

Use for RTL/control logic involving:

```text
FSM
handshake
FIFO / arbiter / queue / pipeline control
CDC / RDC
CSR-visible status
IRQ pulse or pending
timeout / abort / clear / disable
protocol sequencing
PHY direction mapping
bug analysis or RTL review
```

Do not use for pure formatting, trivial one-line edits, or simple datapath expressions.

## Design Checklist Before Coding

Identify:

1. **Job**  
   What does this logic receive, remember, and drive?

2. **Contract**  
   For each important signal, define pulse/level, owner, valid cycle, clear behavior, clock/reset domain, and observable effect.

3. **Events**  
   Name current-cycle events such as accept, consume, start, done, timeout, abort, clear.

4. **Remembered facts**  
   Register only facts that must survive a clock edge: pending, seen, sticky, saved direction, active transaction, timeout active.

5. **Priority**  
   Define same-cycle priority before coding.

   Typical priority:

   ```text
   reset
   > disable / abort / clear / kill
   > consume / complete
   > set new event
   > hold
   ```

6. **Outputs**  
   Decide whether each output comes from a current event, registered fact, state, counter, handshake, CSR sticky bit, or protocol encoding.

7. **Corner cases**  
   Check busy, stall, late input, simultaneous set/clear, timeout, abort, disable, reset release, skewed done, duplicate event, lost pulse, and cross-domain sampling.

## Naming Rules

Keep suffixes minimal. Use suffixes only when they expose timing, ownership, or CDC stage.

### Affix Compression Preference

Treat short prefixes and suffixes as a preference, not a rule. Before adding an
affix, check whether an established one to three-letter form expresses the
meaning clearly, such as `_q`, `_vld`, `_err`, `_req`, or `_ack`.

Keep longer established forms such as `_fire`, `_pending`, and `_nxt` when
they are clearer; do not invent cryptic abbreviations or rename an externally
defined port merely to meet a three-letter target. Semantic clarity, timing
meaning, and project compatibility always win over compression.

| Suffix / Pattern | Meaning | Example |
|---|---|---|
| `_i` | input port | `start_i` |
| `_o` | output port | `done_o` |
| `_q` | registered value | `status_q` |
| `_d` | next value for structured logic | `data_d` |
| `c_st/n_st` | current and next single-FSM state | `c_st`, `n_st` |
| `<scope>_c_st/<scope>_n_st` | current and next state of a named FSM | `uphy_c_st`, `uphy_n_st` |
| `_nxt` | simple candidate next value | `ptr_nxt` |
| `_fire` | qualified current-cycle event | `accept_fire` |
| `_pending` | captured unconsumed event | `req_pending_q` |
| `_sync1_q/_sync2_q` | CDC sync stages | `done_sync1_q`, `done_sync2_q` |
| `_vld` | valid qualifier or valid pulse | `data_vld` |
| `_rdy` | ready qualifier | `data_rdy` |
| `_lvl` | sustained level | `ready_lvl` |
| `_pls` | one-cycle pulse | `timeout_pls` |
| `_sty` | sticky fact held until its defined clear | `irq_sty` |
| `_err` | error level, pulse, or sticky fact | `frame_err` |
| `_req/_ack` | request and acknowledge handshake | `read_req`, `read_ack` |

### Canonical Short Forms

Prefer these established short semantic tokens inside RTL names when the
project does not mandate an external spelling:

| Meaning | Preferred token | Examples |
|---|---|---|
| clear | `clr` | `cfg_clr_pls_i`, `flow_clr_fire` |
| enable | `en` | `cfg_en_i` |
| group | `grp` | `dbg_u2d_grp0` |
| sticky | `sty` | `irq_sty` |

### Port Prefixes

Use a port prefix when it exposes the interface role, then retain the normal
semantic body and timing/direction suffix. A prefix does not replace a
meaningful `_fire`, `_lvl`, `_pls`, `_i`, or `_o` suffix.

| Prefix | Interface role | Examples |
|---|---|---|
| `cfg_` | software, strap, or integration configuration that controls behavior | `cfg_en_i`, `cfg_timeout_i`, `cfg_mode_i` |
| `dbg_` | debug, trace, or observability interface; not a functional protocol path | `dbg_state_o`, `dbg_timeout_o`, `dbg_force_i` |

Use `cfg_` for values that configure normal operation, not for a runtime
transaction request or a one-cycle protocol event. Use `dbg_` for diagnostic
visibility or explicitly debug-only overrides. A debug override must still
state its timing and direction, for example `dbg_force_i` or
`dbg_timeout_pls_i`; do not disguise a functional production control as
debug.

Rules:

- Name a single FSM's current and next state `c_st` and `n_st`. For multiple FSMs, put the semantic qualifier first: `<scope>_c_st` and `<scope>_n_st`, such as `uphy_c_st` and `uphy_n_st`. Do not use `c_<scope>_st` or `n_<scope>_st`.
- Use `_fire` for combinational current-cycle events.
- Use `_q` for registered facts.
- Use `_d` only when real next-value decode improves clarity.
- Use `_nxt` for simple candidate values such as pointer + 1.
- Use `_pending` only when an event is captured and waits to be consumed.
- Use `_sync1_q/_sync2_q` for CDC synchronizer stages.
- Use the exact short suffixes `_vld`, `_rdy`, `_err`, `_req`, and `_ack` for valid, ready, error, request, and acknowledge signals. Prefer `data_vld`, `data_rdy`, `frame_err`, `read_req`, and `read_ack`; do not expand them to `data_valid`, `data_ready`, `frame_error`, `read_request`, or `read_acknowledge`.
- Name a ready/valid pair with the same semantic root, such as `in_vld` and `in_rdy`; name its accepted transaction `in_fire = in_vld && in_rdy`.
- Prefer `_lvl` for a sustained level and `_pls` for a one-cycle pulse, such as `ready_lvl` and `timeout_pls`. Do not force-renaming an external or project-defined `*_level` / `*_pulse` interface merely to shorten it.
- Use `_sty` for a sticky fact that remains set until its defined clear, such as `irq_sty` or `dbg_timeout_sty`. Do not use `_sty` for a transient event, a live level, or a generic register.
- Treat an IRQ as a one-cycle pulse by default and name it `*_irq_pls`, such as `timeout_irq_pls`. Use `*_irq_sty` or `*_irq_pending` only when the contract explicitly requires an IRQ fact to remain asserted; do not use a bare `*_irq` name.
- Use `clr`, `en`, and `grp` rather than `clear`, `enable`, and `group` in internally owned names, such as `flow_clr_fire`, `cfg_en_i`, and `dbg_u2d_grp0`. Keep a longer external or project-defined spelling when its interface compatibility matters.
- Use `cfg_` for configuration ports and `dbg_` for debug or observability ports when those roles are part of the module interface. Keep the remaining name semantic and retain the relevant timing and direction suffix.
- Avoid `_f/_ff` for CDC; they do not show stage order.
- Prefer semantic names over suffix-heavy names.
- Do not create alias wires that add no meaning.

## Structure Rule

Use compact structure for simple logic:

```text
small counter
simple synchronizer
classic FIFO pointer logic
one-condition register update
simple pulse generation
```

Use structured logic for complex behavior:

```text
multi-state FSM
multi-register priority
pending / done-seen logic
CSR / IRQ behavior
CDC event crossing
timeout / abort / clear interaction
protocol sequencing
```

Avoid:

```text
empty input decode sections
one-condition _d logic
alias wires equal to raw inputs
comments that restate code
section headers longer than the logic
mechanical decomposition of classic structures
```

Add abstraction only if it gives clearer timing, clearer priority, safer CDC, less repeated complex logic, easier waveform debug, or fewer realistic bugs.

## Single-Pass Reading Rule

Arrange a non-trivial module so a reader can follow its hardware story without
jumping backward: captured input payload and mode context first, then
current-cycle events, remembered facts, and outputs.

```text
static helpers
  -> input context capture
  -> input / events
  -> register updates
  -> outputs / output pipeline
```

Use one short `// Flow:` comment near executable logic only when it materially
clarifies the path. Put static lookup tables and local helper functions before
that flow; place input and output pipeline boundaries beside the logic they
serve. Do not add aliases or comments to small local logic.

## Event Rule

Pull meaningful current-cycle events into named wires.

```systemverilog
assign accept_fire  = in_vld_i  && in_rdy_o;
assign consume_fire = out_vld_o && out_rdy_i;
assign timeout_fire = timeout_en_q && (timeout_cnt_q == TIMEOUT_LIMIT);
assign abort_fire   = abort_pls_i || timeout_fire;
```

Do not repeat the same complex raw condition in multiple state, counter, CSR, or IRQ blocks.

### Event Struct Rule

Use a packed event struct only when many parallel current-cycle events share
one scope, lifetime, and derivation flow, such as symmetric UPHY and DPHY
protocol events. Name the container `<scope>_evt`, such as `uphy_evt`; fields
must not repeat that scope, such as `uphy_evt.enter_fire` and
`uphy_evt.clr_fire`.

Set the struct to `'0` and derive its fields in one staged `always_comb` block
so each field remains waveform-visible and has one owner. Keep cross-scope
priority and cleanup facts separate, for example `entry_kill`,
`cl12_csr_clr_fire`, or direction-mapped IRQ facts.

Do not use an event struct for one obvious event, registered state, sticky
facts, externally defined ports, or events with different lifetimes, clear
rules, or ownership. A struct groups related facts; it must not hide their
timing contract.

## Combinational Decomposition Rule

Do not hide a multi-phase protocol decision, nested selection, or several
independent timing conditions inside one long combinational expression. Split
it into short, causal facts when each fact has its own waveform meaning, such
as a selected terminal count, elapsed timer, received condition, recovery
ready, or output owner.

```systemverilog
assign tx_last       = (tx_mode == TX_CL0S) ? cl0s_last : cl12_last;
assign tx_elapsed    = tx_cnt >= tx_last;
assign lfps_done     = lfps_seen || lfps_accept_fire;
assign tx_done_fire  = tx_on && (tx_timed ? tx_elapsed : lfps_done);
```

The final event should read like a short timing contract. Do not split a small
obvious expression or add aliases that merely restate a raw input. There is no
line-count target: split when the expression hides causality, ownership,
priority, or a waveform-debug checkpoint.

Keep fixed mathematical transforms and lookup-style logic compact when their
individual terms have no independent timing meaning, such as an LFSR
polynomial, CRC parity equation, or constant decode table. Split their
surrounding protocol selection and completion conditions instead; named facts
must reveal a real waveform checkpoint, not just shorten a line.

Keep a simple, single-meaning continuous assignment on one line. Do not wrap
an obvious comparison, ternary, conjunction, or packing expression merely to
add visual structure. Split only when the expression hides causality,
ownership, priority, or a waveform-debug checkpoint.

Within a short related group, align declarations and simple continuous
assignments by type, name, `=`, or `<=` to make comparison easy. Do not add
padding to force long or multi-stage expressions into a visual column; retain
their causal layout instead.

## Register Rule

For every important register, know:

```text
remembered fact
set condition
clear condition
hold condition
same-cycle priority
```

For obvious one-condition registers, keep this in reasoning; do not add verbose comments.

## Sequential Block Grouping Rule

Group sequential logic by fact lifetime and owner, not merely by sharing the
same clock and reset.

Good grouping:

```text
state / flow phase facts
saved type / direction / transaction facts
pending / seen / done facts
counter and timer facts
registered pulse outputs
CSR-visible status / sticky bits
debug sticky bits
```

Each `always_ff` block should answer one clear question, such as:

```text
What phase is this flow in?
What protocol fact must survive the clock edge?
Which one-cycle output pulse is emitted this cycle?
How does software-visible status set and clear?
```

Keep registers together when they share the same owner, clear condition,
lifetime, and priority. Split them when mixing them hides the hardware story or
makes waveform debug harder.

Avoid:

```text
one giant clocked block containing unrelated state, counters, pulses, CSR status, and debug bits
one always_ff per register when the registers are one coherent fact group
duplicating the same clear/start/done priority in many tiny blocks
```

Synthesis normally produces the same flops either way; this rule is about
readability, priority clarity, and reviewability.

## Priority Rule

Name shared cleanup conditions once.

```systemverilog
assign flow_kill = !en_i || abort_fire || timeout_fire;
```

Reuse shared priority conditions consistently in state, pending bits, done-seen bits, counters, CSR sticky status, IRQ generation, and outputs.

If set and clear happen in the same cycle, make the winner explicit.

## CDC Rule

Only cross clock domains with CDC-safe structures.

Allowed patterns:

```text
single-bit level sync
toggle event sync
pulse sync via toggle
gray pointer sync
req/ack handshake
async FIFO pointer sync
```

Avoid:

```text
direct multi-bit bus sync
raw pulse into another clock domain
combinational CDC paths
cross-domain payload without handshake or FIFO
```

Prefer `_sync1_q/_sync2_q` for synchronizer stages.

```systemverilog
logic done_sync1_q;
logic done_sync2_q;
```

CDC comments should state source domain, destination domain, synchronized fact, and why payload is safe or not needed.

## FIFO Rule

For async FIFO/control FIFO:

```text
binary pointers stay local
Gray pointers cross domains
payload is not synchronized bit-by-bit
full is generated in write clock domain
empty is generated in read clock domain
read data timing must be stated
```

Example contract:

```text
Write accepts data only on w_push_fire = w_en_i && !w_full_o.
Read consumes data only on r_pop_fire = r_en_i && !r_empty_o.
r_data_o updates on r_pop_fire; not FWFT unless explicitly stated.
Cross-domain flow control synchronizes Gray pointers only.
```

For dual-clock memory arrays, note that the RTL models dual-clock RAM and may need FPGA/foundry RAM macro replacement.

Do not over-structure classic FIFO code.

## CSR / IRQ Rule

CSR-visible status must be clearly one of:

```text
live level
sticky bit
write-1-clear sticky bit
read-clear sticky bit
IRQ pending
```

For sticky status:

```text
event domain sets the fact
software/CSR clear removes it
clear priority must be explicit
CDC must be handled before CSR sampling
```

If CSR clock differs from event clock, do not directly synchronize a multi-bit status bus.

## Reset Rule

Keep async reset branches dedicated to reset values.

Good:

```systemverilog
always_ff @(posedge clk_i or negedge rst_n_i) begin
  if (!rst_n_i) begin
    c_st <= S_IDLE;
  end else if (flow_kill) begin
    c_st <= S_IDLE;
  end else begin
    c_st <= n_st;
  end
end
```

Bad:

```systemverilog
always_ff @(posedge clk_i or negedge rst_n_i) begin
  if (!rst_n_i || flow_kill) begin
    c_st <= S_IDLE;
  end else begin
    c_st <= n_st;
  end
end
```

Do not mix functional clear, abort cleanup, phase-exit cleanup, software clear, or context cleanup into async reset condition.

## Direction Mapping Rule

When physical side and logical direction differ, expose the mapping with named wires.

```systemverilog
// DPHY_RX observes downstream-side abort, which maps to U2D logical flow.
assign u2d_abort_fire = dphy_abort_fire;

// UPHY_RX observes upstream-side abort, which maps to D2U logical flow.
assign d2u_abort_fire = uphy_abort_fire;
```

Do not hide direction swaps inside sequential assignments.

## Comment Rule

Use comments sparingly.

Good comments explain:

```text
intent
contract
priority reason
CDC safety
non-obvious protocol behavior
```

Bad comments restate the code.

Avoid large section headers and large file headers.

## Final Check

Before finishing, check:

1. Is the contract clear?
2. Are current-cycle events named?
3. Are remembered facts stored in `_q` registers?
4. Is same-cycle priority explicit?
5. Are pulse/level behaviors clear from contract or names?
6. Are CDC crossings safe?
7. Are CSR sticky/live/IRQ behaviors separated?
8. Are async FIFO pointers/payload handled safely?
9. Are reset and functional clear separated?
10. Are sequential blocks grouped by fact lifetime and owner instead of one unrelated giant block?
11. Can a waveform follow input -> event -> fact/state -> output?
12. Does the code handle busy, stall, timeout, abort, clear, disable, and simultaneous events?
13. Are multi-phase combinational decisions decomposed into short, named facts without adding meaningless aliases?
14. If an event struct is used, does it contain only same-scope current-cycle events with one staged combinational owner?
15. Can any abstraction, alias, comment, or section header be removed without losing clarity?
