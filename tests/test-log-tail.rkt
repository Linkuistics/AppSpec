#lang racket/base
;; test-log-tail.rkt — Hermetic unit tests for the real log tailer.
;;
;; `make-log-tail-fn` produces the thunk the runner installs as the
;; driver's `log-tail` field. It tails the VM's events.log via gv-exec,
;; returning only content not yet seen. These tests model a virtual VM
;; file by stubbing `current-testanyware-runner` (same injection seam
;; used by testanyware-sdk/exec.rkt), so no VM and no `testanyware`
;; binary are touched.

(require rackunit
         racket/string
         "../runner/log-tail.rkt"
         "../testanyware-sdk/exec.rkt")

;; A stub runner that serves a virtual events.log held in `content-box`.
;; It answers the two command shapes the tailer issues:
;;   wc -c < <path>        -> the file's current byte size
;;   tail -c +<N> <path>   -> bytes from the Nth byte (1-indexed) onward
;; Content is treated as ASCII so byte offsets equal char offsets.
(define (vm-file-stub content-box)
  (lambda (args)
    (define cmd (car (reverse args)))
    (define content (unbox content-box))
    (cond
      [(regexp-match? #rx"wc -c" cmd)
       (values 0 (number->string (string-length content)) "")]
      [(regexp-match #rx"tail -c \\+([0-9]+)" cmd)
       => (lambda (m)
            (define pos (string->number (cadr m)))
            (define start (min (sub1 pos) (string-length content)))
            (values 0 (substring content start) ""))]
      [else (values 0 "" "")])))

(test-case "fresh file yields nothing"
  (define file (box ""))
  (parameterize ([current-testanyware-runner (vm-file-stub file)])
    (define tail (make-log-tail-fn #:vm "vm-1" #:path "/x/events.log"))
    (check-equal? (tail) "")))

(test-case "first poll returns appended lines, second returns nothing"
  (define file (box ""))
  (parameterize ([current-testanyware-runner (vm-file-stub file)])
    (define tail (make-log-tail-fn #:vm "vm-1" #:path "/x/events.log"))
    (set-box! file "[lifecycle] startup\n")
    (check-equal? (tail) "[lifecycle] startup\n")
    (check-equal? (tail) "")))

(test-case "subsequent polls return only the delta"
  (define file (box ""))
  (parameterize ([current-testanyware-runner (vm-file-stub file)])
    (define tail (make-log-tail-fn #:vm "vm-1" #:path "/x/events.log"))
    (set-box! file "[lifecycle] startup\n")
    (check-equal? (tail) "[lifecycle] startup\n")
    (set-box! file "[lifecycle] startup\n[modal] enter tree=global\n")
    (check-equal? (tail) "[modal] enter tree=global\n")))

(test-case "truncation (new scenario) resets the offset"
  (define file (box ""))
  (parameterize ([current-testanyware-runner (vm-file-stub file)])
    (define tail (make-log-tail-fn #:vm "vm-1" #:path "/x/events.log"))
    (set-box! file "[lifecycle] startup\n[modal] enter\n")
    (check-true (string-contains? (tail) "[modal] enter"))
    ;; setup-scenario! truncates events.log to 0 before the next scenario.
    (set-box! file "[lifecycle] startup\n")
    (check-equal? (tail) "[lifecycle] startup\n")))

(displayln "test-log-tail: all checks passed")
