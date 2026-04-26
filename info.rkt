#lang info

;; App-Spec collection descriptor.
;;
;; 'multi lets this directory host both the `app-spec` and
;; `app-spec/impl` sub-collections without a per-sub-collection
;; info.rkt. The runner pushes the AppSpec root onto
;; `current-library-collection-paths` at startup so no `raco pkg
;; install` is required.

(define collection 'multi)
(define deps '("base"))
(define build-deps '("rackunit-lib"))
