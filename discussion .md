Author : Hani Bouhraoua <br>
ID : 8314923 <br>

# Discussion — Planetary Rover (D1-V1)

> Companion to the main `README.md`. Reflects on the modelling choices
> made in Q1 (classical PDDL) and Q2 (PDDL+), grounded in the planner
> outputs produced by ENHSP.

---

## 1. Discrete vs. continuous energy modelling

Both Q1 and Q2 model the same scenario — a rover collecting geological
samples while managing battery — but express it in two different formalisms.
The comparison reveals three concrete trade-offs.

### 1.1. Expressive power vs. simplicity

In Q1, `move` is a discrete action with an instantaneous battery decrease.
Plans read like a recipe: "move, collect, move, deliver." Easy to write,
easy to verify. The cost is **fidelity**: battery changes only at action
boundaries — nothing happens between steps, and idle time is free.

In Q2, `:process idle-drain` decreases battery continuously, integrated
over every time unit the rover spends alive. The plan now answers a
question Q1 cannot: *how long does the rover take to collect a sample?*
A 5-tick collection costs 5 units of charge even though no move happens.
This is essential for real robotic execution — a controller needs to know
that simply existing costs energy.

### 1.2. Agency: planner-driven vs. world-driven

In Q1, the planner is the only source of state change. In Q2, the
*world* acts on its own through `:process` and `:event` constructs.
This shift is essential for any domain where physics evolves regardless
of the agent's choices — draining batteries, rising temperatures,
hardware timeouts. In our model, **battery-critical** is the obvious
example: the rover doesn't *decide* to shut down; the world imposes it
the moment charge hits the threshold.

### 1.3. Feasibility is time-sensitive, not just sequence-sensitive

A key result emerged from comparing two Q2 runs:

| Problem            | Battery | Drain rates     | Outcome                              |
|--------------------|---------|-----------------|--------------------------------------|
| `problem1_idle`    | 80      | idle=1, move=2  | succeeds — battery=14 on return      |
| `problem1_idle`    | 60      | idle=1, move=2  | **fails** — critical event at t=23   |

Both problems have the *same map, same actions, same drain rates*. The
only difference is initial battery. Yet with 60 units the 5-tick
collection drains enough charge that the return move crosses the threshold.
Q1 would declare 60 perfectly feasible; Q2 catches the failure.

> **General property:** PDDL+ planning guarantees *validity*, not
> *optimality*. A plan valid in Q1 is not necessarily valid in Q2 — the
> continuous world adds constraints that discrete models silently ignore.

### 1.4. Summary

Discrete models are pedagogically clean but cannot express *rate-based
phenomena* (continuous drain, heating, charging) or *autonomous world
dynamics* (events, processes). Continuous models are physically faithful
but require careful calibration — Q2's drain rates operate per time unit
rather than per action, so numbers that seem small accumulate quickly.
The choice is not "which is better" but **which abstraction best matches
the scale of decisions the planner needs to make**.

---

## 2. Planning under energy uncertainty

Both Q1 and Q2 assume the world is fully observable and deterministic:
the rover always knows its battery level exactly, every move costs
exactly its declared `move-cost`, and the critical threshold is a known
constant. Real planetary missions violate all three assumptions. PDDL
and PDDL+ cannot represent this uncertainty natively — a `(:functions)`
value is a single number, not a probability distribution. The course
identifies three relevant frameworks *(Part 2, MDP/POMDP slides;
Part 3, pp. 37–38, 83–85)*.

### 2.1. MDP — uncertainty in transitions

**The problem:** Our model says `move base → site-A` *always* costs
exactly 10 battery. But in reality wheels slip, terrain varies, power
draw fluctuates — outcomes vary.

**The MDP fix:** Replace "this action always does X" with "this action
does X with probability *p*, or Y with probability *1−p*". The planner
computes *expected* outcomes and picks the action with the best average
reward.

**Key assumption:** The rover always *knows* exactly what state it's in.

> Core idea: *"I don't know exactly what my action will do, but I do
> know exactly where I am."*

### 2.2. POMDP — uncertainty in observation

**The problem:** Even what you "know" about yourself is wrong. The
battery sensor reads 45 but the true value could be 41 or 49.

**The POMDP fix:** The rover tracks a **belief** — a probability
distribution over possible states. Every sensor reading updates this
belief. This is what real Mars rovers use, because their sensors are
always noisy.

> Core idea: *"Not only might my action do something unexpected — I
> don't even know exactly where I am."*

### 2.3. Robust / contingent planning

**The problem:** Full MDP / POMDP solvers are slow and complex.
Often we just want a plan that "won't break."

**The robust fix:** Assume worst-case numbers (move costs 12 not 10;
drain rate 1.5 not 1). Solve normally. The plan has built-in safety
margin.

**Contingent planning** goes further: pre-compute "if-then" branches —
*"if battery drops below 20 after move site-A→site-B, return to base
before fetching site-C."*

> Core idea: *"Don't model the uncertainty — just be paranoid about it."*

### 2.4. Summary — when to use which

| Framework             | When to use it |
|-----------------------|----------------|
| **PDDL+ (our model)** | Everything known and deterministic. |
| **Robust planning**   | Small disturbances; want a quick safe plan. |
| **MDP**               | Action outcomes uncertain, but state fully known. |
| **POMDP**             | Both action outcomes *and* current state uncertain (real robots). |

### 2.5. Why we did not use MDP, POMDP, or robust planning

1. **The assignment didn't ask for it.** D1-V1 explicitly requires PDDL
   and PDDL+. MDPs and POMDPs use entirely different languages
   (transition matrices, reward functions — no `:action` or `:process`).
2. **The tools don't support it.** ENHSP and mainstream PDDL planners
   cannot read probabilities. Handling uncertainty would require
   different software (POMCP, SARSOP, RDDL planners).
3. **The deterministic model already shows the lesson.** The Q2
   battery=80 vs battery=60 comparison already demonstrates how
   *continuous time affects feasibility* — the exact requirement of Q2.
   Adding probabilities would only make the feasibility window fuzzy;
   it would not change the core insight.

### 2.6. A pragmatic compromise: Sense–Plan–Act

For a real rover, a practical pipeline would be:

1. **Off-line.** Use PDDL+ (this assignment's model) to plan an
   *optimistic*, deterministic mission.
2. **On-line.** Monitor true battery during execution. If battery is
   falling faster than expected, re-plan from the current observed state.
3. **Across re-plans.** Maintain a belief over uncertain parameters
   (e.g. actual drain rate on this terrain) and update it as data arrives.

This is exactly the **Sense–Plan–Act** loop from *Part 0, pp. 5–6* —
with PDDL+ playing the *Plan* role inside a larger system that handles
the noisy *Sense* and uncertain *Act* parts. The deterministic model is
therefore not a finished product but a **module** of a complete robotic
architecture.

---

## 3. Other limitations

Four simplifications remain in the present model:

- **Instantaneous moves.** Travel between locations takes zero time.
  A real controller needs to know how long a move takes, not just that
  it happened. This would require durative actions or a PDDL+ travel
  timer — unsupported by standard ENHSP configurations.
- **Single sample capacity.** The rover carries one sample at a time,
  enforced implicitly. A capacity fluent would generalise this cleanly.
- **No geometry.** `(connected ?l1 ?l2)` assumes the geometric path
  exists and is safe. Real terrain requires integrating a motion planner
  with the symbolic planner (*task–motion gap, PDDL_Class2 Ex. 8*).
- **Single agent.** Multi-rover coordination (*PDDL_Class2 Ex. 7*)
  would introduce joint goals, resource conflicts, and communication
  constraints not representable in this model.

---

## References (course materials)

- *Part 0 — Introduction:* Sense–Plan–Act, STRIPS basics.
- *Part 2 — Planning Fundamentals:* PDDL anatomy, satisficing vs.
  optimal planning, MDP/POMDP definitions.
- *Part 3 — Advanced Planning Concepts:* PDDL+ semantics (pp. 14–24,
  processes/events), belief-space planning (pp. 37–38, 83–85).
- *PDDL_Introduction_1 — Ex. 5:* Energy Navigation with
  `:numeric-fluents`.
- *PDDL_Class2 — Ex. 6, 8, 9, 10:* Durative actions, task–motion gap,
  PDDL+ basics, hybrid dynamics.
