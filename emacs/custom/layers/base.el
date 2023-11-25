;; -*- mode: emacs-lisp; lexical-binding: t; -*-
(setq user-full-name "Simon Ho"
      user-mail-address "simonho.ubc@gmail.com")

(setq gc-cons-threshold 100000000
      read-process-output-max (* 1024 1024)
      warning-minimum-level :error
      ring-bell-function 'ignore
      visible-bell t
      sentence-end-double-space nil
      save-interprogram-paste-before-kill t
      use-dialog-box nil
      compilation-scroll-output 'first-error
      use-short-answers t
      fast-but-imprecise-scrolling t
      make-backup-files nil
      auto-save-default nil
      create-lockfiles nil)
(global-auto-revert-mode t)
(set-charset-priority 'unicode)
(prefer-coding-system 'utf-8-unix)
(delete-selection-mode t)
(column-number-mode)
(tool-bar-mode 0)

(use-package which-key
  :demand t
  :init
  (setq 
    which-key-idle-delay 0.1
    which-key-idle-secondary-delay 0.01
    which-key-allow-evil-operators t
    which-key-add-column-padding 1
    which-key-max-display-columns 4)
  (which-key-mode))
