> **FILES TO CHECK (final / correct):**
> **PDDL (Q1)** → `codes/q1/domain.pddl` with `problem1_simple.pddl` (battery comfortable) and `problem2_nontrivial.pddl` (battery exact minimum).
> **PDDL+ (Q2)** → `codes/q2/domain_plus.pddl` with `problem1_idle.pddl` (idle drain decides feasibility) and `problem2_timing.pddl` (trip order decides feasibility).

Author: Hani Bouhraoua &nbsp;|&nbsp; ID: 8314923

---

# Planetary Rover — Single Rover, Static Environment (PDDL / PDDL+)

> Assignment **D1-V1** — *Artificial Intelligence for Robotics 2 (AI4Ro2)*
> A wheeled rover collects geological samples on a static planetary surface
> while managing a limited battery budget.
> **Planner:** ENHSP, run with `-planner sat-hadd`.

---

## Scenario

A single rover starts at a base station and must collect geological samples
from target locations and return them to base. Every move consumes battery;
capacity is fixed and cannot be exceeded. The environment is fully static —
all locations and connections are known in advance.

The model uses two object types — `location` and `sample`. Everything else
is a **predicate** (`at-rover`, `connected`, `sample-at`, `carrying`,
`delivered`, `is-base`) or a **numeric fluent** (`battery-level`,
`move-cost`).

The split `battery-level` (resource) vs `move-cost` (consumption per edge)
satisfies *"distinguish navigation from energy"* and *"battery as a hard
numeric constraint"*.

## Map (directional, used by both Q1 and Q2)

```
  base ──(10)──► site-A ──(10)──► site-B
    │                                 │
   (10)                             (15)
    ▼                                 ▼
  site-A                           site-C
```

`base→site-A` (10), `site-A→site-B` (10), `site-B→site-C` (15).
Shortest path to site-C: `base→site-A→site-B→site-C` = 35 units.
Samples at site-A, site-B, site-C. Rover must return to base after each.

---

## Q1 — Classical PDDL (`codes/q1/`)

Two key actions: **`move`** (precondition `(>= battery-level move-cost)`,
decreases battery) and **`collect-sample`** / **`deliver-sample`** (no
energy cost — instrument draw abstracted away).

| Problem | Battery | Result |
|---------|---------|--------|
| `problem1_simple.pddl`     | 60  | 4 steps, **1 sample** — battery comfortable, trivial plan |
| `problem2_nontrivial.pddl` | 130 | 18 steps, **3 samples** — exact minimum, any detour fails |

The only difference is initial battery and number of samples: same domain,
completely different plan length → **energy genuinely influences planning**.

---

## Q2 — PDDL+ (`codes/q2/`)

Battery drain becomes **continuous**, and a safety cutoff becomes an **event**:

| Construct | Behaviour |
|-----------|-----------|
| `:process idle-drain`     | always active — `battery -= (* #t idle-drain-rate)` |
| `:process move-drain`     | while `rover-active` — `battery -= (* #t move-drain-rate)` |
| `:event battery-critical` | when `battery ≤ threshold` → `(not system-ok)`, all actions blocked |

`idle-drain` and `battery-critical` are **not linked explicitly** — they
coordinate through the shared `(system-ok)` fact. Drain rates are
continuous (per time unit) vs Q1's discrete per-move costs.

Two cases, varying only battery and drain rates, show timing drives feasibility:

| File | Battery | Outcome |
|------|---------|---------|
| `problem1_idle.pddl`   | 80 (60 fails) | idle drain during 5-tick collection is the deciding factor |
| `problem2_timing.pddl` | 310           | wrong trip order exhausts battery before second sample |

---

## How to Run (ENHSP)

Path to the planner jar shown as `~/ENHSP-Public/enhsp.jar`
(adjust if yours differs).

```bash
# Q1
java -jar ~/ENHSP-Public/enhsp.jar -o codes/q1/domain.pddl -f codes/q1/problem1_simple.pddl -planner sat-hadd
java -jar ~/ENHSP-Public/enhsp.jar -o codes/q1/domain.pddl -f codes/q1/problem2_nontrivial.pddl -planner sat-hadd

# Q2
java -jar ~/ENHSP-Public/enhsp.jar -o codes/q2/domain_plus.pddl -f codes/q2/problem1_idle.pddl -planner sat-hadd
java -jar ~/ENHSP-Public/enhsp.jar -o codes/q2/domain_plus.pddl -f codes/q2/problem2_timing.pddl -planner sat-hadd
```

To save output to a file, append `> codes/output/NAME.txt 2>&1`
(create folder first with `mkdir -p codes/output`).
Recorded outputs for every problem are in `codes/output/`.

---

## Limitations

- **Instantaneous moves** — travel time not modelled (no durative actions).
- **No geometry** — locations are symbolic; real terrain and obstacles absent.
- **No uncertainty** — deterministic model; real rovers need MDP/POMDP.
- **No recharge** — battery strictly decreasing; solar charging not modelled.
- **Linear drain only** — real battery degradation is non-linear.

---

## Repository Layout

```
.
├── README.md
├── report/   report.pdf            (1-page summary)
├── slides/   Rover_D1V1_Presentation.pptx
└── codes/
    ├── q1/       Q1 — Classical PDDL
    ├── q2/       Q2 — PDDL+
    └── output/   recorded planner outputs
```
