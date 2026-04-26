#lang racket/base
;; test-harness-inputs.rkt — Unit tests for the input-harness verbs.
;;
;; The harness mutates verb slots on load, so every input verb is bound
;; to its driver-dispatching implementation by the time test cases run.
;; Tests install a fresh driver per case via `install-driver!` to keep
;; assertions independent.

(require rackunit
         "../runner/driver.rkt"
         "../runner/harness-inputs.rkt"
         (only-in "../app-spec/main.rkt"
                  press type chord click-at move-mouse))

(define (capture-driver)
  (define captured (box '()))
  (define (record! tag . args)
    (set-box! captured (cons (cons tag args) (unbox captured))))
  (define d
    (make-driver
      #:press-key  (lambda (k)     (record! 'press-key  k))
      #:type-text  (lambda (t)     (record! 'type-text  t))
      #:chord-keys (lambda (m k)   (record! 'chord-keys m k))
      #:click-at   (lambda (x y)   (record! 'click-at   x y))
      #:move-mouse (lambda (x y)   (record! 'move-mouse x y))))
  (values d captured))

(test-case "press forwards symbol key as string to driver-press-key"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (press 'F18)
  (check-equal? (unbox captured) '((press-key "F18"))))

(test-case "press accepts string keys verbatim"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (press "Return")
  (check-equal? (unbox captured) '((press-key "Return"))))

(test-case "type forwards text unchanged"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (type "hello world")
  (check-equal? (unbox captured) '((type-text "hello world"))))

(test-case "chord forwards modifier list and string key"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (chord '(cmd shift) 'a)
  (check-equal? (unbox captured) '((chord-keys (cmd shift) "a"))))

(test-case "click-at forwards coordinates"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (click-at 100 200)
  (check-equal? (unbox captured) '((click-at 100 200))))

(test-case "move-mouse forwards coordinates"
  (define-values (d captured) (capture-driver))
  (install-driver! d)
  (move-mouse 50 75)
  (check-equal? (unbox captured) '((move-mouse 50 75))))

(test-case "verbs raise when no driver is installed"
  (install-driver! #f)
  (check-exn exn:fail? (lambda () (press 'F18))))

(displayln "test-harness-inputs: all checks passed")
