#lang racket/base
;; runner/harness-observations.rkt — Wires observation verbs
;; (expect-ocr, wait-for-ocr, expect-ax, expect-no-ax,
;; expect-running-app, expect-file) to driver-injected probes.
;;
;; Verb semantics:
;; - expect-ocr / wait-for-ocr accept a string substring or a regexp.
;; - expect-ax / expect-no-ax walk the AX-snapshot tree (a hash-of-hashes
;;   shape produced by `gv-ax-snapshot`); a node is matched by AXRole and
;;   optionally AXTitle.
;; - expect-running-app delegates to the driver's running-app? predicate.
;; - expect-file checks driver-file-exists?, with #:absent? inverting the
;;   sense (to assert the path is gone).

(require "driver.rkt"
         "../app-spec/main.rkt"
         racket/string)

(provide ax-find)

(define (require-driver! who)
  (define d (current-driver))
  (unless d (error who "no driver installed"))
  d)

(define (text-matches? pattern text)
  (cond
    [(regexp? pattern)         (regexp-match? pattern text)]
    [(string? pattern)         (string-contains? text pattern)]
    [else (error 'expect-ocr
                 "expected string or regexp, got ~v" pattern)]))

(install-verb! 'expect-ocr
  (lambda (pattern)
    (define d (require-driver! 'expect-ocr))
    (define text ((driver-ocr-read d)))
    (unless (text-matches? pattern text)
      (error 'expect-ocr
             "pattern ~v not found in OCR text:\n~a"
             pattern text))))

(install-verb! 'wait-for-ocr
  (lambda (pattern #:timeout [timeout-s 5.0])
    (define d (require-driver! 'wait-for-ocr))
    (define deadline (+ (current-inexact-milliseconds) (* 1000 timeout-s)))
    (let loop ()
      (define text ((driver-ocr-read d)))
      (cond
        [(text-matches? pattern text) (void)]
        [(> (current-inexact-milliseconds) deadline)
         (error 'wait-for-ocr
                "pattern ~v not found within ~as:\n~a"
                pattern timeout-s text)]
        [else
         ((driver-wait-fn d) 0.2)
         (loop)]))))

(install-verb! 'expect-ax
  (lambda (#:role role #:title [title #f])
    (define d (require-driver! 'expect-ax))
    (define ax ((driver-ax-snapshot d)))
    (unless (ax-find ax role title)
      (error 'expect-ax
             "no AX node with role=~a~a found"
             role
             (if title (format " title=~v" title) "")))))

(install-verb! 'expect-no-ax
  (lambda (#:role role #:title [title #f])
    (define d (require-driver! 'expect-no-ax))
    (define ax ((driver-ax-snapshot d)))
    (when (ax-find ax role title)
      (error 'expect-no-ax
             "unexpected AX node with role=~a~a"
             role
             (if title (format " title=~v" title) "")))))

(install-verb! 'expect-running-app
  (lambda (bundle-id)
    (define d (require-driver! 'expect-running-app))
    (unless ((driver-running-app? d) bundle-id)
      (error 'expect-running-app
             "app ~a is not running" bundle-id))))

(install-verb! 'expect-file
  (lambda (path #:exists? [exists? #t] #:absent? [absent? #f])
    (define d (require-driver! 'expect-file))
    (define actual ((driver-file-exists? d) path))
    (cond
      [absent?
       (when actual
         (error 'expect-file "~a unexpectedly exists" path))]
      [exists?
       (unless actual
         (error 'expect-file "~a does not exist" path))])))

;; AX tree walk (pre-order). The snapshot is a hash where AXChildren
;; maps to a list of child hashes. role is matched against AXRole as
;; a string; title (when supplied) against AXTitle.
(define (ax-find node role title)
  (cond
    [(not (hash? node)) #f]
    [(node-matches? node role title) node]
    [else
     (define children (hash-ref node 'AXChildren '()))
     (for/or ([child (in-list children)])
       (ax-find child role title))]))

(define (node-matches? node role title)
  (define role-str
    (cond [(symbol? role) (symbol->string role)]
          [(string? role) role]
          [else (error 'expect-ax "role must be symbol or string, got ~v" role)]))
  (and (equal? (hash-ref node 'AXRole #f) role-str)
       (or (not title)
           (equal? (hash-ref node 'AXTitle #f) title))))
