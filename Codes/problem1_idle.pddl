;; ============================================================
;; Assignment D1-V1 — Q2 Problem 1: Idle Time Affects Feasibility
;;
;; Same simple map as Q1-P1, but now idle drain is ON.
;; idle-drain-rate = 1 unit/time, move-drain-rate = 2 units/time
;; move durations = move-cost (10 time units per hop)
;;
;; Timeline analysis (battery starts at 60):
;;   t=0:  move base→site-A  (duration 10)
;;         drain = idle(1) + move(2) = 3/t  →  -30  bat=30
;;   t=10: collect sample1   (duration 5)
;;         drain = idle(1) only (not moving)  →  -5   bat=25
;;   t=15: move site-A→base  (duration 10)
;;         drain = 3/t  →  -30  bat=-5  ← FAILS (critical fires at 10)
;;
;; Critical threshold = 10: event fires before rover returns!
;; The idle drain during collection (5 units) is what makes
;; the difference — without it, battery = 60-20(move)=40,
;; but WITH it the budget is much tighter.
;;
;; With battery=80 the same plan succeeds:
;;   bat=80 → -30 (move) → 50 → -5 (collect) → 45 → -30 (move) → 15 > threshold=10 ✓
;; ============================================================

(define (problem rover-plus-simple)
  (:domain planetary-rover-plus)

  (:objects
    base site-A site-B - location
    sample1 - sample
  )

  (:init
    (at-rover base)
    (system-ok)

    (connected base site-A)  (connected site-A base)
    (connected site-A site-B) (connected site-B site-A)

    (= (move-cost base site-A) 10)
    (= (move-cost site-A base) 10)
    (= (move-cost site-A site-B) 10)
    (= (move-cost site-B site-A) 10)

    (sample-at sample1 site-A)
    (has-sample site-A)
    (is-base base)

    ;; Continuous drain rates
    (= (idle-drain-rate)   1)   ;; always-on drain (sensors, heating)
    (= (move-drain-rate)   2)   ;; extra drain while driving

    ;; Critical threshold — event fires when battery <= 10
    (= (critical-threshold) 10)

    ;; Battery: set to 80 so the mission succeeds
    ;; (try 60 to see the critical event fire before return)
    (= (battery-level) 80)
  )

  (:goal
    (and
      (delivered sample1)
      (at-rover base)
    )
  )
)
