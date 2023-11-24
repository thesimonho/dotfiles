;; -*- mode: emacs-lisp; lexical-binding: t; -*-

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding t
        evil-symbol-word-search t
        evil-ex-search-vim-style-regexp t
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil)
  :config
  (setq evil-cross-lines t
        evil-kill-on-visual-paste nil
        evil-move-beyond-eol t
        evil-want-fine-undo t
        evil-v$-excludes-newline t)

  (setq evil-normal-state-cursor  '("DarkGoldenrod2" box)
        evil-insert-state-cursor  '("chartreuse3" (bar . 2))
        evil-emacs-state-cursor   '("SkyBlue2" box)
        evil-replace-state-cursor '("chocolate" (hbar . 2))
        evil-visual-state-cursor  '("gray" (hbar . 2))
        evil-motion-state-cursor  '("plum3" box))

  (evil-set-undo-system 'undo-redo)
  (evil-mode 1))