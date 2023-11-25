;; -*- mode: emacs-lisp; lexical-binding: t; -*-

(use-package lsp-mode
  :init
  (setq lsp-modeline-diagnostics-enable t
	lsp-modeline-code-actions-mode t
	lsp-headerline-breadcrumb-mode t
lsp-warn-no-matched-clients nil
	lsp-enable-suggest-server-download t)
  :hook ((prog-mode . lsp-deferred)
         (lsp-mode . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred))

(use-package lsp-ui :commands lsp-ui-mode)

(use-package consult-lsp)

(use-package lsp-treemacs
  :init
  (lsp-treemacs-sync-mode 1)
    :commands lsp-treemacs-errors-list)

(use-package flycheck
  :init (global-flycheck-mode))
