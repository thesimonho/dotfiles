;; -*- mode: emacs-lisp; lexical-binding: t; -*-
;; https://github.com/tshu-w/.emacs.d/blob/master/lisp/core-keybinds.el

(use-package general
  :demand t
  :after evil
  :config
  (general-evil-setup t))
(elpaca-wait)

;; Leader key
(general-define-key
   :states '(normal insert motion emacs)
   :keymaps 'override
   :prefix-map 'leader-map
   :prefix "SPC"
   :non-normal-prefix "M-SPC")
(general-create-definer leader-def :keymaps 'leader-map)
(leader-def "" nil)

;; Major mode key
(general-create-definer major-mode-def
  :states '(normal insert motion emacs)
  :keymaps 'override
  :major-modes t
  :prefix "SPC m"
  :non-normal-prefix "M-SPC m")
(major-mode-def "" nil)

(general-def universal-argument-map
    "SPC u" 'universal-argument-more)

;; ** Global Keybindings
(leader-def
:wk-full-keys nil
  "SPC"     '("M-x" . execute-extended-command)
  "TAB"     '("last buffer" . alternate-buffer)
  "u"       '("universal arg" . universal-argument)

  "m"       (cons "major mode" (make-sparse-keymap))

  "h"       (cons "help" (make-sparse-keymap))
  "hb"      'describe-bindings
  "hc"      'describe-char
  "hf"      'describe-function
  "hF"      'describe-face
  "hi"      'info-emacs-manual
  "hI"      'info-display-manual
  "hk"      'describe-key
  "hK"      'describe-keymap
  "hm"      'describe-mode
  "hM"      'woman
  "hp"      'describe-package
  "ht"      'describe-text-properties
  "hv"      'describe-variable

  "w"       (cons "windows" (make-sparse-keymap))
  "wb"      'switch-to-minibuffer-window
  "wd"      'delete-window
  "wD"      'delete-other-windows
  "wm"      'toggle-maximize-buffer
  "wh"      'evil-window-left
  "wj"      'evil-window-down
  "wk"      'evil-window-up
  "wl"      'evil-window-right
  "wr"      'rotate-windows-forward
  "ws"      'split-window-vertically
  "wu"      'winner-undo
  "wU"      'winner-redo
  "wv"      'split-window-horizontally

  "q"       (cons "quit" (make-sparse-keymap))
  "qd"      'restart-emacs-debug-init
  "qr"      'restart-emacs
  "qf"      'delete-frame
  "qq"      'save-buffers-kill-emacs
  )