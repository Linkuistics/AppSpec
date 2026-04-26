#lang racket/base
;; runner/harness-logs.rkt — Wires log-assertion verbs (expect-log,
;; wait-for-log, expect-not-log) to the driver's log-tail function.
;;
;; A monotonic accumulator buffers everything seen so far in the current
;; scenario; expect-log searches the whole accumulator so assertions
;; can fire after the line has scrolled past the latest tail. The
;; runner is expected to call `reset-log-buffer!` between scenarios.
;;
;; Polling cadence (`wait-for-log`, `expect-not-log`) goes through
;; `driver-wait-fn` so unit tests can stub it out without sleeping.
;; The real runner installs `sleep` as the wait function.

(require "driver.rkt"
         "../app-spec/main.rkt")

(provide reset-log-buffer!
         poll-logs!
         accumulated-log)

(define accumulated-log "")

(define (reset-log-buffer!)
  (set! accumulated-log ""))

(define (poll-logs!)
  (define d (current-driver))
  (unless d (error 'poll-logs! "no driver installed"))
  (define fresh ((driver-log-tail d)))
  (unless (equal? fresh "")
    (set! accumulated-log (string-append accumulated-log fresh))))

(install-verb! 'expect-log
  (lambda (rx)
    (poll-logs!)
    (unless (regexp-match? rx accumulated-log)
      (error 'expect-log
             "pattern ~v not found in log:\n~a"
             rx accumulated-log))))

(install-verb! 'wait-for-log
  (lambda (rx #:timeout [timeout-s 5.0])
    (define d (current-driver))
    (unless d (error 'wait-for-log "no driver installed"))
    (define deadline (+ (current-inexact-milliseconds) (* 1000 timeout-s)))
    (let loop ()
      (poll-logs!)
      (cond
        [(regexp-match? rx accumulated-log) (void)]
        [(> (current-inexact-milliseconds) deadline)
         (error 'wait-for-log
                "pattern ~v did not appear within ~as:\n~a"
                rx timeout-s accumulated-log)]
        [else
         ((driver-wait-fn d) 0.1)
         (loop)]))))

(install-verb! 'expect-not-log
  (lambda (rx #:within [within-s 1.0])
    (define d (current-driver))
    (unless d (error 'expect-not-log "no driver installed"))
    (define deadline (+ (current-inexact-milliseconds) (* 1000 within-s)))
    (let loop ()
      (poll-logs!)
      (cond
        [(regexp-match? rx accumulated-log)
         (error 'expect-not-log
                "pattern ~v unexpectedly found in log:\n~a"
                rx accumulated-log)]
        [(> (current-inexact-milliseconds) deadline) (void)]
        [else
         ((driver-wait-fn d) 0.1)
         (loop)]))))
