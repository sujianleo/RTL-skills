## Contents

1. Policy-first questions
2. Five-essential arbiter model
3. State selection
4. Behavioral derivation order
5. Grant timing patterns
6. Checks before finishing

## Policy-First Questions

State these items before writing RTL:

- Is the arbiter fixed-priority, round-robin, weighted, or masked priority?
- Is the grant combinational or registered?
- Can the winner change while the current transfer is stalled?
- Is fairness required, or is deterministic priority sufficient?
- Does the downstream interface use `valid/ready` semantics?

If the policy is not explicit, do not guess silently. State the chosen policy in comments and derive the rest from it.

## Five-Essential Arbiter Model

| Core | Arbiter Question | Typical RTL |
|---|---|---|
| Fact | What fairness or ownership fact survives? | last grant pointer, locked grant, outstanding owner |
| Event | When is a grant accepted or retired? | `grant_fire`, `release_fire`, request valid |
| Priority | Does held grant, new request, or rotation win? | lock/hold before new search, reset pointer rule |
| Boundary | What if request drops, downstream stalls, or pointer wraps? | hold grant, mask/rotate, wrap search |
| Contract | Is grant combinational, registered, held until accept, or one-cycle? | request/grant/ready handshake rule |

## State Selection

The minimal state usually includes:

- Current grant or winner index
- Rotation pointer or last-served index for round-robin
- Optional lock state if a granted transaction must remain selected until completion

Each state element should answer one question only:

- Who won last?
- Who is allowed to win next?
- Am I locked to the current requester?

## Behavioral Derivation Order

Derive arbiter logic in this order:

1. Define contract: combinational grant, registered grant, or held grant until accept.
2. Define events: request eligible, grant selected, grant accepted, owner released.
3. List facts: current owner, rotation pointer, lock/hold state.
4. Set priority: reset, held owner, completion/advance, new winner, hold.
5. Check boundaries: no request, one request, multiple request, downstream stall, pointer wrap.

For each register, define set/clear/hold:

- Grant register updates when a new winner is chosen
- Rotation pointer updates only when policy says service completed
- Lock bit sets when a multi-cycle ownership window begins
- Lock bit clears when the ownership window ends

## Grant Timing Patterns

### Combinational Grant

Use when latency matters and timing is easy enough:

- Grant is a pure function of requests and current policy state
- Re-check for combinational loops if grant feeds ready signals upstream

### Registered Grant

Use when backpressure and timing closure matter:

- Grant becomes stable for a cycle
- Easier to reason about with downstream stall handling
- Often pairs better with per-request `ready` generation

### With `valid/ready`

For handshake arbiters, derive in this order:

1. Which requesters are eligible
2. Which eligible requester wins
3. Whether the selected winner must remain held during stall
4. When the arbiter may advance to the next winner

Never rotate on request appearance alone if the interface contract requires service completion first.

## Checks Before Finishing

Verify these scenarios:

1. No requester active
2. Single requester active for many cycles
3. Multiple simultaneous requests
4. Highest-priority requester toggles on and off
5. Downstream stall while a request is granted
6. Round-robin pointer wrap
7. Fairness over long repeated contention

If the user asks for readability:

- Keep policy explanation near the top of the file
- Name helper signals after policy events such as `grant_fire`, `hold_grant`, `advance_ptr`
- Avoid burying fairness rules inside long chained ternaries
