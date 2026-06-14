;; ============================================================
;; Assignment D1-V1 — Q1: Planetary Rover Domain (Classical PDDL)
;; Requirements: :strips :typing :numeric-fluents
;; ============================================================

(define (domain planetary-rover)

  (:requirements :strips :typing :numeric-fluents)

  (:types
    location  ;; discrete waypoints on the planetary surface
    sample    ;; geological samples to be collected
  )

  (:predicates
    ;; Navigation
    (at-rover ?l - location)           ;; rover is at location l
    (connected ?l1 ?l2 - location)     ;; edge exists between l1 and l2 (directed)

    ;; Sample lifecycle
    (sample-at ?s - sample ?l - location)   ;; sample s is waiting at location l
    (carrying ?s - sample)                  ;; rover is currently carrying sample s
    (delivered ?s - sample)                 ;; sample s has been delivered to base

    ;; Infrastructure
    (is-base ?l - location)            ;; l is the base station
    (has-sample ?l - location)         ;; l is a collection site (has a sample)
  )

  (:functions
    (battery-level)                    ;; current battery charge (0–100)
    (move-cost ?l1 ?l2 - location)    ;; energy cost to traverse edge (l1→l2)
  )

  ;; ----------------------------------------------------------
  ;; ACTION: move
  ;; Navigate from one location to an adjacent one.
  ;; Consumes energy proportional to the edge weight.
  ;; ----------------------------------------------------------
  (:action move
    :parameters (?from ?to - location)
    :precondition (and
      (at-rover ?from)
      (connected ?from ?to)
      (>= (battery-level) (move-cost ?from ?to))   ;; enough charge
    )
    :effect (and
      (not (at-rover ?from))
      (at-rover ?to)
      (decrease (battery-level) (move-cost ?from ?to))
    )
  )

  ;; ----------------------------------------------------------
  ;; ACTION: collect-sample
  ;; Pick up a geological sample at the current location.
  ;; The rover can carry at most one sample at a time
  ;; (enforced by the absence of a second carrying predicate
  ;;  with a different sample — the planner cannot satisfy
  ;;  two simultaneous carrying facts for different samples
  ;;  if the problem goal only needs one delivery at a time).
  ;; ----------------------------------------------------------
  (:action collect-sample
    :parameters (?s - sample ?l - location)
    :precondition (and
      (at-rover ?l)
      (sample-at ?s ?l)
      (has-sample ?l)
    )
    :effect (and
      (not (sample-at ?s ?l))
      (carrying ?s)
    )
  )

  ;; ----------------------------------------------------------
  ;; ACTION: deliver-sample
  ;; Return a collected sample to the base station.
  ;; ----------------------------------------------------------
  (:action deliver-sample
    :parameters (?s - sample ?base - location)
    :precondition (and
      (at-rover ?base)
      (is-base ?base)
      (carrying ?s)
    )
    :effect (and
      (not (carrying ?s))
      (delivered ?s)
    )
  )

)
