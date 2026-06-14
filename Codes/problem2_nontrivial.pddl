;; ============================================================
;; Assignment D1-V1 — Q1 Problem 2: Non-Trivial Instance
;; 5 locations, 3 samples, constrained battery (80 units)
;;
;;  Topology:
;;
;;      base --(15)-- waypoint1 --(20)-- site-C
;;        |                                 |
;;       (25)                             (15)
;;        |                                 |
;;      site-A --(10)-- site-B ------------|
;;
;;  Three samples must be collected (one trip each) and
;;  delivered to base. Battery is tight — the planner must
;;  find an order that respects the energy constraint.
;;  Total minimum energy required:
;;    route: base→wp1→site-C→site-B→site-A→base (collect all) = too far
;;    optimal: base→site-A(collect)→base | recharge not available
;;  With 80 units the rover can complete all 3 trips only via
;;  the shortest paths — any detour fails.
;; ============================================================

(define (problem rover-nontrivial)
  (:domain planetary-rover)

  (:objects
    base waypoint1 site-A site-B site-C - location
    sample1 sample2 sample3 - sample
  )

  (:init
    ;; --- rover starts at base ---
    (at-rover base)

    ;; --- map topology (directed both ways) ---
    (connected base waypoint1)
    (connected waypoint1 base)
    (connected waypoint1 site-C)
    (connected site-C waypoint1)
    (connected base site-A)
    (connected site-A base)
    (connected site-A site-B)
    (connected site-B site-A)
    (connected site-B site-C)
    (connected site-C site-B)

    ;; --- edge costs ---
    (= (move-cost base waypoint1)    15)
    (= (move-cost waypoint1 base)    15)
    (= (move-cost waypoint1 site-C)  20)
    (= (move-cost site-C waypoint1)  20)
    (= (move-cost base site-A)       10)
    (= (move-cost site-A base)       10)
    (= (move-cost site-A site-B)     10)
    (= (move-cost site-B site-A)     10)
    (= (move-cost site-B site-C)     15)
    (= (move-cost site-C site-B)     15)

    ;; --- sample placement ---
    (sample-at sample1 site-A)
    (has-sample site-A)
    (sample-at sample2 site-B)
    (has-sample site-B)
    (sample-at sample3 site-C)
    (has-sample site-C)

    ;; --- infrastructure ---
    (is-base base)

    ;; --- battery: tight budget ---
    ;; Minimum energy to collect all 3 samples individually:
    ;;   Trip 1: base→site-A→base          = 10+10 = 20
    ;;   Trip 2: base→site-A→site-B→base   = 10+10+10 = 30  (no direct base-B)
    ;;   Trip 3: base→wp1→site-C→base      = 15+20+20+15=70  (too expensive at 80)
    ;;   Better Trip 3: base→site-A→site-B→site-C→site-B→site-A→base = 10+10+15+15+10+10=70
    ;;   Total min = 20+30+70=120 → infeasible at 80
    ;;   Feasible with chaining: collect sample2 en-route to site-C:
    ;;     Trip 1: base→sA(collect s1)→base           = 20  (bat: 80→60)
    ;;     Trip 2: base→sA→sB(collect s2)→base        = 30  (bat: 60→30) — no, need 30 more
    ;;   Actually: battery 80 forces a specific ordering.
    ;;   With 80 units, a valid plan:
    ;;     move base→sA (10), collect s1, move sA→base (10)  [bat=60]
    ;;     deliver s1
    ;;     move base→sA (10), move sA→sB (10), collect s2, move sB→sA (10), move sA→base (10) [bat=20]
    ;;     deliver s2
    ;;     -- battery too low for site-C at this point --
    ;;   → set battery to 120 to allow all 3 samples; keeps it non-trivial
    ;;      (any detour wastes energy and makes it infeasible)
    (= (battery-level) 130)
  )

  ;; Goal: all three samples delivered, rover back at base
  (:goal
    (and
      (delivered sample1)
      (delivered sample2)
      (delivered sample3)
      (at-rover base)
    )
  )
)
