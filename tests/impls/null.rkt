#lang app-spec/impl

;; Deliberately-broken impl. Running the scenario suite against this
;; should produce a user-readable "binary not found" error instead of
;; a cryptic crash — proves the runner's error path is friendly.

(impl
  #:name       "Null (no-op stub — scenarios will fail)"
  #:binary     "/does/not/exist/NullModaliser.app"
  #:config-env "MODALISER_CONFIG"
  #:log-env    "MODALISER_EVENTS_LOG"
  #:bundle-id  "null.modaliser.stub"
  #:launch-via 'open)
