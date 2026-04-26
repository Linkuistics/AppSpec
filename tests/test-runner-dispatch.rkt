#lang racket/base
;; test-runner-dispatch.rkt — Unit tests for spec/runner/dispatch.rkt.
;;
;; `execute-scenarios` is exercised against:
;;   1. A scenario file that passes — verify setup! → body → teardown!
;;      fires in order and `success?` is #t.
;;   2. A scenario file whose body raises — verify teardown! fires with
;;      `success?` #f and the failure message is captured.
;;   3. A scenario file with no scenarios registered — zero results.
;;   4. The filter regex is honoured.
;;
;; All tests write throwaway `#lang app-spec` files into a
;; tmpdir; the `dispatch.rkt` logic consumes them without any driver
;; or VM activity.

(require rackunit
         racket/file
         racket/runtime-path
         "../runner/dispatch.rkt"
         "../app-spec/main.rkt")

(define-runtime-path here ".")
(define spec-root (simplify-path (build-path here "..")))

;; Push `spec/` so the scenario files can `#lang app-spec`.
(current-library-collection-paths
  (cons spec-root (current-library-collection-paths)))

(define (write-scenario-file body-lines)
  (define tmp (make-temporary-file "dispatch-~a.rkt"))
  (with-output-to-file tmp #:exists 'replace
    (lambda ()
      (displayln "#lang app-spec")
      (for-each displayln body-lines)))
  tmp)

(define fake-impl 'fake-impl-descriptor)

(define (make-recording-hooks)
  (define events (box '()))
  (define (record! tag . args)
    (set-box! events (cons (cons tag args) (unbox events))))
  (define (setup! impl)
    (record! 'setup impl))
  (define (teardown! impl name #:success? success?)
    (record! 'teardown impl name success?))
  (define (reset-logs!)
    (record! 'reset-logs))
  (values events setup! teardown! reset-logs!))

(test-case "passing scenario: setup → body → teardown(success=#t)"
  (define body-ran? (box #f))
  (parameterize ([scenario-registry '()])
    ;; Register a scenario directly instead of loading a file, for clarity.
    (reset-scenarios!)
    (scenario-registry
      (list (make-scenario "happy" "" (lambda () (set-box! body-ran? #t))))))
  ;; But execute-scenarios consumes files, so write one.
  (define f (write-scenario-file
             '("(scenario \"happy\" (void))")))
  (define-values (events setup! teardown! reset-logs!)
    (make-recording-hooks))
  (define result
    (execute-scenarios fake-impl (list f)
                       #:setup!      setup!
                       #:teardown!   teardown!
                       #:reset-logs! reset-logs!))
  (check-equal? (car result) 1 "passed count")
  (check-equal? (cadr result) '() "no failures")
  (define evs (reverse (unbox events)))
  (check-equal? (map car evs) '(reset-logs setup teardown))
  (define teardown-args (cdr (list-ref evs 2)))
  (check-equal? (cadr teardown-args) "happy")
  (check-equal? (caddr teardown-args) #t)
  (delete-file f))

(test-case "failing body: teardown fires with success=#f, failure recorded"
  (define f (write-scenario-file
             '("(scenario \"boom\" (error 'scenario \"intentional failure\"))")))
  (define-values (events setup! teardown! reset-logs!)
    (make-recording-hooks))
  (define result
    (execute-scenarios fake-impl (list f)
                       #:setup!      setup!
                       #:teardown!   teardown!
                       #:reset-logs! reset-logs!))
  (check-equal? (car result) 0 "zero passes")
  (check-equal? (length (cadr result)) 1)
  (define failure (car (cadr result)))
  (check-equal? (car failure) "boom")
  (check-regexp-match #rx"intentional failure" (cdr failure))
  (define evs (reverse (unbox events)))
  (check-equal? (map car evs) '(reset-logs setup teardown))
  (define teardown-args (cdr (list-ref evs 2)))
  (check-equal? (caddr teardown-args) #f "teardown called with success=#f")
  (delete-file f))

(test-case "teardown error on failure path is swallowed"
  (define f (write-scenario-file
             '("(scenario \"boom\" (error 'scenario \"body fail\"))")))
  (define (setup! _impl) (void))
  (define (teardown! _impl _name #:success? success?)
    (unless success?
      (error 'teardown "explodes on failure")))
  (define result
    (execute-scenarios fake-impl (list f)
                       #:setup!    setup!
                       #:teardown! teardown!))
  (check-equal? (car result) 0)
  (check-equal? (length (cadr result)) 1)
  (delete-file f))

(test-case "scenario file with no scenarios contributes nothing"
  (define f (write-scenario-file '("(void)")))
  (define-values (events setup! teardown! reset-logs!)
    (make-recording-hooks))
  (define result
    (execute-scenarios fake-impl (list f)
                       #:setup!      setup!
                       #:teardown!   teardown!
                       #:reset-logs! reset-logs!))
  (check-equal? (car result) 0)
  (check-equal? (cadr result) '())
  (check-equal? (unbox events) '() "hooks not invoked when no scenarios")
  (delete-file f))

(test-case "filter regex skips non-matching scenarios"
  (define f (write-scenario-file
             '("(scenario \"keep-me\" (void))"
               "(scenario \"skip-me\" (error 'scenario \"would fail\"))")))
  (define-values (events setup! teardown! reset-logs!)
    (make-recording-hooks))
  (define result
    (execute-scenarios fake-impl (list f)
                       #:setup!      setup!
                       #:teardown!   teardown!
                       #:reset-logs! reset-logs!
                       #:filter      #rx"keep"))
  (check-equal? (car result) 1)
  (check-equal? (cadr result) '())
  (delete-file f))

(test-case "discover-scenario-files: non-existent dir → empty list"
  (check-equal? (discover-scenario-files "/no/such/dir/exists") '()))

(test-case "discover-scenario-files: skips helpers/ sub-tree"
  (define root (make-temporary-file "disc-~a" 'directory))
  (make-directory (build-path root "helpers"))
  (define scn (build-path root "real.rkt"))
  (define helper (build-path root "helpers" "util.rkt"))
  (with-output-to-file scn (lambda () (display "x")))
  (with-output-to-file helper (lambda () (display "x")))
  (define found (discover-scenario-files root))
  (check-equal? (length found) 1)
  (check-regexp-match #rx"real\\.rkt$" (path->string (car found)))
  (delete-directory/files root))

(displayln "test-runner-dispatch: all checks passed")
