;;; spec/config/test-config.scm — App-Spec test config.
;;;
;;; Loaded by every impl under test via the MODALISER_CONFIG env var.
;;; Each binding here exists to give scenarios a deterministic surface to
;;; press against; keep this file aligned with spec/docs/logging-contract.md
;;; and the helper bindings in spec/scenarios/helpers/quick-launch.rkt.
;;;
;;; Coverage map (event → triggering binding):
;;;   [modal] enter tree=global         → press F18
;;;   [modal] enter tree=<bundle-id>    → press F17 with matching app focused
;;;   [modal] group key=f               → F18 then "f"
;;;   [modal] exit reason=user          → press Escape in modal
;;;   [modal] exit reason=watchdog      → enter modal, idle past watchdog
;;;   [chooser] open/push/close         → F18 "f" "a" (Find Apps)
;;;   [mru] record key=apps id=…        → Find Apps, type, Return
;;;   [launch] bundle id=…              → quick-launch keys "s"/"t"
;;;   [launch] app name=…               → "n" (raw launch-app)
;;;   [launch] path path=…              → "p" (activate-app path-only)
;;;   [launch] url url=…                → "u" (open-url)
;;;   [window] focus pid=… title=…      → activate-app side effect
;;;   [window] move x=… y=… w=… h=…    → "w" group window verbs

;; ─── Leader keys ───────────────────────────────────────────────
(set-leader! 'global F18)
(set-leader! 'local  F17)

;; Short overlay delay keeps scenarios fast without changing semantics.
(set-overlay-delay! 0.1)

;; ─── Helpers ───────────────────────────────────────────────────

;; activate-app with a bundleId field emits [launch] bundle (not [launch] app).
(define (launch-bundle bundle-id)
  (lambda () (activate-app (list (cons 'bundleId bundle-id)))))

;; activate-app with only a path emits [launch] path.
(define (launch-path app-path)
  (lambda () (activate-app (list (cons 'path app-path)))))

;; ─── Global tree (F18) ────────────────────────────────────────
(define-tree 'global

  ;; Quick-launch by bundle id — Tasks 23 (mru-across-restart) and 24
  ;; (quick-launch) match these exactly via helpers/quick-launch.rkt.
  (key "s" "Safari"   (launch-bundle "com.apple.Safari"))
  (key "t" "TextEdit" (launch-bundle "com.apple.TextEdit"))

  ;; Launch by display name — emits [launch] app.
  (key "n" "Launch by name"
    (lambda () (launch-app "TextEdit")))

  ;; Launch by filesystem path — emits [launch] path.
  (key "p" "Launch by path"
    (launch-path "/System/Applications/TextEdit.app"))

  ;; Open URL — emits [launch] url.
  (key "u" "Example URL"
    (lambda () (open-url "https://example.com")))

  ;; Find group — open-find-apps! helper presses "f" then "a".
  (group "f" "Find"
    (selector "a" "Find Apps"
      'prompt    "Find app…"
      'source    find-installed-apps
      'on-select activate-app
      'remember  "apps"
      'id-field  "bundleId"))

  ;; Window management — center/fullscreen/restore are the verbs Task 24's
  ;; focus-move-restore scenario asserts on.
  (group "w" "Windows"
    (key "c" "Center"     (lambda () (center-window)))
    (key "f" "Fullscreen" (lambda () (toggle-fullscreen)))
    (key "r" "Restore"    (lambda () (restore-window)))
    (key "h" "Left half"  (lambda () (move-window 0 0 1/2 1)))))

;; ─── App-local tree (F17 when Safari is frontmost) ─────────────
;; Lets scenarios verify [modal] enter tree=com.apple.Safari with the
;; 'local leader. Bindings are intentionally trivial keystrokes.
(define-tree 'com.apple.Safari
  (key "n" "New Tab"
    (lambda () (send-keystroke '(cmd) "t")))
  (key "w" "Close Tab"
    (lambda () (send-keystroke '(cmd) "w"))))
