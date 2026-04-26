#lang racket/base
;; test-macos-helpers.rkt — Verifies the scripts the runner issues for
;; quit / TCC reset on the VM, via the stubbed testanyware runner.

(require rackunit
         "../testanyware-sdk/exec.rkt"
         "../testanyware-sdk/macos-helpers.rkt")

(define (capture thunk)
  (define got '())
  (parameterize ([current-testanyware-runner
                  (lambda (args)
                    (set! got args)
                    (values 0 "" ""))])
    (thunk))
  got)

(test-case "quit-impl! issues an osascript quit for the bundle id"
  (define args (capture
                 (lambda () (quit-impl! "com.example.app" #:vm "v1"))))
  (check-equal? (car args) "exec")
  (check-equal? (list-ref args 1) "--vm")
  (check-equal? (list-ref args 2) "v1")
  (check-true (regexp-match? #rx"com\\.example\\.app" (list-ref args 3)))
  (check-true (regexp-match? #rx"osascript" (list-ref args 3))))

(test-case "reset-tcc! issues tccutil reset All"
  (define args (capture
                 (lambda () (reset-tcc! "com.example.app" #:vm "v1"))))
  (check-true (regexp-match? #rx"tccutil reset All" (list-ref args 3)))
  (check-true (regexp-match? #rx"com\\.example\\.app" (list-ref args 3))))

(displayln "test-macos-helpers: all checks passed")
