#lang racket/base
;; test-reader-scenario.rkt — Exercises the #lang app-spec reader
;; and the (scenario ...) form.
;;
;; Each scenario file evaluates once under `dynamic-require`, which
;; appends records to `scenario-registry` in app-spec/main.rkt.
;; We reset the registry between test cases so the loads don't bleed
;; into each other.

(require rackunit
         racket/file
         racket/runtime-path
         (only-in "../app-spec/main.rkt"
                  scenario-name
                  scenario-description
                  scenario?
                  reset-scenarios!
                  get-scenarios))

(define-runtime-path here ".")
(define spec-root (simplify-path (build-path here "..")))

(define (load+collect path)
  (reset-scenarios!)
  (parameterize ([current-library-collection-paths
                  (cons spec-root
                        (current-library-collection-paths))])
    (dynamic-require path #f))
  (get-scenarios))

(define (write-tmp lines)
  (define tmp (make-temporary-file "scn-~a.rkt"))
  (with-output-to-file tmp #:exists 'replace
    (lambda () (for-each displayln lines)))
  tmp)

(test-case "simple scenario loads and registers"
  (define tmp
    (write-tmp
     '("#lang app-spec"
       "(scenario \"alpha\""
       "  (void))")))
  (define scns (load+collect tmp))
  (check-equal? (length scns) 1)
  (define s (car scns))
  (check-true (scenario? s))
  (check-equal? (scenario-name s) "alpha")
  (check-equal? (scenario-description s) "")
  (delete-file tmp))

(test-case "scenario #:description is captured"
  (define tmp
    (write-tmp
     '("#lang app-spec"
       "(scenario \"beta\" #:description \"does stuff\""
       "  (void))")))
  (define scns (load+collect tmp))
  (check-equal? (scenario-description (car scns)) "does stuff")
  (delete-file tmp))

(test-case "parameterised scenarios via for-loop"
  (define tmp
    (write-tmp
     '("#lang app-spec"
       "(for ([k (in-list '(\"a\" \"b\" \"c\"))])"
       "  (scenario (format \"quick-~a\" k)"
       "    (void)))")))
  (define scns (load+collect tmp))
  (check-equal? (length scns) 3)
  (check-equal? (sort (map scenario-name scns) string<?)
                '("quick-a" "quick-b" "quick-c"))
  (delete-file tmp))

(displayln "test-reader-scenario: all checks passed")
