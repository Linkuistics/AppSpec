#lang racket/base
;; app-spec/main.rkt — scenario-DSL surface.
;;
;; Each scenario file is a `#lang app-spec` module. A top-level
;; `(scenario name body ...)` form appends a record to the shared
;; `scenario-registry` parameter. The runner resets the parameter
;; before dynamic-requiring each scenario file, then calls
;; `(get-scenarios)` to harvest what was registered.
;;
;; Loops, `require`, helpers, and any other racket/base form are
;; first-class — scenarios are code, not data, so parameterisation via
;; `(for ([k ...]) (scenario ...))` falls out without extra machinery.
;;
;; Verbs (press, expect-log, …) are stubs at load time; the runner
;; calls `install-verb!` for each one before executing scenarios, so
;; a scenario file loaded outside the runner cannot accidentally
;; invoke real inputs/state.

(require (for-syntax racket/base syntax/parse))

(provide (all-from-out racket/base)

         ;; Scenario registration
         scenario
         make-scenario
         (rename-out [scn?            scenario?]
                     [scn-name        scenario-name]
                     [scn-description scenario-description]
                     [scn-thunk       scenario-thunk])
         scenario-registry
         get-scenarios
         reset-scenarios!

         ;; Input verbs
         press type chord click-at move-mouse

         ;; Observation verbs
         expect-log wait-for-log expect-not-log
         expect-ocr expect-ax expect-no-ax expect-running-app expect-file

         ;; State verbs
         read-mru read-file kill-impl! restart-impl!

         ;; Time / sync
         wait-for-ocr wait

         ;; Runner hook
         install-verb!)

;; ── Scenario record + shared registry ───────────────────────────

(struct scn (name description thunk)
  #:prefab
  #:constructor-name make-scenario)

;; Mutable list held in a parameter so the runner can isolate each
;; scenario-file load. Scenario files do not provide their own
;; `all-scenarios`; the runner reads from here after evaluation.
(define scenario-registry (make-parameter '()))

(define (get-scenarios) (scenario-registry))

(define (reset-scenarios!) (scenario-registry '()))

(define (register-scenario! s)
  (scenario-registry (append (scenario-registry) (list s))))

(define-syntax (scenario stx)
  (syntax-parse stx
    [(_ name:expr
        (~optional (~seq #:description desc:expr)
                   #:defaults ([desc #'""]))
        body:expr ...+)
     #'(register-scenario!
        (make-scenario name desc (lambda () body ...)))]))

;; ── Harness verb stubs ──────────────────────────────────────────

(define (make-stub name)
  (lambda args
    (error name "no driver installed; scenarios must run under the runner")))

(define press              (make-stub 'press))
(define type               (make-stub 'type))
(define chord              (make-stub 'chord))
(define click-at           (make-stub 'click-at))
(define move-mouse         (make-stub 'move-mouse))
(define expect-log         (make-stub 'expect-log))
(define wait-for-log       (make-stub 'wait-for-log))
(define expect-not-log     (make-stub 'expect-not-log))
(define expect-ocr         (make-stub 'expect-ocr))
(define expect-ax          (make-stub 'expect-ax))
(define expect-no-ax       (make-stub 'expect-no-ax))
(define expect-running-app (make-stub 'expect-running-app))
(define expect-file        (make-stub 'expect-file))
(define read-mru           (make-stub 'read-mru))
(define read-file          (make-stub 'read-file))
(define kill-impl!         (make-stub 'kill-impl!))
(define restart-impl!      (make-stub 'restart-impl!))
(define wait-for-ocr       (make-stub 'wait-for-ocr))
(define wait               (make-stub 'wait))

(define (install-verb! sym impl)
  (case sym
    [(press)              (set! press impl)]
    [(type)               (set! type impl)]
    [(chord)              (set! chord impl)]
    [(click-at)           (set! click-at impl)]
    [(move-mouse)         (set! move-mouse impl)]
    [(expect-log)         (set! expect-log impl)]
    [(wait-for-log)       (set! wait-for-log impl)]
    [(expect-not-log)     (set! expect-not-log impl)]
    [(expect-ocr)         (set! expect-ocr impl)]
    [(expect-ax)          (set! expect-ax impl)]
    [(expect-no-ax)       (set! expect-no-ax impl)]
    [(expect-running-app) (set! expect-running-app impl)]
    [(expect-file)        (set! expect-file impl)]
    [(read-mru)           (set! read-mru impl)]
    [(read-file)          (set! read-file impl)]
    [(kill-impl!)         (set! kill-impl! impl)]
    [(restart-impl!)      (set! restart-impl! impl)]
    [(wait-for-ocr)       (set! wait-for-ocr impl)]
    [(wait)               (set! wait impl)]
    [else (error 'install-verb! "unknown verb: ~a" sym)]))
