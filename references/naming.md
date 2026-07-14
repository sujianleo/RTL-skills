# RTL Naming

## Project Precedence

Preserve existing public ports and repository conventions unless the user asks
for an interface change. Use these defaults only for internally owned or
greenfield names.

## Core Forms

| Form | Meaning | Example |
|---|---|---|
| no suffix | ordinary internal fact/register | `busy`, `baud_cnt` |
| `c_st/n_st` | current/next state of one FSM | `c_st`, `n_st` |
| `<scope>_c_st/<scope>_n_st` | named FSM pair | `uphy_c_st`, `uphy_n_st` |
| `_nxt` | simple candidate next value | `ptr_nxt` |
| `_fire` | qualified current-cycle event | `accept_fire` |
| `_pending` | captured unconsumed event | `req_pending` |
| `_q/_q2` | CDC synchronizer stages | `done_q`, `done_q2` |
| `_vld/_rdy` | valid/ready handshake | `data_vld`, `data_rdy` |
| `_lvl/_pls` | sustained level / one-cycle pulse | `busy_lvl`, `done_pls` |
| `_sty` | sticky fact until defined clear | `timeout_sty` |
| `_err` | error fact with contract-defined lifetime | `frame_err` |
| `_req/_ack` | request/acknowledge | `read_req`, `read_ack` |

## Rules

- Use the shortest semantic name that remains unambiguous.
- Add `_i/_o` only when required by project style or needed to make a public
  direction clear. Do not rename a compatible external interface for style.
- Use `c_st/n_st` for one FSM. Put the qualifier before `c_st/n_st` for
  multiple FSMs. Do not use `c_<scope>_st`, `n_<scope>_st`,
  `state_q/state_d`, or `c_state/n_state`.
- Reserve `_q/_q2` for CDC stages. Do not mark ordinary registers with `_q`.
- Use `_nxt` for simple candidate values such as pointer increment; do not use
  it for FSM state.
- Use `_fire` only for a meaningful qualified event, especially a handshake
  or a fact reused by multiple register groups.
- Use `_pending` only when the event waits to be consumed. Avoid stacked names
  such as `req_pending_q`.
- Use exact short forms `_vld`, `_rdy`, `_err`, `_req`, and `_ack`; do not
  expand internally owned names to `valid`, `ready`, `error`, `request`, or
  `acknowledge` unless a public interface requires it.
- Use `_lvl` for sustained levels and `_pls` for one-cycle pulses. Keep
  project-defined `*_level_i/o` and `*_pulse_i/o` unchanged.
- Use `_sty` only for a sticky fact with a defined clear.
- Prefer `clr`, `en`, and `grp` in internally owned names.
- Avoid `_prev`. Keep a previous-value register only when the contract truly
  requires edge detection and state/level qualification cannot express it.
- Avoid `reg_`, `r_`, `wire_`, `w_`, and redundant `in_/out_` prefixes.
- Avoid cryptic abbreviations merely to force every affix below three letters.

## IRQ Naming

Determine IRQ lifetime from the interface contract before naming or coding it:

- one-cycle event: `*_irq_pls`
- latched unserviced interrupt: `*_irq_pending`
- sticky software-visible interrupt fact: `*_irq_sty`
- project-defined sustained line: keep the project name and document its clear

Do not default an unknown IRQ to a pulse. Keep an internal event pulse separate
from a pending/sticky interrupt when both exist.

## Interface Prefixes

- Use `cfg_` for software, strap, or integration configuration that controls
  normal operation, such as `cfg_en_i` or `cfg_mode_i`.
- Use `dbg_` for debug, trace, observability, or explicitly debug-only
  overrides, such as `dbg_state_o` or `dbg_force_i`.
- Do not disguise a runtime protocol request as `cfg_` or a functional
  production control as `dbg_`.
- Retain timing and direction meaning after the prefix, such as
  `dbg_timeout_pls_i`.

## Alignment

Align short related declarations and assignments by type, signal name, `=`, or
`<=` when it improves comparison. Do not add large padding or distort causal
expressions to force visual columns.
