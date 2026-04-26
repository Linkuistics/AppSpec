#lang racket/base
;; runner/impl-config.rkt — Loads an impl descriptor from a
;; `#lang app-spec/impl` file and returns the `impl-spec` struct
;; it provides.
;;
;; The loader pushes `spec/` onto `current-library-collection-paths`
;; for the duration of the dynamic-require so `#lang app-spec/impl`
;; resolves without a global `raco pkg install`. The push is scoped to
;; the parameterize — the runner's ambient collection path is
;; unaffected after the loader returns.
;;
;; Re-exports the `impl-spec` struct bindings via the same relative
;; path that the impl-DSL module uses; Racket canonicalizes module
;; identity by absolute path so the struct instance matches the one
;; produced by `#lang app-spec/impl`.

(require racket/path
         "../app-spec/impl.rkt")

(provide load-impl-config
         (struct-out impl-spec))

(define (load-impl-config path)
  (define path* (if (path? path) path (string->path path)))
  (unless (file-exists? path*)
    (error 'load-impl-config "impl config not found: ~a" path))
  (define spec-root (simplify-path (build-path path* 'up 'up)))
  (parameterize ([current-library-collection-paths
                  (cons spec-root
                        (current-library-collection-paths))])
    (dynamic-require path* 'impl-spec)))
