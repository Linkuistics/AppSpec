#lang racket/base
;; test-reader-impl.rkt — Exercises the #lang app-spec/impl reader
;; and the (impl ...) DSL form.
;;
;; Runs in a throwaway parameterisation of current-library-collection-paths
;; that includes spec/ so the language resolves without pkg-install.

(require rackunit
         racket/file
         racket/runtime-path
         (only-in "../app-spec/impl.rkt"
                  impl-spec-name
                  impl-spec-binary
                  impl-spec-config-env
                  impl-spec-log-env
                  impl-spec-bundle-id
                  impl-spec-launch-via))

(define-runtime-path here ".")

(define spec-root (simplify-path (build-path here "..")))

(define (load-impl path)
  (parameterize ([current-library-collection-paths
                  (cons spec-root
                        (current-library-collection-paths))])
    (dynamic-require path 'impl-spec)))

(define (write-tmp lines)
  (define tmp (make-temporary-file "impl-~a.rkt"))
  (with-output-to-file tmp #:exists 'replace
    (lambda () (for-each displayln lines)))
  tmp)

(test-case "valid impl loads and provides impl-spec"
  (define tmp
    (write-tmp
     '("#lang app-spec/impl"
       "(impl"
       "  #:name \"Test Impl\""
       "  #:binary \"/bin/echo\""
       "  #:config-env \"MOD_CONFIG\""
       "  #:log-env \"MOD_LOG\""
       "  #:bundle-id \"test.bundle\""
       "  #:launch-via 'direct)")))
  (define spec (load-impl tmp))
  (check-equal? (impl-spec-name spec) "Test Impl")
  (check-equal? (impl-spec-binary spec) "/bin/echo")
  (check-equal? (impl-spec-config-env spec) "MOD_CONFIG")
  (check-equal? (impl-spec-log-env spec) "MOD_LOG")
  (check-equal? (impl-spec-bundle-id spec) "test.bundle")
  (check-equal? (impl-spec-launch-via spec) 'direct)
  (delete-file tmp))

(test-case "missing required field raises at load time"
  (define tmp
    (write-tmp
     '("#lang app-spec/impl"
       "(impl #:name \"incomplete\")")))
  (check-exn exn:fail? (lambda () (load-impl tmp)))
  (delete-file tmp))

(test-case "launch-via must be 'open | 'launchctl | 'direct"
  (define tmp
    (write-tmp
     '("#lang app-spec/impl"
       "(impl"
       "  #:name \"x\" #:binary \"/bin/echo\""
       "  #:config-env \"A\" #:log-env \"B\""
       "  #:bundle-id \"z\" #:launch-via 'bogus)")))
  (check-exn exn:fail? (lambda () (load-impl tmp)))
  (delete-file tmp))

(test-case "modaliser-racket impl config loads via the collection path"
  (define spec
    (load-impl (build-path spec-root "impls" "modaliser-racket.rkt")))
  (check-equal? (impl-spec-bundle-id spec) "dev.antony.Modaliser-Racket")
  (check-equal? (impl-spec-launch-via spec) 'open)
  (check-equal? (impl-spec-config-env spec) "MODALISER_CONFIG")
  (check-regexp-match #rx"Modaliser\\.app$" (impl-spec-binary spec)))

(displayln "test-reader-impl: all checks passed")
