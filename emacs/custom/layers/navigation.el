;; -*- mode: emacs-lisp; lexical-binding: t; -*-

(use-package treemacs
  :ensure t
  :init
  (setq treemacs-python-executable "~/anaconda3/python.exe")
  :config
  (treemacs-follow-mode t)
  (treemacs-project-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-git-mode 'deferred)
  (treemacs-fringe-indicator-mode 'always)
  (treemacs-git-commit-diff-mode t))

(use-package treemacs-evil
  :after (treemacs evil)
  :ensure t)

(use-package treemacs-projectile
  :after (treemacs projectile)
  :ensure t)

(use-package treemacs-perspective
  :after (treemacs perspective)
  :ensure t
  :config (treemacs-set-scope-type 'Perspectives))
