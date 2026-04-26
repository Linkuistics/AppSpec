#lang racket/base
;; testanyware-sdk/input.rkt — Keyboard/mouse input via `testanyware input`.

(require racket/string
         "exec.rkt")

(provide gv-press gv-type gv-chord)

(define (coerce-key k)
  (if (symbol? k) (symbol->string k) k))

(define (run! who . args)
  (define-values (rc out err) ((current-testanyware-runner) args))
  (unless (zero? rc)
    (error who "rc=~a stderr=~a" rc err))
  out)

(define (gv-press key #:vm [vm #f])
  (define key-str (coerce-key key))
  (define base (list "input" "key"))
  (define tail (if vm (append (list "--vm" vm) (list key-str)) (list key-str)))
  (apply run! 'gv-press (append base tail)))

(define (gv-type text #:vm [vm #f])
  (define base (list "input" "type"))
  (define tail (if vm (append (list "--vm" vm) (list text)) (list text)))
  (apply run! 'gv-type (append base tail)))

(define (gv-chord mods key #:vm [vm #f])
  ;; mods: list of 'cmd | 'alt | 'ctrl | 'shift
  (define combined
    (format "~a+~a"
            (string-join (map symbol->string mods) "+")
            (coerce-key key)))
  (define base (list "input" "chord"))
  (define tail (if vm (append (list "--vm" vm) (list combined)) (list combined)))
  (apply run! 'gv-chord (append base tail)))
