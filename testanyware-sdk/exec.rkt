#lang racket/base
;; testanyware-sdk/exec.rkt — Thin wrapper over the `testanyware` CLI.
;;
;; All SDK helpers funnel through `current-testanyware-runner` so tests
;; can stub the subprocess layer without monkey-patching `subprocess`
;; globally. Default implementation shells to the `testanyware` binary
;; on `$PATH`.

(require racket/port)

(provide gv-exec
         current-testanyware-runner)

(define (default-testanyware-runner args)
  (define bin (find-executable-path "testanyware"))
  (unless bin
    (error 'testanyware "binary not found on PATH"))
  (define-values (sp out-p in-p err-p)
    (apply subprocess #f #f #f bin args))
  (close-output-port in-p)
  (define out (port->string out-p))
  (define err (port->string err-p))
  (close-input-port out-p)
  (close-input-port err-p)
  (subprocess-wait sp)
  (values (subprocess-status sp) out err))

(define current-testanyware-runner
  (make-parameter default-testanyware-runner))

(define (gv-exec cmd #:vm [vm (getenv "TESTANYWARE_VM_ID")])
  (unless vm
    (error 'gv-exec "no VM id: pass #:vm or set TESTANYWARE_VM_ID"))
  ((current-testanyware-runner) (list "exec" "--vm" vm cmd)))
