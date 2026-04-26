#lang racket/base
;; runner/dispatch.rkt — Scenario execution loop, extracted from
;; main.rkt so it can be unit-tested against a mock driver without
;; spawning subprocesses.
;;
;; `execute-scenarios` takes an impl descriptor, a list of
;; scenario files, and lifecycle hooks (setup!, teardown!, reset-logs!).
;; For each scenario it runs:
;;   reset-logs!  →  setup!  →  body  →  teardown! success=#t
;; On exception from any of setup!/body, runs teardown! success=#f and
;; records the failure. Returns `(list passed failed)` where `failed`
;; is a list of `(cons scenario-name error-message)`.
;;
;; The runner's CLI wraps this in a driver install + summary printer;
;; keeping the loop pure makes the pass/fail bookkeeping unit-testable
;; without any real VM or subprocess activity.

(require "../app-spec/main.rkt")

(provide execute-scenarios
         load-scenarios-from-file
         discover-scenario-files)

(define (scenario-file? p)
  (and (file-exists? p)
       (regexp-match? #rx"\\.rkt$" (path->string p))
       (not (regexp-match? #rx"/helpers/" (path->string p)))))

(define (discover-scenario-files root)
  (cond
    [(not (directory-exists? root)) '()]
    [else
     (define root-path (if (path? root) root (string->path root)))
     (define found
       (for/list ([p (in-directory root-path)]
                  #:when (scenario-file? p))
         p))
     (sort found path<?)]))

(define (load-scenarios-from-file path
                                   #:filter [filter-rx #f])
  (parameterize ([scenario-registry '()])
    (reset-scenarios!)
    (dynamic-require path #f)
    (define all (get-scenarios))
    (cond
      [filter-rx
       (filter (lambda (s) (regexp-match? filter-rx (scenario-name s)))
               all)]
      [else all])))

(define (execute-scenarios impl
                           scenario-files
                           #:setup!       setup!
                           #:teardown!    teardown!
                           #:reset-logs!  [reset-logs! void]
                           #:filter       [filter-rx #f]
                           #:on-scenario-start [on-start void]
                           #:on-scenario-end   [on-end   void])
  (define passed 0)
  (define failed '())
  (for ([scn-file (in-list scenario-files)])
    (for ([scn (in-list (load-scenarios-from-file scn-file
                                                  #:filter filter-rx))])
      (define name (scenario-name scn))
      (on-start scn-file name)
      (define outcome
        (with-handlers
          ([exn:fail?
             (lambda (e)
               (with-handlers ([exn:fail? void])
                 (teardown! impl name #:success? #f))
               (cons 'fail (exn-message e)))])
          (reset-logs!)
          (setup! impl)
          ((scenario-thunk scn))
          (teardown! impl name #:success? #t)
          (cons 'pass #f)))
      (case (car outcome)
        [(pass) (set! passed (add1 passed))
                (on-end name 'pass #f)]
        [(fail) (set! failed (cons (cons name (cdr outcome)) failed))
                (on-end name 'fail (cdr outcome))])))
  (list passed (reverse failed)))
