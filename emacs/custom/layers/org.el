;; -*- mode: emacs-lisp; lexical-binding: t; -*-

(add-hook 'org-mode-hook 'org-indent-mode)

(major-mode-def
  :keymaps 'org-mode-map
  "a" 'org-agenda
  "c" 'org-capture)