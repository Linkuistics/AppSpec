#lang racket/base
;; runner/harness-state.rkt — Wires state-access verbs (read-mru,
;; read-file, kill-impl!, restart-impl!, wait) to driver-injected
;; implementations.
;;
;; Same shape as harness-inputs.rkt: loading this module installs the
;; verb dispatchers by mutating slots in app-spec/main.rkt.
;; Scenario files that `require app-spec` pick up the installed
;; verbs once the runner has loaded this module.

(require "driver.rkt"
         "../app-spec/main.rkt")

(define (require-driver! who)
  (define d (current-driver))
  (unless d (error who "no driver installed"))
  d)

(install-verb! 'read-mru
  (lambda ()
    (define d (require-driver! 'read-mru))
    ((driver-read-mru-fn d))))

(install-verb! 'read-file
  (lambda (path)
    (define d (require-driver! 'read-file))
    ((driver-read-file-fn d) path)))

(install-verb! 'kill-impl!
  (lambda ()
    (define d (require-driver! 'kill-impl!))
    ((driver-kill-impl-fn d))))

(install-verb! 'restart-impl!
  (lambda ()
    (define d (require-driver! 'restart-impl!))
    ((driver-restart-impl-fn d))))

(install-verb! 'wait
  (lambda (seconds)
    (define d (require-driver! 'wait))
    ((driver-wait-fn d) seconds)))
