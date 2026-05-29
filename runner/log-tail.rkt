#lang racket/base
;; runner/log-tail.rkt — Real log tailer for the live runner.
;;
;; `make-log-tail-fn` returns the thunk the runner installs as the
;; driver's `log-tail` field. Each call returns only the content
;; appended to the VM's events.log since the previous call, by tracking
;; a byte offset and reading from it via `testanyware exec`.
;;
;; Two VM reads per poll, both routed through gv-exec (and thus
;; `current-testanyware-runner`, so unit tests stub the subprocess
;; layer without a VM):
;;   wc -c < <path>        — current byte size, the authoritative offset
;;   tail -c +<offset+1>   — bytes appended since the last poll
;;
;; No background `place`/thread: events.log is a durable, append-only
;; file, so synchronous offset-tracking captures every line regardless
;; of poll timing. `setup-scenario!` truncates events.log to 0 between
;; scenarios; when the observed size drops below the tracked offset we
;; treat it as a truncation and reset to 0, so the tailer self-heals
;; across scenario boundaries without needing an explicit reset hook.

(require racket/string
         "../testanyware-sdk/exec.rkt")

(provide make-log-tail-fn)

(define default-events-path
  "/Users/admin/.cache/modaliser/events.log")

(define (vm-file-size vm path)
  (define-values (rc out _err)
    (gv-exec (format "wc -c < ~a 2>/dev/null || echo 0" path) #:vm vm))
  (or (and (zero? rc) (string->number (string-trim out))) 0))

(define (vm-read-from vm path byte-pos)
  (define-values (rc out _err)
    (gv-exec (format "tail -c +~a ~a 2>/dev/null || true" byte-pos path)
             #:vm vm))
  (if (zero? rc) out ""))

(define (make-log-tail-fn #:vm vm
                          #:path [path default-events-path])
  (define offset 0)
  (lambda ()
    (define size (vm-file-size vm path))
    (when (< size offset)        ; file truncated → new scenario
      (set! offset 0))
    (cond
      [(> size offset)
       (define fresh (vm-read-from vm path (add1 offset)))
       (set! offset size)
       fresh]
      [else ""])))
