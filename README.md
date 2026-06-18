# D1-V1 · Planetary Rover — Single Rover, Static Environment

**Author:** Amri Abdelouafi &nbsp;|&nbsp; **ID:** S7708121
**Course:** AI4Ro2 — Artificial Intelligence for Robotics 2 · UniGe · 2025-26
**Planner:** ENHSP (`-planner sat-hadd`)

---

## What files to run

| Model | Domain | Problems |
|-------|--------|----------|
| Q1 — Classical PDDL | `codes/q1/domain.pddl` | `problem1_simple.pddl` · `problem2_nontrivial.pddl` |
| Q2 — PDDL+ | `codes/q2/domain_plus.pddl` | `problem1_idle.pddl` · `problem2_timing.pddl` |

---

## The problem

A wheeled rover must visit locations on a planetary surface, collect geological
samples, and bring them back to base — all without exceeding its battery capacity.
No obstacles appear or disappear. The full graph is known before planning starts.

```
  base ──(10)──► site-A ──(10)──► site-B
    │                                  │
   (10)                              (15)
    ▼                                  ▼
  site-A ◄──────────────────────── site-C
              (via waypoint1: 15+20)
```

One sample per site. Rover carries one at a time. Must return to base after each.

**Objects:** `location`, `sample`
**Predicates:** `at-rover` · `connected` · `sample-at` · `carrying` · `delivered` · `is-base`
**Fluents:** `battery-level` · `move-cost`

---

## Q1 — Classical PDDL

Battery is a numeric fluent. `move` checks `(>= battery-level move-cost)` before
executing and decreases battery on success. `collect-sample` and `deliver-sample`
handle the task cycle with no energy cost.

**Why this choice:** encoding battery as a precondition (not a goal flag) means
the planner genuinely cannot skip the constraint — it must route around it.

| Problem | Initial battery | Steps | What happens |
|---------|----------------|-------|--------------|
| `problem1_simple.pddl` | 60 | 4 | 1 sample, trivial round-trip |
| `problem2_nontrivial.pddl` | 130 | 16 | 3 samples — planner finds optimal routing across 3 trips |

---

## Q2 — PDDL+

Three new constructs replace the static battery model:

**`idle-drain` (process)** — runs at all times:
```
(decrease (battery-level) (* #t (idle-drain-rate)))
```

**`move-drain` (process)** — runs only while `rover-active` is true:
```
(decrease (battery-level) (* #t (move-drain-rate)))
```

**`battery-critical` (event)** — world-triggered, not planner-triggered:
```
when battery ≤ threshold → (not (system-ok)) → all actions blocked
```

The processes and the event coordinate through `(system-ok)` — there is no
explicit link between them. Drain rates are per-time-unit, not per-action.

| Problem | Battery | What it shows |
|---------|---------|---------------|
| `problem1_idle.pddl` | 80 | Continuous drain active — system-ok gates all actions |
| `problem2_timing.pddl` | 80 | 2 samples, planner picks optimal trip order to stay above threshold |

---

## How to run

```bash
# Q1
java -jar ~/ENHSP-Public/enhsp.jar \
  -o codes/q1/domain.pddl -f codes/q1/problem1_simple.pddl -planner sat-hadd

java -jar ~/ENHSP-Public/enhsp.jar \
  -o codes/q1/domain.pddl -f codes/q1/problem2_nontrivial.pddl -planner sat-hadd

# Q2
java -jar ~/ENHSP-Public/enhsp.jar \
  -o codes/q2/domain_plus.pddl -f codes/q2/problem1_idle.pddl -planner sat-hadd

java -jar ~/ENHSP-Public/enhsp.jar \
  -o codes/q2/domain_plus.pddl -f codes/q2/problem2_timing.pddl -planner sat-hadd
```

Save output: append `> codes/output/NAME.txt 2>&1` to any command above.
Pre-recorded outputs for all four problems are in `codes/output/`.

---

## Limitations

- Moves are instantaneous — no travel time modelled
- No terrain geometry — `connected` is purely symbolic
- Battery strictly decreases — no solar or RTG recharging
- Single agent, fully deterministic — no uncertainty, no multi-rover coordination
- Linear drain only — real degradation curves with temperature and age

---

## Repo layout

```
├── README.md
├── discussion.md
├── report/    report.pdf
├── slides/    Rover_D1V1_Presentation.pptx
└── codes/
    ├── q1/        domain.pddl · problem1_simple.pddl · problem2_nontrivial.pddl
    ├── q2/        domain_plus.pddl · problem1_idle.pddl · problem2_timing.pddl
    └── output/    one .txt per problem
```
