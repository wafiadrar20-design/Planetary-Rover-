;; ============================================================
;; Assignment D1-V1 — Q1 Problem 1: Simple Instance
;; 3 locations, 1 sample, generous battery
;;
;;  base --- (10) --- site-A --- (10) --- site-B
;;  (all edges bidirectional, each direction stated explicitly)
;; ============================================================

(define (problem rover-simple)
  (:domain planetary-rover)

  (:objects
    base site-A site-B - location
    sample1 - sample
  )

  (:init
    ;; --- rover starts at base ---
    (at-rover base)

    ;; --- map topology (directed; both directions given) ---
    (connected base site-A)
    (connected site-A base)
    (connected site-A site-B)
    (connected site-B site-A)

    ;; --- edge costs ---
    (= (move-cost base site-A) 10)
    (= (move-cost site-A base) 10)
    (= (move-cost site-A site-B) 10)
    (= (move-cost site-B site-A) 10)

    ;; --- sample placement ---
    (sample-at sample1 site-A)
    (has-sample site-A)

    ;; --- infrastructure ---
    (is-base base)

    ;; --- battery ---
    (= (battery-level) 60)   ;; plenty for a simple round trip
  )

  ;; Goal: sample1 delivered and rover back at base
  (:goal
    (and
      (delivered sample1)
      (at-rover base)
    )
  )
)
