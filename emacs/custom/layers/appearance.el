;; -*- mode: emacs-lisp; lexical-binding: t; -*-

;; Maximize the Emacs frame at startup
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; Font configurations
(set-frame-font "FiraCode NF-11")

(use-package all-the-icons)

(use-package all-the-icons-completion
  :after all-the-icons
  :init (all-the-icons-completion-mode))

(use-package all-the-icons-dired
  :after all-the-icons
  :hook (dired-mode . all-the-icons-dired-mode))

(use-package treemacs-all-the-icons
  :after (treemacs all-the-icons)
  :ensure t)

(add-hook 'prog-mode-hook #'display-line-numbers-mode)