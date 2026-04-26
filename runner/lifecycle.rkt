#lang racket/base
;; runner/lifecycle.rkt — Per-scenario VM setup/teardown.
;;
;; Setup brings the VM into a known state before each scenario:
;;   1. Quit any running impl (osascript graceful quit).
;;   2. Truncate events.log so log assertions start from a fresh slate.
;;   3. Remove mru.dat so MRU-related scenarios start unbiased.
;;   4. Reset and re-grant Accessibility for the impl's bundle id so
;;      the launch isn't blocked by a TCC prompt.
;;   5. Launch the impl through the configured launch method.
;;   6. Wait for `[lifecycle] startup` to confirm readiness.
;;
;; Teardown quits the impl and, on failure, captures screen + events
;; tail + AX snapshot into a dated artifact directory.
;;
;; All VM commands route through `current-testanyware-runner` (via the
;; gv-* helpers). Unit tests stub the runner; the live runner uses
;; the real `testanyware` binary on $PATH.

(require racket/file
         racket/date
         "../testanyware-sdk/exec.rkt"
         "../testanyware-sdk/screenshot.rkt"
         "../testanyware-sdk/macos-helpers.rkt"
         "../app-spec/impl.rkt")

(provide setup-scenario!
         teardown-scenario!
         capture-failure-artifacts
         launch-impl!)

(define default-events-path
  "/Users/admin/.cache/modaliser/events.log")

(define default-test-config-path
  "/Users/admin/.config/modaliser/test-config.scm")

(define default-mru-path
  "/Users/admin/.config/modaliser/mru.dat")

(define default-artifact-root
  (build-path "spec" "artifacts"))

(define (launch-impl! impl
                      #:vm                [vm #f]
                      #:events-path       [events-path default-events-path]
                      #:test-config-path  [test-config-path
                                           default-test-config-path])
  (define binary (impl-spec-binary impl))
  (case (impl-spec-launch-via impl)
    [(open)
     (gv-exec
      (format "~a=~a ~a=~a open \"~a\""
              (impl-spec-config-env impl) test-config-path
              (impl-spec-log-env    impl) events-path
              binary)
      #:vm vm)]
    [(launchctl)
     (gv-exec (format "launchctl asuser 501 \"~a\"" binary) #:vm vm)]
    [(direct)
     (gv-exec (format "\"~a\" &" binary) #:vm vm)]
    [else
     (error 'launch-impl! "unknown launch-via: ~v"
            (impl-spec-launch-via impl))]))

(define (setup-scenario! impl
                         #:vm               [vm #f]
                         #:settle-delay     [settle-delay 0.5]
                         #:events-path      [events-path default-events-path]
                         #:test-config-path [test-config-path
                                             default-test-config-path]
                         #:mru-path         [mru-path default-mru-path]
                         #:ready-timeout    [ready-timeout 10])
  (quit-impl! (impl-spec-bundle-id impl) #:vm vm)
  (when (positive? settle-delay) (sleep settle-delay))
  (gv-exec (format "truncate -s 0 ~a 2>/dev/null || true" events-path)
           #:vm vm)
  (gv-exec (format "rm -f ~a" mru-path) #:vm vm)
  (reset-tcc! (impl-spec-bundle-id impl) #:vm vm)
  (grant-accessibility! (impl-spec-bundle-id impl) #:vm vm)
  (launch-impl! impl
                #:vm vm
                #:events-path events-path
                #:test-config-path test-config-path)
  (wait-ready (impl-spec-bundle-id impl)
              #:vm vm
              #:events-path events-path
              #:timeout ready-timeout))

(define (teardown-scenario! impl name
                            #:vm             [vm #f]
                            #:success?       [success? #t]
                            #:artifact-root  [artifact-root default-artifact-root]
                            #:events-path    [events-path default-events-path])
  (unless success?
    (capture-failure-artifacts impl name
                               #:vm vm
                               #:artifact-root artifact-root
                               #:events-path events-path))
  (quit-impl! (impl-spec-bundle-id impl) #:vm vm))

(define (capture-failure-artifacts impl name
                                   #:vm            [vm #f]
                                   #:artifact-root [artifact-root
                                                    default-artifact-root]
                                   #:events-path   [events-path
                                                    default-events-path])
  (define ts (parameterize ([date-display-format 'iso-8601])
               (date->string (current-date) #t)))
  (define safe-ts (regexp-replace* #rx"[:T ]" ts "-"))
  (define dir (build-path artifact-root (format "~a-~a" name safe-ts)))
  (make-directory* dir)
  (with-handlers ([exn:fail?
                   (lambda (e)
                     (eprintf "screenshot capture failed: ~a\n"
                              (exn-message e)))])
    (gv-screenshot (path->string (build-path dir "screen.png")) #:vm vm))
  (define-values (_rc out _err)
    (gv-exec (format "tail -n 200 ~a 2>/dev/null || true" events-path)
             #:vm vm))
  (with-output-to-file (build-path dir "events.log.tail")
    #:exists 'replace
    (lambda () (display out)))
  (with-handlers ([exn:fail? (lambda _ (void))])
    (define-values (_rc2 out2 _err2)
      (gv-exec "testanyware ax snapshot --json" #:vm vm))
    (with-output-to-file (build-path dir "ax.json") #:exists 'replace
      (lambda () (display out2))))
  dir)
