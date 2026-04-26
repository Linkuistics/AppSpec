#lang racket/base
;; runner/main.rkt — CLI entry point for the App-Spec runner.
;;
;; Usage:
;;   racket runner/main.rkt \
;;       --impl <path-to-impl-config.rkt> \
;;       [--filter REGEX] [--vm VM-ID] \
;;       run <scenarios-dir>
;;
;; Flags must precede the positional `run <scenarios-dir>` args — this
;; is a limitation of `racket/cmdline`'s left-to-right parser. The
;; `run.sh` wrapper takes care of that ordering for the common case.
;;
;; Responsibilities:
;;   1. Parse CLI flags, load the impl descriptor.
;;   2. Push the AppSpec root onto `current-library-collection-paths` so
;;      scenario files written in `#lang app-spec` resolve.
;;   3. Build a driver that routes harness verbs at the live
;;      testanyware-sdk wrappers, then `install-driver!`.
;;   4. Hand off to dispatch.rkt for the scenario loop.
;;   5. Print a pass/fail summary; exit non-zero if any scenario failed.

(require racket/cmdline
         racket/path
         racket/runtime-path
         "dispatch.rkt"
         "driver.rkt"
         "impl-config.rkt"
         "lifecycle.rkt"
         "harness-inputs.rkt"
         "harness-logs.rkt"
         "harness-observations.rkt"
         "harness-state.rkt"
         "../testanyware-sdk/exec.rkt"
         "../testanyware-sdk/input.rkt"
         "../testanyware-sdk/screenshot.rkt"
         "../testanyware-sdk/agent.rkt"
         "../testanyware-sdk/macos-helpers.rkt"
         "../app-spec/main.rkt")

(define-runtime-path spec-root "..")

(define impl-path (make-parameter #f))
(define filter-rx (make-parameter #f))
(define vm-id     (make-parameter (getenv "TESTANYWARE_VM_ID")))

(define scenarios-dir
  (command-line
    #:program "app-spec"
    #:once-each
    [("--impl")   path "Path to impl config (.rkt)"  (impl-path path)]
    [("--filter") rx   "Regex to filter scenarios"   (filter-rx (regexp rx))]
    [("--vm")     v    "VM id (overrides env)"       (vm-id v)]
    #:args (cmd scenarios-dir)
    (unless (equal? cmd "run")
      (error 'app-spec
             "unknown command: ~a (only 'run' is supported in v1)" cmd))
    scenarios-dir))

(unless (impl-path)
  (error 'app-spec "--impl PATH is required"))
(unless (vm-id)
  (error 'app-spec "--vm ID is required (or set TESTANYWARE_VM_ID)"))

;; Scenario files written in #lang app-spec resolve via this push.
(current-library-collection-paths
  (cons (simplify-path spec-root)
        (current-library-collection-paths)))

(define impl (load-impl-config (impl-path)))

(define driver-impl
  (make-driver
    #:vm-id      (vm-id)
    #:impl       impl
    #:press-key  (lambda (k) (gv-press k #:vm (vm-id)))
    #:type-text  (lambda (t) (gv-type t #:vm (vm-id)))
    #:chord-keys (lambda (m k) (gv-chord m k #:vm (vm-id)))
    #:click-at   (lambda (x y) (error 'click-at "not implemented in v1"))
    #:move-mouse (lambda (x y) (error 'move-mouse "not implemented in v1"))
    #:log-tail
      (lambda ()
        (define-values (rc out _err)
          (gv-exec "cat /Users/admin/.cache/modaliser/events.log 2>/dev/null || true"
                   #:vm (vm-id)))
        (if (zero? rc) out ""))
    #:ocr-read    (lambda () (gv-ocr #:vm (vm-id)))
    #:ax-snapshot (lambda () (gv-ax-snapshot #:vm (vm-id)))
    #:running-app?
      (lambda (bundle-id)
        (define-values (_rc out _err)
          (gv-exec (format "pgrep -f ~a >/dev/null && echo yes || echo no"
                           bundle-id)
                   #:vm (vm-id)))
        (regexp-match? #rx"yes" out))
    #:file-exists?
      (lambda (path)
        (define-values (_rc out _err)
          (gv-exec (format "test -f ~a && echo yes || echo no" path)
                   #:vm (vm-id)))
        (regexp-match? #rx"yes" out))
    #:read-mru
      (lambda ()
        (define-values (_rc out _err)
          (gv-exec "cat /Users/admin/.config/modaliser/mru.dat 2>/dev/null || echo '#hash()'"
                   #:vm (vm-id)))
        (with-handlers ([exn:fail? (lambda _ (hash))])
          (read (open-input-string out))))
    #:read-file
      (lambda (path)
        (define-values (_rc out _err)
          (gv-exec (format "cat ~a" path) #:vm (vm-id)))
        (string->bytes/utf-8 out))
    #:kill-impl
      (lambda ()
        (quit-impl! (impl-spec-bundle-id impl) #:vm (vm-id)))
    #:restart-impl
      (lambda ()
        (quit-impl! (impl-spec-bundle-id impl) #:vm (vm-id))
        (sleep 1.0)
        (launch-impl! impl #:vm (vm-id))
        (wait-ready (impl-spec-bundle-id impl) #:vm (vm-id)))
    #:wait sleep))

(install-driver! driver-impl)

(define scenario-files (discover-scenario-files scenarios-dir))

(when (null? scenario-files)
  (eprintf "warning: no scenario files found under ~a~n" scenarios-dir))

(define (on-start scn-file name)
  (printf "~n[~a] ~a ... " (path->string scn-file) name)
  (flush-output))

(define (on-end name outcome detail)
  (case outcome
    [(pass) (printf "OK~n")]
    [(fail) (printf "FAIL~n    ~a~n" detail)]))

(define result
  (execute-scenarios impl
                     scenario-files
                     #:setup!      (lambda (i) (setup-scenario! i #:vm (vm-id)))
                     #:teardown!   (lambda (i n #:success? ok?)
                                     (teardown-scenario! i n
                                                         #:vm (vm-id)
                                                         #:success? ok?))
                     #:reset-logs! reset-log-buffer!
                     #:filter      (filter-rx)
                     #:on-scenario-start on-start
                     #:on-scenario-end   on-end))

(define passed (car result))
(define failed (cadr result))
(define total  (+ passed (length failed)))

(printf "~n~a/~a passed~n" passed total)

(unless (null? failed)
  (printf "Failures:~n")
  (for ([f (in-list failed)])
    (printf "  ~a: ~a~n" (car f) (cdr f)))
  (exit 1))
