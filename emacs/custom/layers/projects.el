;; -*- mode: emacs-lisp; lexical-binding: t; -*-

(defun system-is-mswindows ()
  (eq system-type 'windows-nt))

(use-package projectile
  :ensure t
  :init
  (when (and (system-is-mswindows) (executable-find "find")
               (not (file-in-directory-p
                     (executable-find "find") "C:\\Windows")))
    (setq projectile-indexing-method 'alien
          projectile-generic-command "find . -type f")
          projectile-project-search-path '("~/dotfiles" "F:\\")
          projectile-sort-order 'recently-active
          projectile-enable-caching t
          projectile-require-project-root t
          projectile-current-project-on-switch t
          projectile-switch-project-action #'projectile-find-file
  )
  :config
  (projectile-mode)
  :general 
  (leader-def
  :wk-full-keys nil
    "p"       (cons "projects" (make-sparse-keymap))
    "pp" '(projectile-persp-switch-project :wk "Switch project")
    "pf" '(consult-project-buffer :wk "Project files")
    "pa" '(projectile-add-known-project :wk "Add project")
    "pd" '(projectile-remove-known-project :wk "Remove project")
    "p!" '(projectile-run-shell-command-in-root :wk "Run command in root")

    "p1" '((lambda () (interactive) (persp-switch-by-number 1)) :wk "Project 1")
    "p2" '((lambda () (interactive) (persp-switch-by-number 2)) :wk "Project 2")
    "p3" '((lambda () (interactive) (persp-switch-by-number 3)) :wk "Project 3")
    "p4" '((lambda () (interactive) (persp-switch-by-number 4)) :wk "Project 4")
    "p5" '((lambda () (interactive) (persp-switch-by-number 5)) :wk "Project 5")
    ))

(use-package perspective
  :ensure t
  :config
  (setq persp-initial-frame-name "default")
  (setq persp-suppress-no-prefix-key-warning t)
  (persp-mode))

(use-package persp-projectile
  :ensure t
  :after (projectile perspective))
