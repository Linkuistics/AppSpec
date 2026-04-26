#lang racket/base
;; test-harness-logs.rkt — Unit tests for the log-harness verbs.
;;
;; Tests stub `driver-log-tail` to feed canned line batches and stub
;; `driver-wait-fn` to a no-op so wait-for-log/expect-not-log run
;; without real sleeping.

(require rackunit
         racket/string
         "../runner/driver.rkt"
         "../runner/harness-logs.rkt"
         (only-in "../app-spec/main.rkt"
                  expect-log wait-for-log expect-not-log))

(define (lines->blob lines)
  (apply string-append
         (map (lambda (s) (string-append s "\n")) lines)))

(define (install-stub-tail! lines)
  (define buf (box (lines->blob lines)))
  (define (tail)
    (define current (unbox buf))
    (set-box! buf "")
    current)
  (install-driver!
    (make-driver
      #:log-tail tail
      #:wait     (lambda (s) (void))))
  (reset-log-buffer!)
  buf)

(test-case "expect-log matches existing log line"
  (install-stub-tail! '("[modal] enter tree=global"))
  (check-not-exn
    (lambda () (expect-log #px"\\[modal\\] enter tree=global"))))

(test-case "expect-log raises when no match"
  (install-stub-tail! '("[lifecycle] startup"))
  (check-exn exn:fail?
    (lambda () (expect-log #px"\\[modal\\] enter"))))

(test-case "expect-log accumulates across polls"
  (define buf (install-stub-tail! '("[lifecycle] startup")))
  ;; Drain initial batch into the accumulator.
  (expect-log #px"startup")
  ;; Add a follow-up line; after a poll, both are matchable.
  (set-box! buf (lines->blob '("[modal] enter tree=global")))
  (expect-log #px"\\[modal\\] enter tree=global")
  ;; The earlier line is still present in the accumulator.
  (expect-log #px"\\[lifecycle\\] startup"))

(test-case "wait-for-log polls until match appears"
  (define calls (box 0))
  (install-driver!
    (make-driver
      #:log-tail (lambda ()
                   (set-box! calls (add1 (unbox calls)))
                   (if (>= (unbox calls) 4)
                       "[chooser] open selector=\"Find Apps\"\n"
                       ""))
      #:wait     (lambda (s) (void))))
  (reset-log-buffer!)
  (wait-for-log #px"\\[chooser\\] open" #:timeout 2.0)
  (check-true (>= (unbox calls) 4)))

(test-case "wait-for-log raises on timeout"
  (install-driver!
    (make-driver
      #:log-tail (lambda () "")
      #:wait     (lambda (s) (void))))
  (reset-log-buffer!)
  (check-exn exn:fail?
    (lambda () (wait-for-log #px"never" #:timeout 0.05))))

(test-case "expect-not-log passes when pattern absent during window"
  (install-driver!
    (make-driver
      #:log-tail (lambda () "")
      #:wait     (lambda (s) (void))))
  (reset-log-buffer!)
  (check-not-exn
    (lambda () (expect-not-log #px"forbidden" #:within 0.05))))

(test-case "expect-not-log raises when pattern appears"
  (define calls (box 0))
  (install-driver!
    (make-driver
      #:log-tail (lambda ()
                   (set-box! calls (add1 (unbox calls)))
                   (if (>= (unbox calls) 2)
                       "[chooser] open\n"
                       ""))
      #:wait     (lambda (s) (void))))
  (reset-log-buffer!)
  (check-exn exn:fail?
    (lambda () (expect-not-log #px"\\[chooser\\] open" #:within 1.0))))

(displayln "test-harness-logs: all checks passed")
