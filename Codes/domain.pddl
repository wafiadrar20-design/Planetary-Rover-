;; ============================================================
;; Assignment D1-V1 — Q1: Planetary Rover Domain (Classical PDDL)
;; Requirements: :strips :typing :numeric-fluents
;; ============================================================

(define (domain planetary-rover)

  (:requirements :strips :typing :numeric-fluents)

  (:types
    location  
    sample    
  )

  (:predicates
    ;; Navigation
    (at-rover ?l - location)           
    (connected ?l1 ?l2 - location)     

    ;; Sample lifecycle
    (sample-at ?s - sample ?l - location)   
    (carrying ?s - sample)                  
    (delivered ?s - sample)                 

    ;; Infrastructure
    (is-base ?l - location)           
    (has-sample ?l - location)         
  )

  (:functions
    (battery-level)                    
    (move-cost ?l1 ?l2 - location)    
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
      (>= (battery-level) (move-cost ?from ?to))   
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
