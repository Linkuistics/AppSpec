#lang racket/base
;; test-testanyware-agent.rkt — Verifies the screenshot / OCR / upload /
;; AX-snapshot / health wrappers send the correct argv.

(require rackunit
         "../testanyware-sdk/exec.rkt"
         "../testanyware-sdk/screenshot.rkt"
         "../testanyware-sdk/agent.rkt")

(define (capture thunk)
  (define got '())
  (parameterize ([current-testanyware-runner
                  (lambda (args)
                    (set! got args)
                    (values 0 "" ""))])
    (thunk))
  got)

(test-case "gv-screenshot passes --vm and -o out-path"
  (check-equal?
   (capture (lambda () (gv-screenshot "/tmp/x.png" #:vm "v1")))
   '("screenshot" "--vm" "v1" "-o" "/tmp/x.png")))

(test-case "gv-ocr returns stdout payload"
  (parameterize ([current-testanyware-runner
                  (lambda (args) (values 0 "Safari\nTextEdit\n" ""))])
    (define text (gv-ocr #:vm "v1"))
    (check-true (regexp-match? #rx"Safari" text))))

(test-case "gv-ocr forwards --region when supplied"
  (check-equal?
   (capture (lambda () (gv-ocr #:vm "v1" #:region '(10 20 100 200))))
   '("ocr" "--vm" "v1" "--region" "10,20,100,200")))

(test-case "gv-upload sends (upload --vm … src dst)"
  (check-equal?
   (capture (lambda () (gv-upload "/local/x" "/remote/x" #:vm "v1")))
   '("upload" "--vm" "v1" "/local/x" "/remote/x")))

(test-case "gv-ax-snapshot parses JSON stdout"
  (parameterize ([current-testanyware-runner
                  (lambda (args)
                    (values 0 "{\"role\":\"window\",\"title\":\"X\"}" ""))])
    (define snap (gv-ax-snapshot #:vm "v1"))
    (check-equal? (hash-ref snap 'role) "window")
    (check-equal? (hash-ref snap 'title) "X")))

(test-case "gv-health returns #t on rc=0, #f otherwise"
  (parameterize ([current-testanyware-runner
                  (lambda (args) (values 0 "" ""))])
    (check-true (gv-health #:vm "v1")))
  (parameterize ([current-testanyware-runner
                  (lambda (args) (values 1 "" "no"))])
    (check-false (gv-health #:vm "v1"))))

(displayln "test-testanyware-agent: all checks passed")
