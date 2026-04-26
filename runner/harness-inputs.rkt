#lang racket/base
;; runner/harness-inputs.rkt — Wires input verbs (press, type,
;; chord, click-at, move-mouse) to driver-injected implementations.
;;
;; Loading this module installs the verbs by mutating the slots in
;; app-spec/main.rkt. Scenario files that `require app-spec`
;; will pick up the installed verbs, provided this harness module has
;; been loaded first by the runner.

(require "driver.rkt"
         "../app-spec/main.rkt")

(define (require-driver! who)
  (define d (current-driver))
  (unless d (error who "no driver installed"))
  d)

(define (->key-string key)
  (cond
    [(symbol? key) (symbol->string key)]
    [(string? key) key]
    [else (error 'press "expected symbol or string for key, got ~v" key)]))

(install-verb! 'press
  (lambda (key)
    (define d (require-driver! 'press))
    ((driver-press-key d) (->key-string key))))

(install-verb! 'type
  (lambda (text)
    (define d (require-driver! 'type))
    ((driver-type-text d) text)))

(install-verb! 'chord
  (lambda (mods key)
    (define d (require-driver! 'chord))
    ((driver-chord-keys d) mods (->key-string key))))

(install-verb! 'click-at
  (lambda (x y)
    (define d (require-driver! 'click-at))
    ((driver-click-at d) x y)))

(install-verb! 'move-mouse
  (lambda (x y)
    (define d (require-driver! 'move-mouse))
    ((driver-move-mouse d) x y)))
