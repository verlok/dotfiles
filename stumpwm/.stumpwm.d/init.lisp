
;; StumpWM - init.lisp
;; Cody Reichert <codyreichert@gmail.com>

(in-package :stumpwm)

(add-to-load-path "~/.stumpwm.d/contrib/")

(add-to-load-path "/home/cody/.emacs.d/slime/swank")
(load "/home/cody/.emacs.d/slime/swank-loader.lisp")

(add-to-load-path "/home/cody/.stumpwm.d/contrib/modeline/cpu")
(add-to-load-path "/home/cody/.stumpwm.d/contrib/modeline/mem")
(add-to-load-path "/home/cody/.stumpwm.d/contrib/modeline/disk")
(add-to-load-path "/home/cody/.stumpwm.d/contrib/minor-mode/mpd")

(load-module "cpu")
(load-module "disk")
(load-module "mem")
(load-module "mpd")

;; run a couple commands on startup
(run-shell-command "myxrandr")
(run-shell-command "mpd")

;; general setup
(setf *mouse-focus-policy* :sloppy) ; focus window on mouse hover
(setf *ignore-wm-inc-hints* t) ; fixes space around some windows
(setf *mode-line-background-color* "#333")
(setf *mode-line-foreground-color* "#ddd")
(setf *suppress-frame-indicator*  t)

(set-focus-color "#7C4DFF")
(set-unfocus-color "#727272")


;; keys
(set-prefix-key (kbd "C-t"))

(define-key *root-map* (kbd "o")   "fnext")
(define-key *root-map* (kbd "C-o") "prev")

(define-key *root-map* (kbd "C-s") "swank")
(define-key *root-map* (kbd "c")   "exec terminator")
(define-key *root-map* (kbd "C-c") "exec chromium")
(define-key *root-map* (kbd "m")   "toggle-current-mode-line")
(define-key *root-map* (kbd "C-e") "exec emacs")

(define-key *root-map* (kbd "C-m") 'mpd:*mpd-map*)
(define-key mpd:*mpd-map* (kbd "C-g") "smirk-shuffle-genre")
(define-key mpd:*mpd-map* (kbd "C-a") "smirk-shuffle-artist")
(define-key mpd:*mpd-map* (kbd "C-t") "smirk-random-tracks")
(define-key mpd:*mpd-map* (kbd "a")   "smirk-random-album")


(defcommand smirk-shuffle-artist (artist) ((:string "Arist: "))
  "Shuffle MPD with the given artist."
  (run-shell-command (concat "smirk artist " artist)))

(defcommand smirk-shuffle-genre (genre) ((:string "Genre: "))
    "Shuffle MPD with the given genre."
  (run-shell-command (concat "smirk genre " genre)))

(defcommand smirk-random-tracks () ()
    "Play a random 250 tracks in MPD."
  (run-shell-command "smirk tracks"))

(defcommand smirk-random-album () ()
    "Play a random album in MPD."
  (run-shell-command "smirk album"))


;; swank
(swank-loader:init)

(defvar *swank-p* nil)

(defcommand swank () ()
"Starts a swank server on port 4005 and notifies the user."
  (setf *top-level-error-action* :break)
  (if *swank-p*
      (message "Swank server already running.")
    (progn
      (swank:create-server :port 4005
                           :style swank:*communication-style*
                           :dont-close t)
      (setf *swank-p* t)
      (message "Starting swank on port 4005."))))


(defun show-key-seq (key seq val)
  "Show a brief message with the key-sequence used for all commands."
  (declare (ignore key val))
  (message (print-key-seq (reverse seq))))

(add-hook *key-press-hook* 'show-key-seq)


; MPD
(mpd:mpd-connect)

(setf *window-format* "|%n%m%30t|")
(setf mpd:*mpd-modeline-fmt* "%L %a - %t (%n/%p)")

;; mode-line
(defcommand toggle-current-mode-line () ()
  "Toggle the current screens mode-line."
  (toggle-mode-line (current-screen)
                    (current-head)))


(defun my/fmt-cpu-usage (ml)
  "Returns a string representing current the percent of average CPU
  utilization."
  (declare (ignore ml))
  (let* ((cpu (nth-value 0 (truncate (* 100 (cpu::current-cpu-usage))))))
    (format nil "~A%" cpu)))

(pushnew '(#\U my/fmt-cpu-usage) *screen-mode-line-formatters* :test 'equal)


(defun my/fmt-mem-usage (ml)
  "Returns a string representing the current percent of used memory."
  (declare (ignore ml))
  (let* ((mem (mem::mem-usage))
         (allocated (truncate (/ (nth 1 mem) 1000))))
    (format nil "~A mb" allocated)))

(pushnew '(#\N my/fmt-mem-usage) *screen-mode-line-formatters* :test 'equal)

(defun my/fmt-disk-usage (ml)
  "Returns a string representing the current percent of used memory."
  (declare (ignore ml))
  (disk::disk-update-usage disk::*disk-usage-paths*)
  (let ((fmts (loop for p in disk::*disk-usage-paths*
                 collect (disk::format-expand disk::*disk-formatters-alist*
                                          "%m: %p"
                                          p))))
    (format nil "~{~a~}" fmts)))

(pushnew '(#\Y my/fmt-disk-usage) *screen-mode-line-formatters* :test 'equal)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun enable-mode-line-all-heads ()
  (dolist (screen *screen-list*)
    (dolist (head (screen-heads screen))
      (enable-mode-line screen head t))))

(setf *screen-mode-line-format*
      (list
       "[^B%n^b] %W "
       "^> %m | %N | %U | %Y | "
       '(:eval (run-shell-command "date '+%F %a %R' | tr -d [:cntrl:]" t))))

(setf *mode-line-timeout* 2)

(enable-mode-line-all-heads)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Groups and Windows
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setf *default-group-name* "1")

(defun mode-line-scroll-through-windows (ml bt x y)
  "Allows scrolling through windows and groups with the mouse-wheel.
Using the left 100px of mode-line (where the group is displayed) will
scroll through the groups, while using any other part of the mode-line
will scroll through windows in the current group."
  (declare (ignore ml y))
  (cond ((>= x 100)
         (cond ((eq bt 5)
                (run-commands "next"))
               ((eq bt 4)
                (run-commands "prev"))))
        (t
         (cond ((eq bt 5)
                (run-commands "gnext"))
               ((eq bt 4)
                (run-commands "gprev"))))))

(add-hook *mode-line-click-hook* 'mode-line-scroll-through-windows)
