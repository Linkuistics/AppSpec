#lang racket/base
;; test-lifecycle.rkt — Unit tests for spec/runner/lifecycle.rkt.
;;
;; Stubs `current-testanyware-runner` so no subprocess is spawned and
;; the assertions can inspect the exact argv sequence the runner
;; would issue against a VM.

(require rackunit
         racket/file
         racket/list
         racket/string
         "../testanyware-sdk/exec.rkt"
         "../runner/lifecycle.rkt"
         "../app-spec/impl.rkt")

(define (sample-impl #:launch-via [lv 'open])
  (make-impl-spec "Sample" "/tmp/Sample.app"
                  "MODALISER_CONFIG" "MODALISER_EVENTS_LOG"
                  "com.example.sample" lv))

;; Capture every argv passed to the testanyware runner. The stub also
;; returns a fake events.log containing `[lifecycle] startup` so
;; wait-ready (called inside setup-scenario!) terminates promptly.
(define (with-capture body)
  (define captured (box '()))
  (parameterize ([current-testanyware-runner
                  (lambda (args)
                    (set-box! captured
                              (append (unbox captured) (list args)))
                    (cond
                      [(and (member "exec" args)
                            (regexp-match? #px"cat .*events\\.log"
                                           (last args)))
                       (values 0 "[lifecycle] startup pid=42\n" "")]
                      [else (values 0 "" "")]))])
    (body captured)))

(define (joined-commands captured)
  (for/list ([argv (in-list (unbox captured))]
             #:when (and (pair? argv) (equal? (car argv) "exec")))
    (last argv)))

(test-case "launch-impl! 'open uses /usr/bin/open with config + log envs"
  (with-capture
    (lambda (captured)
      (launch-impl! (sample-impl #:launch-via 'open) #:vm "v1")
      (define cmds (joined-commands captured))
      (check-equal? (length cmds) 1)
      (define cmd (car cmds))
      (check-true (regexp-match? #rx"open " cmd))
      (check-true (regexp-match? #rx"MODALISER_CONFIG=" cmd))
      (check-true (regexp-match? #rx"MODALISER_EVENTS_LOG=" cmd))
      (check-true (regexp-match? #rx"/tmp/Sample\\.app" cmd)))))

(test-case "launch-impl! 'launchctl uses launchctl asuser 501"
  (with-capture
    (lambda (captured)
      (launch-impl! (sample-impl #:launch-via 'launchctl) #:vm "v1")
      (define cmd (car (joined-commands captured)))
      (check-true (regexp-match? #rx"launchctl asuser 501" cmd))
      (check-true (regexp-match? #rx"/tmp/Sample\\.app" cmd)))))

(test-case "launch-impl! 'direct shells out to the binary"
  (with-capture
    (lambda (captured)
      (launch-impl! (sample-impl #:launch-via 'direct) #:vm "v1")
      (define cmd (car (joined-commands captured)))
      (check-true (regexp-match? #rx"/tmp/Sample\\.app" cmd))
      (check-false (regexp-match? #rx"open " cmd))
      (check-false (regexp-match? #rx"launchctl" cmd)))))

(test-case "setup-scenario! issues quit, truncate, rm, tcc-reset, grant, launch"
  (with-capture
    (lambda (captured)
      (setup-scenario! (sample-impl) #:vm "v1" #:settle-delay 0)
      (define cmds (joined-commands captured))
      ;; The full flow ends with the readiness probe (cat … events.log),
      ;; so we expect ≥7 distinct exec calls.
      (check-true (>= (length cmds) 7)
                  (format "expected ≥7 exec calls, got ~a" (length cmds)))
      ;; Order check: quit → truncate → rm mru → tcc reset → grant → launch.
      (define steps
        (list #rx"osascript.*com\\.example\\.sample.*quit"
              #px"truncate.*events\\.log"
              #px"rm .*mru\\.dat"
              #px"tccutil reset All com\\.example\\.sample"
              #px"INSERT OR REPLACE INTO access"
              #px"open .*/tmp/Sample\\.app"))
      (void
        (for/fold ([cursor 0]) ([rx (in-list steps)])
          (define remaining (list-tail cmds cursor))
          (define hit-tail (memf (lambda (c) (regexp-match? rx c)) remaining))
          (check-not-false hit-tail (format "step missing: ~v" rx))
          (+ cursor (- (length remaining) (length hit-tail)) 1))))))

(test-case "teardown-scenario! quits the impl on success"
  (with-capture
    (lambda (captured)
      (teardown-scenario! (sample-impl) "name" #:vm "v1" #:success? #t)
      (define cmds (joined-commands captured))
      (check-equal? (length cmds) 1)
      (check-true (regexp-match? #rx"osascript.*quit" (car cmds))))))

(test-case "teardown-scenario! captures artifacts on failure"
  (define artifact-root (make-temporary-file "modspec-art-~a" 'directory))
  (with-capture
    (lambda (captured)
      (teardown-scenario! (sample-impl) "modal-enter"
                          #:vm "v1" #:success? #f
                          #:artifact-root artifact-root)
      ;; quit happens; tail + ax also happen; screenshot is attempted.
      (define cmds (joined-commands captured))
      (check-true (and (memf (lambda (c) (regexp-match? #px"tail -n .*events\\.log" c))
                             cmds)
                       #t)
                  "events tail not invoked")
      (check-true (and (memf (lambda (c) (regexp-match? #rx"osascript.*quit" c))
                             cmds)
                       #t)
                  "quit not invoked")))
  ;; Artifact dir created, and contains events.log.tail at minimum.
  (define dirs (directory-list artifact-root))
  (check-true (>= (length dirs) 1) "no artifact dir created")
  (define created (build-path artifact-root (car dirs)))
  (check-true (file-exists? (build-path created "events.log.tail")))
  (delete-directory/files artifact-root))

(test-case "capture-failure-artifacts is callable directly"
  (define artifact-root (make-temporary-file "modspec-art-~a" 'directory))
  (with-capture
    (lambda (_)
      (define dir (capture-failure-artifacts (sample-impl) "direct-call"
                                             #:vm "v1"
                                             #:artifact-root artifact-root))
      (check-true (directory-exists? dir))
      (check-true (file-exists? (build-path dir "events.log.tail")))))
  (delete-directory/files artifact-root))

(displayln "test-lifecycle: all checks passed")
