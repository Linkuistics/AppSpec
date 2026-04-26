#lang racket/base
;; test-impl-config.rkt — Unit tests for spec/runner/impl-config.rkt.
;;
;; The loader is a thin wrapper around `dynamic-require` that also
;; pushes `spec/` onto the collection path so `#lang app-spec/impl`
;; resolves without global pkg installation. Tests cover the happy path
;; (reference impl loads) and error paths (missing file, malformed
;; config).

(require rackunit
         racket/file
         racket/runtime-path
         "../runner/impl-config.rkt")

(define-runtime-path here ".")

(test-case "load-impl-config reads impl-spec from impls/modaliser-racket.rkt"
  (define spec (load-impl-config
                (build-path here ".." "impls" "modaliser-racket.rkt")))
  (check-equal? (impl-spec-name spec) "Modaliser-Racket")
  (check-equal? (impl-spec-bundle-id spec) "dev.antony.Modaliser-Racket")
  (check-equal? (impl-spec-launch-via spec) 'open))

(test-case "load-impl-config reads impl-spec from impls/null.rkt"
  (define spec (load-impl-config
                (build-path here ".." "impls" "null.rkt")))
  (check-equal? (impl-spec-bundle-id spec) "null.modaliser.stub")
  (check-equal? (impl-spec-binary spec) "/does/not/exist/NullModaliser.app"))

(test-case "load-impl-config raises a readable error on missing impl file"
  (check-exn
    #rx"impl config not found"
    (lambda ()
      (load-impl-config (build-path here "nonexistent-impl.rkt")))))

(test-case "load-impl-config surfaces malformed-config errors"
  (define tmp (make-temporary-file "bad-impl-~a.rkt"))
  (with-output-to-file tmp #:exists 'replace
    (lambda ()
      (displayln "#lang app-spec/impl")
      (displayln "(impl #:name \"missing fields\")")))
  (check-exn exn:fail? (lambda () (load-impl-config tmp)))
  (delete-file tmp))

(displayln "test-impl-config: all checks passed")
