#lang racket/base
;; testanyware-sdk/agent.rkt — Agent-channel operations: upload, download,
;; accessibility-tree snapshot, health probe.

(require json
         "exec.rkt")

(provide gv-upload gv-download gv-ax-snapshot gv-health)

(define (args/vm vm tail)
  (if vm (append (list "--vm" vm) tail) tail))

(define (run-or-raise who args)
  (define-values (rc out err) ((current-testanyware-runner) args))
  (unless (zero? rc)
    (error who "rc=~a stderr=~a" rc err))
  out)

(define (gv-upload src dst #:vm [vm #f])
  (void (run-or-raise 'gv-upload
                      (cons "upload" (args/vm vm (list src dst))))))

(define (gv-download src dst #:vm [vm #f])
  (void (run-or-raise 'gv-download
                      (cons "download" (args/vm vm (list src dst))))))

(define (gv-ax-snapshot #:vm [vm #f])
  (define out (run-or-raise 'gv-ax-snapshot
                            (cons "ax"
                                  (cons "snapshot"
                                        (args/vm vm (list "--json"))))))
  (read-json (open-input-string out)))

(define (gv-health #:vm [vm #f])
  (define-values (rc _out _err)
    ((current-testanyware-runner)
     (cons "health" (args/vm vm '()))))
  (zero? rc))
