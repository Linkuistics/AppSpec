#lang racket/base
;; test-harness-observations.rkt — Unit tests for observation verbs.

(require rackunit
         "../runner/driver.rkt"
         "../runner/harness-observations.rkt"
         (only-in "../app-spec/main.rkt"
                  expect-ocr wait-for-ocr
                  expect-ax expect-no-ax
                  expect-running-app expect-file))

(test-case "expect-ocr matches substring in OCR output"
  (install-driver!
    (make-driver #:ocr-read (lambda () "Find app…\nSafari\nTextEdit")))
  (check-not-exn (lambda () (expect-ocr "Safari"))))

(test-case "expect-ocr matches regexp"
  (install-driver!
    (make-driver #:ocr-read (lambda () "version 1.2.3")))
  (check-not-exn (lambda () (expect-ocr #px"version \\d+\\.\\d+"))))

(test-case "expect-ocr raises when substring absent"
  (install-driver!
    (make-driver #:ocr-read (lambda () "unrelated text")))
  (check-exn exn:fail? (lambda () (expect-ocr "Safari"))))

(test-case "wait-for-ocr polls until pattern appears"
  (define calls (box 0))
  (install-driver!
    (make-driver
      #:ocr-read (lambda ()
                   (set-box! calls (add1 (unbox calls)))
                   (if (>= (unbox calls) 3) "Safari" ""))
      #:wait     (lambda (s) (void))))
  (wait-for-ocr "Safari" #:timeout 2.0)
  (check-true (>= (unbox calls) 3)))

(test-case "wait-for-ocr raises on timeout"
  (install-driver!
    (make-driver
      #:ocr-read (lambda () "")
      #:wait     (lambda (s) (void))))
  (check-exn exn:fail?
    (lambda () (wait-for-ocr "never" #:timeout 0.05))))

(test-case "expect-running-app delegates to driver-running-app?"
  (install-driver!
    (make-driver
      #:running-app? (lambda (b) (equal? b "com.apple.Safari"))))
  (check-not-exn (lambda () (expect-running-app "com.apple.Safari")))
  (check-exn exn:fail?
    (lambda () (expect-running-app "com.apple.Calculator"))))

(test-case "expect-file uses driver-file-exists?"
  (install-driver!
    (make-driver #:file-exists? (lambda (p) (equal? p "/tmp/x"))))
  (check-not-exn (lambda () (expect-file "/tmp/x")))
  (check-exn exn:fail? (lambda () (expect-file "/tmp/y"))))

(test-case "expect-file #:absent? inverts the sense"
  (install-driver!
    (make-driver #:file-exists? (lambda (p) (equal? p "/tmp/x"))))
  (check-not-exn (lambda () (expect-file "/tmp/y" #:absent? #t)))
  (check-exn exn:fail?
    (lambda () (expect-file "/tmp/x" #:absent? #t))))

(test-case "expect-ax finds matching role node"
  (define snapshot
    (hash 'AXRole "AXApplication"
          'AXChildren
          (list (hash 'AXRole "AXWindow"
                      'AXTitle "Find apps"
                      'AXChildren '()))))
  (install-driver! (make-driver #:ax-snapshot (lambda () snapshot)))
  (check-not-exn (lambda () (expect-ax #:role 'AXWindow)))
  (check-not-exn
    (lambda () (expect-ax #:role 'AXWindow #:title "Find apps")))
  (check-exn exn:fail?
    (lambda () (expect-ax #:role 'AXWindow #:title "Other"))))

(test-case "expect-no-ax raises when matching node present"
  (define snapshot
    (hash 'AXRole "AXApplication"
          'AXChildren
          (list (hash 'AXRole "AXWindow" 'AXChildren '()))))
  (install-driver! (make-driver #:ax-snapshot (lambda () snapshot)))
  (check-exn exn:fail? (lambda () (expect-no-ax #:role 'AXWindow))))

(test-case "expect-no-ax passes when role absent"
  (define snapshot
    (hash 'AXRole "AXApplication" 'AXChildren '()))
  (install-driver! (make-driver #:ax-snapshot (lambda () snapshot)))
  (check-not-exn (lambda () (expect-no-ax #:role 'AXWindow))))

(test-case "ax-find returns the matched node"
  (define snapshot
    (hash 'AXRole "AXApplication"
          'AXChildren
          (list (hash 'AXRole "AXWindow"
                      'AXTitle "target"
                      'AXChildren '()))))
  (define found (ax-find snapshot 'AXWindow "target"))
  (check-not-false found)
  (check-equal? (hash-ref found 'AXTitle #f) "target"))

(displayln "test-harness-observations: all checks passed")
