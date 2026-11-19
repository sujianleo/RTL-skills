# RTL Naming

Use the shortest unambiguous name. Apply these defaults to new or internally
owned names and follow the project's public interface conventions.

| Form | Meaning | Example |
|---|---|---|
| `i_<name>`, `o_<name>` | Ordinary input and output ports | `i_data_vld`, `o_done_pls` |
| `cfg_<name>` | Configuration that controls normal operation | `cfg_en`, `cfg_mode` |
| `dbg_<name>` | Debug, trace, observability, or debug-only override | `dbg_force`, `dbg_state` |
| No register suffix | Ordinary internal fact or register | `busy`, `baud_cnt` |
| `c_st/n_st` | Current and next state of one FSM | `c_st`, `n_st` |
| `<scope>_c_st/<scope>_n_st` | Current and next state of a named FSM | `rx_c_st`, `rx_n_st` |
| `_nxt` | Candidate next value outside an FSM | `ptr_nxt` |
| `_pos/_neg` | Sampled rising and falling transitions | `scl_pos`, `scl_neg` |
| `_fire` | Qualified current-cycle event | `accept_fire` |
| `_pending` | Captured event awaiting consumption | `req_pending` |
| `_q/_q2` | Reserved for CDC synchronizer stages | `done_q`, `done_q2` |
| `_vld/_rdy` | Valid and ready | `data_vld`, `data_rdy` |
| `_lvl/_pls` | Sustained level and one-cycle pulse | `busy_lvl`, `done_pls` |
| `_sty` | Sticky fact with a defined clear | `timeout_sty` |
| `_err` | Error with a contract-defined lifetime | `frame_err` |
| `_req/_ack` | Request and acknowledgement | `read_req`, `read_ack` |

Put direction first for ordinary ports. For `cfg_` and `dbg_` ports, the
port declaration gives the direction and the name still shows timing when
relevant, as in `dbg_timeout_pls`. Reserve these prefixes for their actual
roles. Runtime requests and normal production control use ordinary names.

Prefer `clr`, `en`, and `grp`. Avoid `_prev`, `reg_`, `r_`, `wire_`,
`w_`, and needless stacked suffixes. Keep symmetric paths parallel. Use the
table's short forms without forcing a fixed abbreviation length.

Match the IRQ name to the specified lifetime. Use `*_irq_pls` for a one-cycle
event, `*_irq_pending` for an unserviced interrupt, and `*_irq_sty` for a
sticky software-visible fact. Use the project's name for a sustained IRQ line.
