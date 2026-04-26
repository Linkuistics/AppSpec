#lang racket/base
;; test-harness-state.rkt — Unit tests for the state-harness verbs.
;;
;; Mirrors the test-harness-inputs.rkt pattern: install a fresh
;; recording driver per case, exercise the verb, assert what got
;; forwarded.

(require rackunit
         "../runner/driver.rkt"
         "../runner/harness-state.rkt"
         (only-in "../app-spec/main.rkt"
                  read-mru read-file kill-impl! restart-impl! wait))

(define (capture-driver)
  (define captured (box '()))
  (define (record! tag . args)
    (set-box! captured (cons (cons tag args) (unbox captured))))
  (define d
    (make-driver
      #:read-mru     (lambda ()  (record! 'read-mru)
                                 (hash "apps" '("com.apple.Safari")))
      #:read-file    (lambda (p) (record! 'read-file p) #"contents")
      #:kill-impl    (lambda ()  (record! 'kill-impl))
      #:restart-impl (lambda ()  (record! 'restart-impl))
      #:wait         (lambda (s) (record! 'wait s))))
  (values d captured))

(test-case "read-mru returns driver's mru hash"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (check-equal? (read-mru) (hash "apps" '("com.apple.Safari")))
  (check-equal? (unbox captured) '((read-mru))))

(test-case "read-file forwards path and returns driver's bytes"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (check-equal? (read-file "/tmp/x") #"contents")
  (check-equal? (unbox captured) '((read-file "/tmp/x"))))

(test-case "kill-impl! forwards"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (kill-impl!)
  (check-equal? (unbox captured) '((kill-impl))))

(test-case "restart-impl! forwards"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (restart-impl!)
  (check-equal? (unbox captured) '((restart-impl))))

(test-case "wait forwards seconds argument"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (wait 1.5)
  (check-equal? (unbox captured) '((wait 1.5))))

(test-case "verbs raise when no driver is installed"
  (install-driver! #f)
  (check-exn exn:fail? (lambda () (read-mru)))
  (check-exn exn:fail? (lambda () (read-file "/x")))
  (check-exn exn:fail? (lambda () (kill-impl!)))
  (check-exn exn:fail? (lambda () (restart-impl!)))
  (check-exn exn:fail? (lambda () (wait 0.1))))

(displayln "test-harness-state: all checks passed")
