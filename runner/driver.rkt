#lang racket/base
;; runner/driver.rkt — Driver record + current-driver parameter.
;;
;; A driver is a bag of functions implementing the harness operations
;; (input injection, log tailing, observation queries, state access).
;; The runner constructs one with real testanyware-sdk calls; tests
;; construct one with mock functions.
;;
;; Verb implementations in harness-*.rkt look up `current-driver` and
;; dispatch through the function-typed fields. The runner installs a
;; driver via `install-driver!` before executing each scenario.
;;
;; Relative-path require (`"../app-spec/main.rkt"`) keeps tests
;; runnable as plain `racket file.rkt` without pushing the collection
;; path. The runner also resolves app-spec via a path push, but
;; both routes refer to the same absolute file so module instances
;; coincide.

(provide (struct-out driver)
         make-driver
         current-driver
         install-driver!)

(struct driver (vm-id
                impl
                events-path
                press-key
                type-text
                chord-keys
                click-at
                move-mouse
                log-tail
                ocr-read
                ax-snapshot
                running-app?
                file-exists?
                read-mru-fn
                read-file-fn
                kill-impl-fn
                restart-impl-fn
                wait-fn))

(define current-driver (make-parameter #f))

(define (install-driver! d)
  (current-driver d))

;; Keyword constructor with sensible defaults — every field defaults to
;; an "unset" thunk that raises a clear error if a verb tries to use it.
;; Tests override only the fields they exercise.

(define (unset-thunk name)
  (lambda args
    (error 'driver "field ~a not set on installed driver" name)))

(define (make-driver #:vm-id        [vm-id #f]
                     #:impl         [impl #f]
                     #:events-path  [events-path #f]
                     #:press-key    [press-key    (unset-thunk 'press-key)]
                     #:type-text    [type-text    (unset-thunk 'type-text)]
                     #:chord-keys   [chord-keys   (unset-thunk 'chord-keys)]
                     #:click-at     [click-at     (unset-thunk 'click-at)]
                     #:move-mouse   [move-mouse   (unset-thunk 'move-mouse)]
                     #:log-tail     [log-tail     (lambda () "")]
                     #:ocr-read     [ocr-read     (lambda () "")]
                     #:ax-snapshot  [ax-snapshot  (lambda () (hash))]
                     #:running-app? [running-app? (lambda (b) #f)]
                     #:file-exists? [file-exists? (lambda (p) #f)]
                     #:read-mru     [read-mru     (lambda () (hash))]
                     #:read-file    [read-file    (lambda (p) #"")]
                     #:kill-impl    [kill-impl    (lambda () (void))]
                     #:restart-impl [restart-impl (lambda () (void))]
                     #:wait         [wait-fn      (lambda (s) (void))])
  (driver vm-id impl events-path
          press-key type-text chord-keys click-at move-mouse
          log-tail ocr-read ax-snapshot running-app? file-exists?
          read-mru read-file kill-impl restart-impl wait-fn))
