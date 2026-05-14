# Arbiter Design

## Contents

1. Policy-first questions
2. State selection
3. Behavioral derivation order
4. Grant timing patterns
5. Checks before finishing

## Policy-First Questions

State these items before writing RTL:

- Is the arbiter fixed-priority, round-robin, weighted, or masked priority?
- Is the grant combinational or registered?
- Can the winner change while the current transfer is stalled?
- Is fairness required, or is deterministic priority sufficient?
- Does the downstream interface use `valid/ready` semantics?

If the policy is not explicit, do not guess silently. State the chosen policy in comments and derive the rest from it.

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

1. No requests active
2. One request active
3. Multiple requests active
4. Downstream stall while a grant is present
5. Grant completion and winner rotation

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
