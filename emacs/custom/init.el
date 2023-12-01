;; -*- lexical-binding: t; -*-
(defun org-babel-tangle-config ()
 (when (string-equal (file-name-nondirectory (buffer-file-name)) "init.org"))
 (let ((org-confirm-babel-evaluate nil))
   (org-babel-tangle)
   (message "%s tangled" buffer-file-name)))
 (add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'org-babel-tangle-config)))

;; (add-hook 'emacs-startup-hook
    ;; 	  (lambda ()
    ;; 	    (message "*** Emacs loaded in %s seconds with %d garbage collections."
    ;; 		     (emacs-init-time "%.2f")
    ;; 		     gcs-done)))
  
(setq use-package-verbose nil  ; don't print anything
      use-package-compute-statistics t ; compute statistics about package initialization
      use-package-minimum-reported-time 0.0001
      use-package-always-defer t)	; always defer, don't "require", except when :demand

(defvar elpaca-installer-version 0.6)
(defvar elpaca-directory (expand-file-name "elpaca/" user-emacs-directory))
(defvar elpaca-builds-directory (expand-file-name "builds/" elpaca-directory))
(defvar elpaca-repos-directory (expand-file-name "repos/" elpaca-directory))
(defvar elpaca-order '(elpaca :repo "https://github.com/progfolio/elpaca.git"
			:ref nil
			:files (:defaults "elpaca-test.el" (:exclude "extensions"))
			:build (:not elpaca--activate-package)))
(let* ((repo  (expand-file-name "elpaca/" elpaca-repos-directory))
 (build (expand-file-name "elpaca/" elpaca-builds-directory))
 (order (cdr elpaca-order))
 (default-directory repo))
  (add-to-list 'load-path (if (file-exists-p build) build repo))
  (unless (file-exists-p repo)
    (make-directory repo t)
    (when (< emacs-major-version 28) (require 'subr-x))
    (condition-case-unless-debug err
	(if-let ((buffer (pop-to-buffer-same-window "*elpaca-bootstrap*"))
		 ((zerop (call-process "git" nil buffer t "clone"
				 (plist-get order :repo) repo)))
		 ((zerop (call-process "git" nil buffer t "checkout"
				 (or (plist-get order :ref) "--"))))
		 (emacs (concat invocation-directory invocation-name))
		 ((zerop (call-process emacs nil buffer nil "-Q" "-L" "." "--batch"
				 "--eval" "(byte-recompile-directory \".\" 0 'force)")))
		 ((require 'elpaca))
		 ((elpaca-generate-autoloads "elpaca" repo)))
	    (progn (message "%s" (buffer-string)) (kill-buffer buffer))
	  (error "%s" (with-current-buffer buffer (buffer-string))))
((error) (warn "%s" err) (delete-directory repo 'recursive))))
  (unless (require 'elpaca-autoloads nil t)
    (require 'elpaca)
    (elpaca-generate-autoloads "elpaca" repo)
    (load "./elpaca-autoloads")))
(add-hook 'after-init-hook #'elpaca-process-queues)
(elpaca `(,@elpaca-order))

;; Install use-package support
(elpaca elpaca-use-package
  ;; Enable :elpaca use-package keyword.
  (elpaca-use-package-mode)
  ;; Assume :elpaca t unless otherwise specified.
  (setq elpaca-use-package-by-default t))

;; Block until current queue processed.
(elpaca-wait)

(use-package no-littering
	:init
	(setq no-littering-etc-directory (expand-file-name "config/" user-emacs-directory)
				no-littering-var-directory (expand-file-name "data/" user-emacs-directory)
				custom-file (no-littering-expand-etc-file-name "custom.el")))

;; Maximize the Emacs frame at startup
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

(setq gc-cons-threshold 100000000
	read-process-output-max (* 1024 1024)
	warning-minimum-level :error
	ring-bell-function 'ignore
	visible-bell t
	sentence-end-double-space nil
	save-interprogram-paste-before-kill t
	compilation-scroll-output 'first-error
	use-short-answers t
	fast-but-imprecise-scrolling t
	make-backup-files nil
	auto-save-default nil
	create-lockfiles nil
	auto-revert-mode t
	revert-without-query t
	sentence-end-double-space nil
	delete-selection-mode t
	column-number-mode t
	use-dialog-box nil
	set-charset-priority 'unicode
	prefer-coding-system 'utf-8-unix
	native-comp-async-report-warnings-errors nil)

(setq-default tab-width 2)

(blink-cursor-mode 0)
(set-fringe-mode 10)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(setq user-full-name "Simon Ho"
user-mail-address "simonho.ubc@gmail.com")

(setq custom-theme-directory (expand-file-name "themes/" user-emacs-directory))

(use-package autothemer
	:demand t
	:config
	(load-theme 'kanagawa t))

(set-frame-font "FiraCode NF-11")

(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(use-package nerd-icons
  :demand t)

(use-package nerd-icons-dired
  :after nerd-icons
  :hook
  (dired-mode . nerd-icons-dired-mode))

(use-package nerd-icons-completion
  :after (nerd-icons marginalia)
  :config
  (nerd-icons-completion-mode))

(use-package treemacs-nerd-icons
  :after (nerd-icons treemacs)
  :config
  (treemacs-load-theme "nerd-icons"))

(use-package doom-modeline
		:init
		(setq doom-modeline-height 30
		doom-modeline-project-detection 'auto
		doom-modeline-buffer-modification-icon t
		doom-modeline-lsp t
		doom-modeline-time-icon nil
		doom-modeline-highlight-modified-buffer-name t
		doom-modeline-position-column-line-format '("L%l:C%c")
		doom-modeline-minor-modes t
		doom-modeline-checker-simple-format nil
		doom-modeline-modal-icon t
		doom-modeline-modal-modern-icon t)
		(doom-modeline-mode 1))

	(use-package diminish)

	(defun diminish-modes ()
	(dolist (mode '((eldoc-mode)
									(lsp-lens-mode)
									))
		(diminish (car mode) (cdr mode))))

(add-hook 'elpaca-after-init-hook #'diminish-modes)

(use-package minions
	:demand t
	:config
	(minions-mode))

(use-package beacon
	:demand t
	:diminish
	:config
	(beacon-mode 1))

(use-package rainbow-mode
	:diminish
	:hook
	(prog-mode . rainbow-mode))

(use-package rainbow-delimiters
	:diminish
	:hook
	(prog-mode . rainbow-delimiters-mode))

(use-package dashboard
	:demand t
	:after projectile
	:init
	(setq
	 dashboard-banner-logo-title nil
	 dashboard-startup-banner (concat (expand-file-name "images/" user-emacs-directory) "zzz_small.png")
	 dashboard-projects-backend 'projectile
	 dashboard-center-content t
	 dashboard-display-icons-p t
	 dashboard-icon-type 'nerd-icons
	 dashboard-set-navigator t
	 dashboard-set-heading-icons t
	 dashboard-set-file-icons t
	 dashboard-show-shortcuts nil
	 dashboard-set-init-info t
	 dashboard-footer-messages '("if you have to wait for it to roar out of you, then wait patiently.\n   if it never does roar out of you, do something else.")
	 dashboard-footer-icon (nerd-icons-codicon "nf-cod-quote"
																						 :height 1.0
																						 :v-adjust -0.05
																						 :face 'font-lock-keyword-face)
	 dashboard-projects-switch-function 'projectile-persp-switch-project)
	(setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
	(setq dashboard-items '((recents  . 5)
				(projects . 5)))
	(setq dashboard-navigator-buttons
		`((
			(,(nerd-icons-sucicon "nf-seti-settings") "dotfiles" "Open Emacs config" (lambda (&rest _) (interactive) (find-file "~/dotfiles/emacs/custom/init.org")) warning)
			(,(nerd-icons-codicon "nf-cod-package") "Elpaca" "Update Packages" (lambda (&rest _) (elpaca-fetch-all)) error)
			)))
	:config
	(add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists)
	(add-hook 'elpaca-after-init-hook #'dashboard-initialize)
	(dashboard-setup-startup-hook))

(use-package evil
	:demand t
	:init
	(setq evil-want-integration t
	evil-want-keybinding nil
	evil-symbol-word-search t
	evil-respect-visual-line-mode t
	evil-ex-search-vim-style-regexp t
	evil-want-C-u-scroll t
	evil-want-C-i-jump nil)
	:config
	(setq evil-cross-lines t
	evil-kill-on-visual-paste nil
	evil-move-beyond-eol t
	evil-want-fine-undo t
	evil-v$-excludes-newline t)

	(setq evil-normal-state-cursor  '("#FF9E3B" box)
	evil-insert-state-cursor  '("#C34043" (bar . 2))
	evil-emacs-state-cursor   '("#FF9E3B" box)
	evil-replace-state-cursor '("#C34043" (hbar . 2))
	evil-visual-state-cursor  '("#76946A" (hbar . 2))
	evil-motion-state-cursor  '("#FF9E3B" box))

	(evil-set-undo-system 'undo-redo)
	(evil-mode 1))

(use-package evil-commentary
	:demand t
	:diminish
	:config
	(evil-commentary-mode))

(use-package evil-surround
	:demand t
	:diminish
	:config
	(global-evil-surround-mode 1))

(use-package which-key
	:demand t
	:diminish
	:init
	(setq 
	 which-key-idle-delay 0.1
	 which-key-idle-secondary-delay 0.01
	 which-key-allow-evil-operators t
	 which-key-add-column-padding 5
	 which-key-max-display-columns 5)
	(which-key-mode))

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
	:prefix ","
	:non-normal-prefix "M-,")
(major-mode-def "" nil)

;; Global Keybindings
(leader-def
:wk-full-keys nil
	"SPC"     '("M-x" . execute-extended-command)
	"TAB"     '("last buffer" . previous-buffer)
	"`"				'(eshell :wk "shell")
	"u"       '("universal arg" . universal-argument)
	"y"				'(consult-yank-pop :wk "kill ring")

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
	"wn"			'clone-frame
	"wo"			'other-frame

	"q"       (cons "quit" (make-sparse-keymap))
	"qd"      'restart-emacs-debug-init
	"qr"      'restart-emacs
	"qf"      'delete-frame
	"qq"      'save-buffers-kill-emacs
	)

(global-set-key (kbd "<escape>") 'keyboard-escape-quit)

(general-def universal-argument-map
		"SPC u" 'universal-argument-more)

(general-define-key
	:keymaps 'override
	"C-s" 'save-buffer)

(general-define-key
 :keymaps 'insert
 "TAB" 'tab-to-tab-stop
 "C-v" 'yank)

(defun system-is-mswindows ()
  (eq system-type 'windows-nt))

(use-package projectile
  :demand t
  :diminish
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
    "pp" '(projectile-persp-switch-project :wk "switch project")
    "pf" '(consult-project-buffer :wk "project files")
    "pa" '(projectile-add-known-project :wk "add project")
    "pd" '(projectile-remove-known-project :wk "remove project")
    "p!" '(projectile-run-shell-command-in-root :wk "run command in root")

    "p1" '((lambda () (interactive) (persp-switch-by-number 1)) :wk "project 1")
    "p2" '((lambda () (interactive) (persp-switch-by-number 2)) :wk "project 2")
    "p3" '((lambda () (interactive) (persp-switch-by-number 3)) :wk "project 3")
    "p4" '((lambda () (interactive) (persp-switch-by-number 4)) :wk "project 4")
    "p5" '((lambda () (interactive) (persp-switch-by-number 5)) :wk "project 5")
    ))

(use-package perspective
  :demand t
  :config
  (setq persp-initial-frame-name "default")
  (setq persp-suppress-no-prefix-key-warning t)
  (persp-mode))

(use-package persp-projectile
  :demand t
  :after (projectile perspective))

(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)                 ;; Enable auto completion
  (corfu-auto-delay 0.0)
  (corfu-quit-at-boundary 'separator)   
  (corfu-quit-no-match t)
  (corfu-echo-documentation 0.0)
  (corfu-preselect 'directory)      
  (corfu-on-exact-match 'quit)    
  :init
  (global-corfu-mode)
  (corfu-history-mode)
  (setq corfu-popupinfo-delay 0.2)
  (corfu-popupinfo-mode)
  :general
  (corfu-map
   "TAB" 'corfu-next
   [tab] 'corfu-next
   "S-TAB" 'corfu-previous
   [backtab] 'corfu-previous))

(use-package vertico
	:init
	(setq read-file-name-completion-ignore-case t
				read-buffer-completion-ignore-case t
				completion-ignore-case t
				vertico-resize t)
	(vertico-mode)
	(keymap-set vertico-map "TAB" #'minibuffer-complete)
	:general (:keymaps 'vertico-map
										 "C-j" 'vertico-next
										 "C-k" 'vertico-previous))

(elpaca nil (use-package vertico-mouse
	:after vertico)
	:config
	(vertico-mouse-mode))

;; Add prompt indicator to `completing-read-multiple'.
(defun crm-indicator (args)
	(cons (format "[CRM%s] %s"
								(replace-regexp-in-string
								 "\\`\\[.*?]\\*\\|\\[.*?]\\*\\'" ""
								 crm-separator)
								(car args))
				(cdr args)))
(advice-add #'completing-read-multiple :filter-args #'crm-indicator)

;; Do not allow the cursor in the minibuffer prompt
(setq minibuffer-prompt-properties
			'(read-only t cursor-intangible t face minibuffer-prompt))
(add-hook 'minibuffer-setup-hook #'cursor-intangible-mode)

;; Enable recursive minibuffers
(setq enable-recursive-minibuffers t)

(use-package orderless
	:demand t
	:config
	(setq completion-styles '(orderless basic substring partial-completion flex)
				completion-category-defaults nil
				completion-category-overrides '((file (styles partial-completion)))))

(use-package consult
	:config
	(add-to-list 'consult-preview-allowed-hooks 'global-org-modern-mode-check-buffers)
	(consult-customize
	 consult-theme consult-ripgrep consult-git-grep consult-grep
	 consult-bookmark consult-recent-file consult-xref
	 consult--source-bookmark consult--source-file-register
	 consult--source-recent-file consult--source-project-recent-file
	 :preview-key '(:debounce 0.5 any))
	(recentf-mode)
	(add-to-list 'recentf-exclude
							 (recentf-expand-file-name no-littering-var-directory))
	(add-to-list 'recentf-exclude
							 (recentf-expand-file-name no-littering-etc-directory))
	:general 
	(leader-def
		:wk-full-keys nil
		"b"       (cons "buffers" (make-sparse-keymap))
		"bb" '(persp-switch-to-buffer* :wk "find buffer")
		"bd" '(kill-current-buffer :wk "delete buffer")

		"f"       (cons "files" (make-sparse-keymap))
		"fed"       '((lambda () (interactive) (find-file "~/dotfiles/emacs/custom/init.org")) :wk "open Emacs config")
		"fs" '(save-buffer :wk "save") 
		"ff" '(find-file :wk "find file")
		"fr" '(consult-recent-file :wk "recent files")
		"ft" '(treemacs-select-window :wk "file tree")
		))

(use-package marginalia
	:defer 1
	:config
	(marginalia-mode))

(add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)

(use-package expand-region
:general
(leader-def
	:wk-full-keys nil
	"v" '(er/expand-region :wk "expand region")))

(use-package smart-hungry-delete
	:demand t
	:init (smart-hungry-delete-add-default-hooks)
	:general
	(general-imap "C-<backspace>" 'smart-hungry-delete-backward-char)
	(general-imap "C-<delete>" 'smart-hungry-delete-forward-char))

(use-package treemacs
	:demand t
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
	:demand t
	:after (treemacs evil))

(use-package treemacs-projectile
	:after (treemacs projectile))

(use-package treemacs-perspective
	:after (treemacs perspective)
	:config (treemacs-set-scope-type 'Perspectives))

(use-package centaur-tabs
	:demand t
	:init
	(setq centaur-tabs-style "bar"
				centaur-tabs-height 32
				centaur-tabs-set-icons t
				centaur-tabs-set-bar 'under
				x-underline-at-descent-line t
				centaur-tabs-cycle-scope 'tabs
				centaur-tabs-show-count t
				centaur-tabs-enable-ido-completion nil
				centaur-tabs-show-navigation-buttons nil
				centaur-tabs-show-new-tab-button t
				centaur-tabs-gray-out-icons 'buffer)
	:config
	(centaur-tabs-mode t)
	(centaur-tabs-headline-match)
	(centaur-tabs-group-by-projectile-project)
	:general
	(:keymaps 'evil-normal-state-map
						:prefix "g"
						"t" 'centaur-tabs-forward
						"T" 'centaur-tabs-backward))

(use-package format-all
	:diminish
	:commands format-all-mode
	:hook (prog-mode . format-all-mode)
	:config
	(setq-default format-all-formatters '(("Typescript" (prettierd))
																				("Javascript" (prettierd))
																				("Vue" (prettierd))
																				("GraphQL" (prettierd))
																				("Python" (black))
																				))
	:general
	(leader-def
		:wk-full-keys nil
		"c"       (cons "code" (make-sparse-keymap))
		"cf" '(format-all-region-or-buffer :wk "format")
		"cs" '(consult-line :wk "search")
		"co" '(consult-imenu :wk "outline")))

(use-package whitespace-cleanup-mode
	:demand t
	:diminish
	:config
	(global-whitespace-cleanup-mode))

(use-package anzu
:config
(global-anzu-mode +1)
:general
(leader-def
	:wk-full-keys nil
	"cr" '(anzu-query-replace-regexp :wk "replace")))

(use-package avy
	:demand t
	:general
	(leader-def
			:wk-full-keys nil
			"j"       (cons "jump" (make-sparse-keymap))
			"jj" 'avy-goto-char-timer
			"jl" 'avy-goto-line
			"jb" 'centaur-tabs-ace-jump
			"jw" 'ace-window))

(use-package ace-window
	:init
	(setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
				aw-minibuffer-flag t
				aw-ignore-current t))

(use-package ace-link)

(dolist (mode-mapping '((org-mode-map . ace-link-org)
												(Info-mode-map . ace-link-info)
												(help-mode-map . ace-link-help)
												(woman-mode-map . ace-link-woman)
												(eww-mode-map . ace-link-eww)
												(eww-link-keymap . ace-link-eww)
												))
	(let ((mode-map (car mode-mapping))
				(ace-link-command (cdr mode-mapping)))
		(general-nmap
			:keymaps mode-map
			:prefix "SPC"
			"jo" ace-link-command)))

(use-package lsp-mode
	:diminish
	:init
	(setq
	 lsp-modeline-diagnostics-enable nil
	 lsp-modeline-code-actions-mode t
	 lsp-modeline-code-actions-segments '(icon count)
	 lsp-modeline-code-action-fallback-icon (nerd-icons-codicon "nf-cod-lightbulb")
	 lsp-enable-snippet nil
	 lsp-headerline-breadcrumb-mode t
	 lsp-headerline-breadcrumb-segments '(file symbols)
	 lsp-warn-no-matched-clients nil
	 lsp-enable-suggest-server-download t)
	:hook ((prog-mode . lsp-deferred)
				 (lsp-mode . (lambda () (setq lsp-keymap-prefix "SPC l")
											 (lsp-enable-which-key-integration))))
	:commands (lsp lsp-deferred)
	:config
	(general-def 'normal lsp-mode :definer 'minor-mode
		"SPC l" lsp-command-map))

(use-package lsp-ui
	:commands lsp-ui-mode)

(use-package lsp-treemacs
	:init
	(lsp-treemacs-sync-mode 1)
	:commands lsp-treemacs-errors-list)

(use-package flycheck
	:diminish
	:init (global-flycheck-mode))

(use-package treesit-auto
	:demand t
:custom
(treesit-auto-install 'prompt)
:config
(treesit-auto-add-to-auto-mode-alist 'all)
(global-treesit-auto-mode))

(use-package git-gutter
	:demand t
	:diminish
	:init
	(custom-set-variables
	 '(git-gutter:update-interval 5)
	 '(git-gutter:modified-sign "~")
	 '(git-gutter:added-sign "+") 
	 '(git-gutter:deleted-sign "-"))
	:config
	(general-define-key
	 :states 'normal
	 "[h" '(git-gutter:previous-hunk :wk "previous hunk")
	 "]h" '(git-gutter:next-hunk :wk "next hunk"))
	(global-git-gutter-mode t))

(use-package npm
	:general
	(major-mode-def
		:keymaps '(js-mode-map typescript-ts-mode-map web-mode-map)
		:wk-full-keys nil
		"n" 'npm)
	)

(use-package lispy
  :hook
  (emacs-lisp-mode . lispy-mode))

(use-package lispyville
  :hook
  (emacs-lisp-mode . lispyville-mode))

(add-hook 'python-mode-hook (lambda () (setq-local tab-width 4)))

(use-package web-mode
	:init
	(add-to-list 'auto-mode-alist '("\\.vue\\'" . web-mode)))

(use-package toc-org
	:hook (org-mode . toc-org-mode))

(use-package org-modern
	:init
	(setq
	;; Edit settings
	org-auto-align-tags nil
	org-tags-column 0
	org-catch-invisible-edits 'show-and-error
	org-special-ctrl-a/e t
	org-insert-heading-respect-content t

	;; Org styling, hide markup etc.
	org-hide-emphasis-markers t
	org-pretty-entities t

	;; Agenda styling
	org-agenda-tags-column 0
	org-agenda-block-separator ?-)
	:hook
	(org-mode . global-org-modern-mode))

(use-package evil-org
	:diminish
	:hook (org-mode . evil-org-mode)
	:config (evil-org-set-key-theme '(textobjects insert navigation additional shift todo)))

(major-mode-def
	:keymaps 'org-mode-map
	:wk-full-keys nil
	"x" '(org-babel-execute-src-block :wk "execute block")
	"i"       (cons "insert" (make-sparse-keymap))
	"ic" '((lambda() (interactive) (org-insert-structure-template "src")) :wk "src block")
	"it" '((lambda() (interactive) (org-set-tags-command "TOC")) :wk "TOC"))
