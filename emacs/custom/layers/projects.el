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
    "pp" '(projectile-switch-project :wk "switch project")
    "pa" '(projectile-add-known-project :wk "add project")
    "pd" '(projectile-remove-known-project :wk "remove project")
    "p!" '(projectile-run-shell-command-in-root :wk "run command in root")
    ))
