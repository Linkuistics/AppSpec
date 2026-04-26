#lang racket/base
;; app-spec/impl.rkt — DSL surface for impl config files.
;;
;; Every Modaliser implementation declares a single `(impl ...)` form
;; describing its launch and on-disk contract. The runner
;; dynamic-requires the impl-config file and reads the provided
;; `impl-spec` struct.
;;
;; All six keywords are required; missing ones are a syntax error.
;; `launch-via` is validated against the enum { 'open, 'launchctl,
;; 'direct } at expansion time so typos fail loudly.

(require (for-syntax racket/base syntax/parse))

(provide (all-from-out racket/base)
         impl
         make-impl-spec
         (struct-out impl-spec))

;; Name the constructor explicitly so the DSL can expand to a
;; top-level `(define impl-spec …)` binding in the user's impl file
;; without shadowing the struct constructor.
(struct impl-spec (name binary config-env log-env bundle-id launch-via)
  #:prefab
  #:constructor-name make-impl-spec)

(define valid-launch-methods '(open launchctl direct))

(define (check-launch-via lv)
  (unless (memq lv valid-launch-methods)
    (error 'impl
           "launch-via must be 'open, 'launchctl, or 'direct; got ~v" lv))
  lv)

(define-syntax (impl stx)
  (syntax-parse stx
    [(_ (~alt (~once (~seq #:name       name:expr))
              (~once (~seq #:binary     binary:expr))
              (~once (~seq #:config-env config-env:expr))
              (~once (~seq #:log-env    log-env:expr))
              (~once (~seq #:bundle-id  bundle-id:expr))
              (~once (~seq #:launch-via launch-via:expr)))
        ...)
     #'(begin
         (provide impl-spec)
         (define impl-spec
           (make-impl-spec name binary config-env log-env bundle-id
                           (check-launch-via launch-via))))]))
