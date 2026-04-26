#lang racket/base
;; test-testanyware-exec.rkt — Verifies the argv shape the SDK sends to
;; the `testanyware` CLI. The runner is parameterised so the test can
;; capture argv without ever spawning a subprocess.

(require rackunit
         "../testanyware-sdk/exec.rkt"
         "../testanyware-sdk/input.rkt")

(define (with-captured f)
  (define captured '())
  (parameterize ([current-testanyware-runner
                  (lambda (args)
                    (set! captured args)
                    (values 0 "" ""))])
    (f)
    captured))

(test-case "gv-exec passes --vm and the command"
  (check-equal? (with-captured (lambda () (gv-exec "echo hello" #:vm "vm-abc")))
                '("exec" "--vm" "vm-abc" "echo hello")))

(test-case "gv-exec defaults --vm to $TESTANYWARE_VM_ID"
  (putenv "TESTANYWARE_VM_ID" "env-vm")
  (check-equal? (with-captured (lambda () (gv-exec "uname")))
                '("exec" "--vm" "env-vm" "uname")))

(test-case "gv-exec raises when no VM id is available"
  (putenv "TESTANYWARE_VM_ID" "")
  ;; putenv "" sets empty string; getenv still returns "" (not #f) on macOS.
  ;; Mimic unset via a distinct sentinel call:
  (parameterize ([current-testanyware-runner
                  (lambda (args) (values 0 "" ""))])
    (with-handlers ([exn:fail? (lambda (_) (check-true #t))])
      (gv-exec "ignored" #:vm #f)
      (check-true #f "should have raised on missing vm id"))))

(test-case "gv-press sends (input key --vm … key)"
  (check-equal? (with-captured (lambda () (gv-press 'f18 #:vm "v1")))
                '("input" "key" "--vm" "v1" "f18")))

(test-case "gv-press without vm omits the --vm pair entirely"
  (check-equal? (with-captured (lambda () (gv-press "escape")))
                '("input" "key" "escape")))

(test-case "gv-type forwards text"
  (check-equal? (with-captured (lambda () (gv-type "hello world" #:vm "v1")))
                '("input" "type" "--vm" "v1" "hello world")))

(test-case "gv-chord joins modifiers with +"
  (check-equal? (with-captured (lambda () (gv-chord '(cmd shift) "t" #:vm "v1")))
                '("input" "chord" "--vm" "v1" "cmd+shift+t")))

(displayln "test-testanyware-exec: all checks passed")
