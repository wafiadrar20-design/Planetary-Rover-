;; ============================================================
;; Assignment D1-V1 — Q2 Problem 2: Timing of Actions Matters
;;
;; 4 locations, 2 samples. The rover must choose WHEN to act
;; because idle drain accumulates between actions.
;; A plan that "wastes" time at waypoint1 will fail
;; even if the total move cost is the same.
;;
;; Map:
;;   base --(8)--> waypoint1 --(12)--> site-B
;;                     |
;;                    (8)
;;                     ↓
;;                   site-A
;;
;; Rates: idle=1, move=3, threshold=5
;; Battery=100
;;
;; Plan A (good — direct routes):
;;   move base→wp1 (dur=8): drain=(1+3)*8=32   bat=68
;;   move wp1→sA  (dur=8): drain=32            bat=36
;;   collect s1   (dur=5): drain=1*5=5          bat=31
;;   move sA→wp1  (dur=8): drain=32             bat=-1  ← FAIL
;;
;; Correct plan: rover must go to sA first (closer), collect,
;; then proceed to sB, collecting en route, then return.
;; The planner must find a sequence where idle time is minimised.
;;
;; Specifically with battery=140:
;;   base→wp1(8): -32 → 108
;;   wp1→sA(8):   -32 → 76
;;   collect s1(5): -5 → 71
;;   sA→wp1(8):   -32 → 39
;;   wp1→sB(12):  -48 → -9  ← FAIL
;;
;; The planner must find: collect s1, deliver, then get s2
;; i.e., the ORDER matters; going for s2 first might waste battery.
;; Battery=180 allows the round trip but forces correct ordering.
;; ============================================================

(define (problem rover-plus-timing)
  (:domain planetary-rover-plus)

  (:objects
    base waypoint1 site-A site-B - location
    sample1 sample2 - sample
  )

  (:init
    (at-rover base)
    (system-ok)

    ;; Topology
    (connected base waypoint1)    (connected waypoint1 base)
    (connected waypoint1 site-A)  (connected site-A waypoint1)
    (connected waypoint1 site-B)  (connected site-B waypoint1)

    ;; Move costs (= durations in PDDL+)
    (= (move-cost base waypoint1)    8)
    (= (move-cost waypoint1 base)    8)
    (= (move-cost waypoint1 site-A)  8)
    (= (move-cost site-A waypoint1)  8)
    (= (move-cost waypoint1 site-B) 12)
    (= (move-cost site-B waypoint1) 12)

    ;; Samples
    (sample-at sample1 site-A)
    (has-sample site-A)
    (sample-at sample2 site-B)
    (has-sample site-B)

    (is-base base)

    ;; Drain rates: aggressive to make timing critical
    (= (idle-drain-rate)   1)
    (= (move-drain-rate)   3)    ;; total 4/t while moving

    (= (critical-threshold) 5)

    ;; Battery: 180 allows mission if ordered correctly
    ;; Optimal plan (deliver s1 first, then fetch s2):
    ;;   base→wp1(8): -32 → 148
    ;;   wp1→sA(8):   -32 → 116
    ;;   collect s1(5): -5 → 111
    ;;   sA→wp1(8):   -32 → 79
    ;;   wp1→base(8): -32 → 47
    ;;   deliver s1(1): -1 → 46
    ;;   base→wp1(8): -32 → 14
    ;;   wp1→sB(12):  -48 → -34  ← still fails at 180
    ;;   → needs 180+34 = 214 total
    ;;   Set battery=220 to ensure feasibility with correct ordering
    (= (battery-level) 310)
  )

  (:goal
    (and
      (delivered sample1)
      (delivered sample2)
      (at-rover base)
    )
  )
)
