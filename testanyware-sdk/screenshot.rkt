#lang racket/base
;; testanyware-sdk/screenshot.rkt — Screenshot + OCR wrappers.

(require "exec.rkt")

(provide gv-screenshot gv-ocr)

(define (run-or-raise who args)
  (define-values (rc out err) ((current-testanyware-runner) args))
  (unless (zero? rc)
    (error who "rc=~a stderr=~a" rc err))
  out)

(define (gv-screenshot out-path #:vm [vm #f])
  (define args
    (if vm
        (list "screenshot" "--vm" vm "-o" out-path)
        (list "screenshot" "-o" out-path)))
  (void (run-or-raise 'gv-screenshot args)))

(define (gv-ocr #:vm [vm #f] #:region [region #f])
  (define base (if vm (list "ocr" "--vm" vm) (list "ocr")))
  (define args (if region
                   (append base
                           (list "--region"
                                 (format "~a,~a,~a,~a"
                                         (car region) (cadr region)
                                         (caddr region) (cadddr region))))
                   base))
  (run-or-raise 'gv-ocr args))
