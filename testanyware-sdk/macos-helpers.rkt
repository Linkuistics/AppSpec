#lang racket/base
;; testanyware-sdk/macos-helpers.rkt — macOS-specific setup/teardown
;; verbs the runner calls around each scenario: quit an impl, reset
;; its TCC grants, inject an Accessibility grant, wait for the impl
;; to emit `[lifecycle] startup`.

(require "exec.rkt")

(provide quit-impl!
         reset-tcc!
         grant-accessibility!
         wait-ready)

(define (quit-impl! bundle-id #:vm [vm #f])
  ;; osascript graceful quit → impl emits `[lifecycle] shutdown
  ;; reason=menu` via applicationWillTerminate before exit.
  (gv-exec
   (format "osascript -e 'tell application id \"~a\" to quit' 2>/dev/null || true"
           bundle-id)
   #:vm vm))

(define (reset-tcc! bundle-id #:vm [vm #f])
  (gv-exec (format "tccutil reset All ~a 2>/dev/null || true" bundle-id)
           #:vm vm))

(define (grant-accessibility! bundle-id #:vm [vm #f])
  ;; Admin DB write; VM-only. Adds an Accessibility grant row so the
  ;; next impl launch isn't blocked by the TCC prompt.
  (gv-exec
   (format
    (string-append
     "sudo sqlite3 /Library/Application\\ Support/com.apple.TCC/TCC.db "
     "\"INSERT OR REPLACE INTO access "
     "(service, client, client_type, auth_value, auth_reason, "
     "auth_version, indirect_object_identifier, flags, last_modified) "
     "VALUES ('kTCCServiceAccessibility', '~a', 0, 2, 3, 1, 'UNUSED', 0, ~a);\""
     " 2>/dev/null || true")
    bundle-id
    (current-seconds))
   #:vm vm))

(define (wait-ready bundle-id
                    #:vm          [vm #f]
                    #:events-path [events-path
                                   "/Users/admin/.cache/modaliser/events.log"]
                    #:timeout     [timeout-s 10])
  ;; Modaliser-specific readiness probe: poll events.log for the
  ;; `[lifecycle] startup` line. See spec/docs/logging-contract.md.
  (define deadline (+ (current-inexact-milliseconds) (* 1000.0 timeout-s)))
  (let loop ()
    (define-values (rc out err)
      (gv-exec (format "cat ~a 2>/dev/null || true" events-path) #:vm vm))
    (cond
      [(regexp-match? #px"\\[lifecycle\\] startup" out) #t]
      [(> (current-inexact-milliseconds) deadline)
       (error 'wait-ready
              "~a did not emit [lifecycle] startup within ~as"
              bundle-id timeout-s)]
      [else (sleep 0.2) (loop)])))
