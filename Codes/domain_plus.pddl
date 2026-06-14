;; ============================================================
;; Assignment D1-V1 — Q2: Planetary Rover Domain (PDDL+)
;; Extends Q1 with:
;;   - Continuous battery drain process (idle drain)
;;   - Critical-threshold event (emergency shutdown trigger)
;;   - Durative move and collect actions
;;
;; Requirements: :typing :numeric-fluents :durative-actions
;;               :continuous-effects :time
;;
;; Planner: ENHSP  (handles PDDL+ processes/events)
;; ============================================================

(define (domain planetary-rover-plus)

  (:requirements
    :typing
    :numeric-fluents
    :durative-actions
    :continuous-effects
    :time
  )

  (:types
    location
    sample
  )

  (:predicates
    (at-rover ?l - location)
    (connected ?l1 ?l2 - location)
    (sample-at ?s - sample ?l - location)
    (carrying ?s - sample)
    (delivered ?s - sample)
    (is-base ?l - location)
    (has-sample ?l - location)

    ;; PDDL+ state flags
    (rover-active)         ;; true while rover is moving or working
    (critical-battery)     ;; set by event when battery < threshold
    (system-ok)            ;; false after critical event fires
  )

  (:functions
    (battery-level)
    (move-cost ?l1 ?l2 - location)
    (idle-drain-rate)      ;; continuous drain per time unit (always on)
    (move-drain-rate)      ;; additional drain per time unit while moving
    (critical-threshold)   ;; battery level that triggers the safety event
  )

  ;; ===========================================================
  ;; PROCESS: idle-drain
  ;; Battery discharges continuously at all times,
  ;; even when the rover is not executing any action.
  ;; This models real electronic systems (sensors, comms, heating).
  ;; ===========================================================
  (:process idle-drain
    :parameters ()
    :precondition (and
      (> (battery-level) 0)
      (system-ok)
    )
    :effect (and
      (decrease (battery-level) (* #t (idle-drain-rate)))
    )
  )

  ;; ===========================================================
  ;; PROCESS: move-drain
  ;; Extra battery consumption while the rover is moving.
  ;; Runs concurrently with idle-drain.
  ;; ===========================================================
  (:process move-drain
    :parameters ()
    :precondition (and
      (rover-active)
      (> (battery-level) 0)
      (system-ok)
    )
    :effect (and
      (decrease (battery-level) (* #t (move-drain-rate)))
    )
  )

  ;; ===========================================================
  ;; EVENT: battery-critical
  ;; Fires automatically when battery drops below the threshold.
  ;; Models a hardware safety cutoff — timing determines
  ;; whether the rover can complete its mission.
  ;; ===========================================================
  (:event battery-critical
    :parameters ()
    :precondition (and
      (<= (battery-level) (critical-threshold))
      (system-ok)
    )
    :effect (and
      (critical-battery)
      (not (system-ok))    ;; rover shuts down; no further actions possible
    )
  )

  ;; ===========================================================
  ;; DURATIVE ACTION: move
  ;; Travel takes time (duration = distance/speed abstracted as fixed).
  ;; During the move, move-drain process is active.
  ;; ===========================================================
  (:durative-action move
    :parameters (?from ?to - location)
    :duration (= ?duration (move-cost ?from ?to))
    :condition (and
      (at start (at-rover ?from))
      (at start (connected ?from ?to))
      (at start (system-ok))
      (over all (system-ok))        ;; abort if critical event fires mid-move
    )
    :effect (and
      (at start (not (at-rover ?from)))
      (at start (rover-active))     ;; activate move-drain process
      (at end   (at-rover ?to))
      (at end   (not (rover-active)))
    )
  )

  ;; ===========================================================
  ;; DURATIVE ACTION: collect-sample
  ;; Collection takes 5 time units (instrument deployment, scan).
  ;; ===========================================================
  (:durative-action collect-sample
    :parameters (?s - sample ?l - location)
    :duration (= ?duration 5)
    :condition (and
      (at start (at-rover ?l))
      (at start (sample-at ?s ?l))
      (at start (has-sample ?l))
      (at start (system-ok))
      (over all (system-ok))
    )
    :effect (and
      (at end (not (sample-at ?s ?l)))
      (at end (carrying ?s))
    )
  )

  ;; ===========================================================
  ;; DURATIVE ACTION: deliver-sample
  ;; Instantaneous handoff (duration = 1) at base.
  ;; ===========================================================
  (:durative-action deliver-sample
    :parameters (?s - sample ?base - location)
    :duration (= ?duration 1)
    :condition (and
      (at start (at-rover ?base))
      (at start (is-base ?base))
      (at start (carrying ?s))
      (at start (system-ok))
      (over all (system-ok))
    )
    :effect (and
      (at end (not (carrying ?s)))
      (at end (delivered ?s))
    )
  )

)
