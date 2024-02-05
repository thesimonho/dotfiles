;; -*- lexical-binding: t; -*-
(defun org-babel-tangle-config ()
	(when (string-equal (file-name-nondirectory (buffer-file-name)) "init.org"))
	(let ((org-confirm-babel-evaluate nil))
		(org-babel-tangle)
		(message "%s tangled" buffer-file-name)))
(add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'org-babel-tangle-config)))

(defun system-is-mswindows ()
	(eq system-type 'windows-nt))

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

(elpaca-no-symlink-mode)

;; Install use-package support
(elpaca elpaca-use-package
	;; Enable :elpaca use-package keyword.
	(elpaca-use-package-mode)
	;; Assume :elpaca t unless otherwise specified.
	(setq elpaca-use-package-by-default t))

;; Block until current queue processed.
(elpaca-wait)

(setq use-package-verbose nil  ; don't print anything
			use-package-compute-statistics t ; compute statistics about package initialization
			use-package-minimum-reported-time 0.0001
			use-package-always-defer t)	; always defer, don't "require", except when :demand

(use-package no-littering
	:init
	(setq no-littering-etc-directory (expand-file-name "config/" user-emacs-directory)
				no-littering-var-directory (expand-file-name "data/" user-emacs-directory)
				custom-file (no-littering-expand-etc-file-name "custom.el"))
	(recentf-mode 1)
	(add-to-list 'recentf-exclude
							 (recentf-expand-file-name no-littering-var-directory))
	(add-to-list 'recentf-exclude
							 (recentf-expand-file-name no-littering-etc-directory)))

(defun gc-buffers-scratch (buffer)
	(string= (buffer-name buffer) "*scratch*"))

(use-package gc-buffers :elpaca (:host "www.codeberg.org"
																			 :repo "akib/emacs-gc-buffers")
	:config
	(add-to-list 'gc-buffers-functions #'gc-buffers-scratch)
	(gc-buffers-mode t))

;; Maximize the Emacs frame at startup
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(add-to-list 'default-frame-alist '(alpha-background . 92))

(setq gc-cons-threshold 100000000
			read-process-output-max (* 1024 1024)
			auto-save-default nil
			column-number-mode t
			compilation-scroll-output 'first-error
			confirm-kill-processes nil
			create-lockfiles nil
			delete-selection-mode t
			display-line-numbers-type 'relative
			garbage-collection-messages nil
			global-auto-revert-mode t
			global-auto-revert-non-file-buffers t
			history-length 35
			kill-ring-max 20
			make-backup-files nil
			max-mini-window-height 0.1
			native-comp-async-report-warnings-errors nil
			package-install-upgrade-built-in t
			pixel-scroll-precision-mode t
			prefer-coding-system 'utf-8-unix
			revert-without-query t
			ring-bell-function 'ignore
			save-interprogram-paste-before-kill t
			scroll-margin 10
			scroll-conservatively 101
			sentence-end-double-space nil
			set-charset-priority 'unicode
			use-dialog-box nil
			use-short-answers t
			visible-bell t
			warning-minimum-level :error
			x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING))

(setq-default tab-width 2
							standard-indent 2)

;; Run garbage collection when Emacs is idle for 15 seconds
(run-with-idle-timer 15 t #'garbage-collect)

;; Run garbage collection when the Emacs window loses focus
(add-hook 'focus-out-hook 'garbage-collect)

(set-clipboard-coding-system 'utf-8-unix)
(savehist-mode 1)
(save-place-mode 1)
(blink-cursor-mode 0)
(global-hl-line-mode 1)
(set-fringe-mode 10)
(tool-bar-mode -1)
(scroll-bar-mode -1)

(setq user-full-name "Simon Ho"
			user-mail-address "simonho.ubc@gmail.com")

(setq custom-theme-directory (expand-file-name "themes/" user-emacs-directory))

(use-package autothemer
	:demand t
	:config
	(load-theme 'kanagawa-paper t))

(add-to-list 'default-frame-alist '(font . "FiraCode Nerd Font-11"))

(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(use-package nerd-icons
	:demand t)

(use-package nerd-icons-completion
	:after (nerd-icons marginalia)
	:config
	(nerd-icons-completion-mode))

(use-package doom-modeline
	:init
	(setq doom-modeline-height 30
				doom-modeline-hud nil
				doom-modeline-project-detection 'auto
				doom-modeline-display-default-persp-name nil
				doom-modeline-buffer-modification-icon nil
				doom-modeline-buffer-encoding nil
				doom-modeline-buffer-file-name-style 'relative-to-project
				doom-modeline-lsp t
				doom-modeline-time-icon nil
				doom-modeline-highlight-modified-buffer-name t
				doom-modeline-position-column-line-format '("L:%l")
				doom-modeline-minor-modes t
				doom-modeline-checker-simple-format nil
				doom-modeline-major-mode-icon nil
				doom-modeline-modal-icon t
				doom-modeline-modal-modern-icon t)
	(doom-modeline-mode 1))

(use-package minions
	:demand t
	:config
	(minions-mode))

(use-package beacon
	:demand t
	:init
	(setq beacon-blink-when-window-scrolls nil
				beacon-blink-when-window-changes t
				beacon-blink-when-point-moves t)
	:config
	(beacon-mode 1))

(use-package rainbow-mode
	:hook
	(prog-mode . rainbow-mode))

(use-package rainbow-delimiters
	:hook
	(prog-mode . rainbow-delimiters-mode))

(use-package indent-guide
	:hook
	(prog-mode . indent-guide-mode))

(use-package hl-todo
	:demand t
	:after evil
	:config
	(evil-define-key 'normal 'global
		(kbd "[t") 'hl-todo-previous
		(kbd "]t") 'hl-todo-next)
	(global-hl-todo-mode 1))

(use-package yascroll
	:demand t
	:custom
	(yascroll:disabled-modes '(magit-log-mode))
	(yascroll:delay-to-hide nil)
	(yascroll:scroll-bar 'right-fringe)
	:config
	(global-yascroll-bar-mode 1))

(use-package dimmer
	:demand t
	:init
	(setq dimmer-fraction 0.5
				dimmer-adjustment-mode :foreground
				dimmer-watch-frame-focus-events nil)

	(defun advise-dimmer-config-change-handler ()
		"Advise to only force process if no predicate is truthy."
		(let ((ignore (cl-some (lambda (f) (and (fboundp f) (funcall f)))
													 dimmer-prevent-dimming-predicates)))
			(unless ignore
				(when (fboundp 'dimmer-process-all)
					(dimmer-process-all t)))))

	(defun corfu-frame-p ()
		"Check if the buffer is a corfu frame buffer."
		(string-match-p "\\` \\*corfu" (buffer-name)))

	(defun dimmer-configure-corfu ()
		"Convenience settings for corfu users."
		(add-to-list 'dimmer-prevent-dimming-predicates #'corfu-frame-p))
	:config
	(advice-add 'dimmer-config-change-handler :override 'advise-dimmer-config-change-handler)
	(dimmer-configure-corfu)
	(dimmer-configure-which-key)
	(dimmer-configure-hydra)
	(dimmer-configure-magit)
	(dimmer-configure-org)
	(dimmer-configure-posframe)
	(dimmer-mode t))

(use-package dashboard
	:demand t
	:after projectile
	:init
	(setq
	 dashboard-banner-logo-title nil
	 dashboard-startup-banner (concat (expand-file-name "images/" user-emacs-directory) "zzz_small.webp")
	 dashboard-projects-backend 'projectile
	 dashboard-center-content t
	 dashboard-display-icons-p t
	 dashboard-icon-type 'nerd-icons
	 dashboard-set-navigator t
	 dashboard-set-heading-icons t
	 dashboard-set-file-icons t
	 dashboard-set-init-info t
	 dashboard-show-shortcuts t
	 dashboard-footer-messages '("if you have to wait for it to roar out of you, then wait patiently.\n   if it never does roar out of you, do something else.")
	 dashboard-footer-icon (nerd-icons-codicon "nf-cod-quote"
																						 :height 1.0
																						 :v-adjust -0.05
																						 :face 'font-lock-keyword-face)
	 dashboard-projects-switch-function 'projectile-persp-switch-project)
	(setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
	(setq dashboard-items '((recents  . 10)
													(projects . 5)))
	(setq dashboard-navigator-buttons
				`((
					 ;; (,(nerd-icons-sucicon "nf-seti-settings") "dotfiles" "Open Emacs config" (lambda (&rest _) (interactive) (find-file "~/dotfiles/emacs/init.org")) warning)
					 (,(nerd-icons-codicon "nf-cod-package") " Elpaca" "Elpaca Manager UI" (lambda (&rest _) (elpaca-manager)) error)
					 )))
	:config
	(add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists)
	(add-hook 'elpaca-after-init-hook #'dashboard-initialize)
	(dashboard-setup-startup-hook))

;; https://github.com/noctuid/evil-guide

(use-package evil
	:demand t
	:init
	(setq
	 evil-cross-lines t
	 evil-ex-search-vim-style-regexp t
	 evil-kill-on-visual-paste nil
	 evil-move-cursor-back nil
	 evil-respect-visual-line-mode t
	 evil-symbol-word-search t
	 evil-want-integration t
	 evil-want-keybinding nil
	 evil-want-C-u-scroll t
	 evil-want-C-i-jump nil
	 evil-want-fine-undo t
	 evil-v$-excludes-newline t
	 evil-normal-state-cursor  '("#FF9E3B" box)
	 evil-insert-state-cursor  '("#C34043" (bar . 2))
	 evil-emacs-state-cursor   '("#FF9E3B" box)
	 evil-replace-state-cursor '("#C34043" (hbar . 2))
	 evil-visual-state-cursor  '("#76946A" (hbar . 2))
	 evil-motion-state-cursor  '("#FF9E3B" box))
	:config
	(evil-set-leader nil (kbd "SPC"))
	(evil-set-leader nil "," t)
	(evil-set-undo-system 'undo-redo)
	(evil-mode 1))

(use-package scroll-on-jump
	:demand t
	:after evil
	:init
	(setq scroll-on-jump-duration 0.4
				scroll-on-jump-smooth t
				scroll-on-jump-curve 'smooth)
	:config
	(with-eval-after-load 'evil
		(scroll-on-jump-advice-add evil-jump-item)
		(scroll-on-jump-advice-add evil-jump-forward)
		(scroll-on-jump-advice-add evil-jump-backward)
		(scroll-on-jump-advice-add evil-search-next)
		(scroll-on-jump-advice-add evil-search-previous)
		(scroll-on-jump-advice-add evil-ex-search-next)
		(scroll-on-jump-advice-add evil-ex-search-previous)
		(scroll-on-jump-advice-add evil-forward-paragraph)
		(scroll-on-jump-advice-add evil-backward-paragraph)
		(scroll-on-jump-advice-add evil-goto-mark)

		(scroll-on-jump-with-scroll-advice-add evil-scroll-down)
		(scroll-on-jump-with-scroll-advice-add evil-scroll-up)
		(scroll-on-jump-with-scroll-advice-add evil-scroll-line-to-center)
		(scroll-on-jump-with-scroll-advice-add evil-scroll-line-to-top)
		(scroll-on-jump-with-scroll-advice-add evil-scroll-line-to-bottom))

	(with-eval-after-load 'goto-chg
		(scroll-on-jump-advice-add goto-last-change)
		(scroll-on-jump-advice-add goto-last-change-reverse)))

(use-package evil-escape
	:demand t
	:after evil
	:init
	(setq-default evil-escape-key-sequence "kj"
								evil-escape-delay 0.1
								evil-escape-unordered-key-sequence nil)
	:config
	(evil-escape-mode))

(use-package evil-commentary
	:demand t
	:after evil
	:config
	(evil-commentary-mode))

(use-package evil-surround
	:demand t
	:after evil
	:config
	(global-evil-surround-mode 1))

(use-package evil-collection
	:demand t
	:after evil
	:custom
	(evil-collection-corfu-key-themes '(default tab-n-go))
	:config
	(evil-collection-init '(corfu dashboard diff-hl dired eldoc elpaca lsp-ui-imenu magit magit-section magit-todos which-key)))

(defun backward-kill-spaces-or-char-or-word ()
	(interactive)
	(cond
	 ((looking-back (rx (char word)) 1)
		(backward-kill-word 1))
	 ((looking-back (rx (char blank)) 1)
		(delete-horizontal-space t))
	 (t
		(backward-delete-char 1))))

(defun forward-kill-spaces-or-char-or-word ()
	(interactive)
	(cond
	 ((looking-at (rx (char word)) 1)
		(kill-word 1))
	 ((looking-at (rx (char blank)) 1)
		(delete-horizontal-space))
	 (t
		(delete-forward-char 1))))

(with-eval-after-load 'evil
	(evil-define-motion mark-gg ()
		"Set mark at point and go to top of buffer."
		:type inclusive
		(evil-set-marker ?g (point))
		(evil-goto-first-line))

	(evil-define-motion mark-G ()
		"Set mark at point and go to end of buffer."
		:type inclusive
		(evil-set-marker ?g (point))
		(end-of-buffer))

	(evil-define-key '(normal visual) 'global
		"j" 'evil-next-visual-line
		"k" 'evil-previous-visual-line
		"gg" 'mark-gg
		"G"  'mark-G
		(kbd "<leader>SPC")     '("M-x" . execute-extended-command)
		(kbd "<leader>`")       '("shell" . eshell)
		(kbd "<leader>y")				'("kill ring" . consult-yank-pop)

		(kbd "<leader>hh") 			'("help at point" . helpful-at-point)
		(kbd "<leader>hb")      '("bindings" . describe-bindings)
		(kbd "<leader>hc")      '("character" . describe-char)
		(kbd "<leader>hf")      '("function" . helpful-callable)
		(kbd "<leader>hF")      '("face" . describe-face)
		(kbd "<leader>he")      '("Emacs manual" . info-emacs-manual)
		(kbd "<leader>hk")      '("key" . helpful-key)
		(kbd "<leader>hK")      '("keymap" . describe-keymap)
		(kbd "<leader>hm")      '("mode" . describe-mode)
		(kbd "<leader>hM")      '("woman" . woman)
		(kbd "<leader>hp")      '("package" . describe-package)
		(kbd "<leader>ht")      '("text" . describe-text-properties)
		(kbd "<leader>hv")      '("variable" . helpful-variable)

		(kbd "<leader>wm")      '("minibuffer" . switch-to-minibuffer)
		(kbd "<leader>wd")      '("delete" . delete-window)
		(kbd "<leader>wD")      '("delete others" . delete-other-windows)
		(kbd "<leader>wh")      '("left" . evil-window-left)
		(kbd "<leader>wj")      '("down" . evil-window-down)
		(kbd "<leader>wk")      '("up" . evil-window-up)
		(kbd "<leader>wl")      '("right" . evil-window-right)
		(kbd "<leader>wr")      '("rotate" . rotate-windows-forward)
		(kbd "<leader>wu")      '("winner undo" . winner-undo)
		(kbd "<leader>wU")      '("winner redo" . winner-redo)
		(kbd "<leader>ws")      '("split vertical" . split-window-vertically)
		(kbd "<leader>wv")      '("split horizontal" . split-window-horizontally)
		(kbd "<leader>wn")			'("new frame" . clone-frame)
		(kbd "<leader>wo")			'("switch frame" . other-frame)

		(kbd "<leader>zk")		  '("key history" . view-lossage)
		(kbd "<leader>zu")		  '("use package report" . use-package-report)
		(kbd "<leader>zp")		  '("profiler start" . profiler-start)
		(kbd "<leader>zP")		  '("profiler report" . profiler-report)

		(kbd "<leader>qr")      '("restart" . restart-emacs)
		(kbd "<leader>qR")			'("toggle debug on quit" . toggle-debug-on-quit)
		(kbd "<leader>qq")      '("kill frame" . delete-frame)
		(kbd "<leader>qQ")      '("kill emacs" . save-buffers-kill-emacs)
		)

	(evil-define-key nil 'global
		(kbd "M-u")			 'universal-argument
		(kbd "<escape>") 'keyboard-escape-quit
		)

	(evil-define-key '(normal insert) 'global
		(kbd "C-s") 'save-buffer
		(kbd "C-v") 'yank
		)

	(evil-define-key 'insert 'global
		(kbd "TAB")						'tab-to-tab-stop
		(kbd "<C-backspace>") 'backward-kill-spaces-or-char-or-word
		(kbd "<C-delete>")		'forward-kill-spaces-or-char-or-word
		)
	)

(use-package which-key
	:demand t
	:init
	(setq
	 which-key-allow-evil-operators t
	 which-key-add-column-padding 5
	 which-key-idle-delay 0.3
	 which-key-idle-secondary-delay 0.01
	 which-key-max-display-columns 6)
	:config
	(which-key-add-key-based-replacements
		"<SPC> b" "Buffers"
		"<SPC> c" "Code"
		"<SPC> f" "Files"
		"<SPC> h" "Help"
		"<SPC> j" "Jump"
		"<SPC> p" "Projects"
		"<SPC> q" "Quit"
		"<SPC> w" "Window"
		"<SPC> z" "Tools"
		", t"     "Tests"
		)
	(which-key-mode))

(use-package helpful)

(use-package projectile
	:demand t
	:init
	(when (and (system-is-mswindows) (executable-find "find")
						 (not (file-in-directory-p
									 (executable-find "find") "C:\\Windows")))
		(setq projectile-indexing-method 'alien
					projectile-generic-command "find . -type f")
		projectile-project-search-path '("/mnt/Projects")
		projectile-sort-order 'recently-active
		projectile-enable-caching t
		projectile-require-project-root t
		projectile-current-project-on-switch t
		projectile-switch-project-action #'projectile-find-file
		)
	:config
	(projectile-mode)
	(evil-define-key 'normal 'global
		(kbd "<leader>pp")     '("switch project" . projectile-persp-switch-project)
		(kbd "<leader>pf")     '("project files" . project-find-file)
		(kbd "<leader>pa")     '("add project" . projectile-add-known-project)
		(kbd "<leader>pd")     '("close project" . persp-kill)
		(kbd "<leader>px")     '("remove project" . projectile-remove-known-project)
		(kbd "<leader>p!")     '("run command in root" . projectile-run-shell-command-in-root)

		(kbd "<leader>p1")     '("project 1" . (lambda () (interactive) (persp-switch-by-number 1)))
		(kbd "<leader>p2")     '("project 2" . (lambda () (interactive) (persp-switch-by-number 2)))
		(kbd "<leader>p3")     '("project 3" . (lambda () (interactive) (persp-switch-by-number 3)))
		(kbd "<leader>p4")     '("project 4" . (lambda () (interactive) (persp-switch-by-number 4)))
		(kbd "<leader>p5")     '("project 5" . (lambda () (interactive) (persp-switch-by-number 5)))
		)
	)

(use-package perspective
	:demand t
	:config
	(setq persp-initial-frame-name "default")
	(setq persp-suppress-no-prefix-key-warning t)
	(persp-mode))

(use-package persp-projectile
	:demand t
	:after (projectile perspective))

(use-package magit
	:commands magit
	:init
	(evil-define-key 'normal 'global
		(kbd "<leader>g")  '("magit status" . magit)
		))

(use-package corfu
	:custom
	(corfu-cycle t)
	(corfu-auto t)
	(corfu-auto-delay 0.2)
	(corfu-count 15)
	(corfu-min-width 20)
	(corfu-quit-at-boundary t)
	(corfu-quit-no-match t)
	(corfu-echo-delay 0.0)
	(corfu-preselect 'directory)
	(corfu-on-exact-match 'quit)
	(corfu-popupinfo-delay '(2.0 . 1.0))
	:init
	(global-corfu-mode)
	(corfu-popupinfo-mode)
	(corfu-history-mode 1)
	(add-to-list 'savehist-additional-variables 'corfu-history)
	)

(use-package nerd-icons-corfu
	:demand t
	:after corfu
	:config
	(add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(defun cape-prog()
	(dolist (backend '(cape-dabbrev cape-file cape-keyword))
		(add-to-list 'completion-at-point-functions backend))
	)

(defun cape-elisp()
	(dolist (backend '(cape-dabbrev cape-elisp-block))
		(add-to-list 'completion-at-point-functions backend))
	)

(defun cape-text()
	(dolist (backend '(cape-dabbrev cape-emoji))
		(add-to-list 'completion-at-point-functions backend))
	)

(use-package cape
	:hook
	(prog-mode . cape-prog)
	(emacs-lisp-mode . cape-elisp)
	(org-mode . cape-elisp)
	(text-mode . cape-text)
	:init
	(setq cape-dabbrev-min-length 3
				cape-dabbrev-check-other-buffers 'some
				cape-file-directory-must-exist nil)
	)

(use-package dabbrev
	:elpaca nil
	:custom
	(dabbrev-upcase-means-case-search t)
	(dabbrev-check-all-buffers nil)
	(dabbrev-check-other-buffers t)
	(dabbrev-friend-buffer-function 'dabbrev--same-major-mode-p)
	(dabbrev-ignored-buffer-regexps '("\\.\\(?:pdf\\|jpe?g\\|png\\)\\'"))
	)

(use-package vertico
	:init
	(setq read-file-name-completion-ignore-case t
				read-buffer-completion-ignore-case t
				completion-ignore-case t
				eldoc-echo-area-use-multiline-p nil
				vertico-resize nil)
	(vertico-mode)
	(evil-define-key nil vertico-map
		(kbd "C-j") 'vertico-next
		(kbd "C-k") 'vertico-previous)
	)

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
	(setq completion-styles '(orderless partial-completion basic)
				completion-category-defaults nil
				completion-category-overrides nil))

(use-package consult
	:demand t
	:config
	(add-to-list 'consult-preview-allowed-hooks 'global-org-modern-mode-check-buffers)
	(consult-customize
	 consult-theme consult-ripgrep consult-git-grep consult-grep
	 consult-bookmark consult-recent-file consult-xref
	 consult--source-bookmark consult--source-file-register
	 consult--source-recent-file consult--source-project-recent-file
	 :preview-key '(:debounce 0.5 any))

	(evil-define-key 'normal 'global
		(kbd "<leader>bb")     '("find buffer" . consult-project-buffer)
		(kbd "<leader>bd")     '("delete buffer" . kill-current-buffer)
		(kbd "<leader>bD")     '("delete other buffers" . centaur-tabs-kill-other-buffers-in-current-group)

		(kbd "<leader>fs")     '("save" . save-buffer)
		(kbd "<leader>ff")     '("find file" . find-file)
		(kbd "<leader>fF")     '("locate file" . consult-locate)
		(kbd "<leader>fg")     '("grep string" . consult-ripgrep)
		(kbd "<leader>fr")     '("recent files" . consult-recent-file)
		(kbd "<leader>fd")     '("directory" . dirvish-side)

		(kbd "<leader>cs")     '("search" . consult-line)
		(kbd "<leader>co")     '("outline" . consult-imenu)
		)
	)

(use-package marginalia
	:defer 1
	:config
	(marginalia-mode))

(add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)

(use-package dirvish
	:init
	(setq dirvish-side-auto-expand t
				dirvish-side-width 30
				dirvish-use-header-line 'global
				dirvish-use-mode-line 'global
				dired-mouse-drag-files t
				mouse-drag-and-drop-region-cross-program t
				delete-by-moving-to-trash t
				dirvish-reuse-session t
				dired-listing-switches "-l -v --almost-all --human-readable --group-directories-first --no-group"
				dirvish-attributes '(nerd-icons subtree-state))
	:hook
	(dired-mode . (lambda () (setq-local mouse-1-click-follows-link nil)))
	:config
	(dirvish-override-dired-mode)
	(evil-define-key 'normal dirvish-mode-map
		(kbd "<mouse-1>") 'dirvish-subtree-toggle-or-open
		(kbd "<mouse-3>") 'dired-mouse-find-file-other-window
		(kbd "q")					'dirvish-quit
		(kbd "TAB")				'dirvish-subtree-toggle
		(kbd "<return>")  'dired-find-file
		(kbd "u")					'dired-up-directory
		(kbd "p")					'dirvish-yank
		(kbd "z")				  'dirvish-quicksort
		(kbd "s")				  'dirvish-ls-switches-menu
		)
	)

(use-package dired-gitignore
	:demand t
	:after dirvish
	:config
	(dired-gitignore-global-mode t))

(defun set-daemon-faces ()
	(set-face-attribute 'tab-line nil :background "#16161D")
	)

(use-package centaur-tabs
	:demand t
	:hook
	((dashboard-mode eshell-mode compilation-mode) . centaur-tabs-local-mode)
	(server-after-make-frame . set-daemon-faces)
	:init
	(setq centaur-tabs-style "bar"
				centaur-tabs-set-bar 'under
				x-underline-at-descent-line t
				centaur-tabs-modified-marker "\u2022"
				centaur-tabs-height 32
				centaur-tabs-set-icons t
				centaur-tabs-set-modified-marker t
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
	)

(defun centaur-tabs-buffer-groups ()
	"`centaur-tabs-buffer-groups' control buffers' group rules.

	Group centaur-tabs with mode if buffer is derived from `eshell-mode' `emacs-lisp-mode' `dired-mode' `org-mode' `magit-mode'.
	All buffer name start with * will group to \"Emacs\".
	Other buffer group by `centaur-tabs-get-group-name' with project name."
	(list
	 (cond
		((or (string-equal "*" (substring (buffer-name) 0 1))
				 (memq major-mode '(magit-process-mode
														magit-status-mode
														magit-diff-mode
														magit-log-mode
														magit-file-mode
														magit-blob-mode
														magit-blame-mode
														)))
		 "Emacs")
		((derived-mode-p 'prog-mode)
		 "Editing")
		((derived-mode-p 'dired-mode)
		 "Dired")
		((memq major-mode '(helpful-mode
												help-mode))
		 "Help")
		((memq major-mode '(org-mode
												org-agenda-clockreport-mode
												org-src-mode
												org-agenda-mode
												org-beamer-mode
												org-indent-mode
												org-bullets-mode
												org-cdlatex-mode
												org-agenda-log-mode
												diary-mode))
		 "OrgMode")
		(t
		 (centaur-tabs-get-group-name (current-buffer))))))

(defun centaur-tabs-hide-tab (x)
	"Do no to show buffer X in tabs."
	(let ((name (format "%s" x)))
		(or
		 ;; Current window is not dedicated window.
		 (window-dedicated-p (selected-window))

		 ;; Buffer name not match below blacklist.
		 (string-prefix-p "*epc" name)
		 (string-prefix-p "*helm" name)
		 (string-prefix-p "*Helm" name)
		 (string-prefix-p "*Compile-Log*" name)
		 (string-prefix-p "*lsp" name)
		 (string-prefix-p "*company" name)
		 (string-prefix-p "*Flycheck" name)
		 (string-prefix-p "*Flymake" name)
		 (string-prefix-p "*tramp" name)
		 (string-prefix-p " *Mini" name)
		 (string-prefix-p "*help" name)
		 (string-prefix-p "*straight" name)
		 (string-prefix-p " *temp" name)
		 (string-prefix-p "*Help" name)

		 ;; Is not magit buffer.
		 (and (string-prefix-p "magit" name)
					(not (file-name-extension name)))
		 )))

(defun dual-format-function ()
	"Format code using lsp-format if lsp-mode is active, otherwise use format-all."
	(interactive)
	(if (bound-and-true-p lsp-mode)
			(lsp-format-buffer)
		(format-all-region-or-buffer)))

;; (defun dual-format-function ()
;; 	"Format code using lsp-format if eglot is active, otherwise use format-all."
;; 	(interactive)
;; 	(if (bound-and-true-p eglot--managed-mode)
;; 			(eglot-format-buffer)
;; 		(format-all-region-or-buffer)))

(use-package format-all
	:demand t
	:commands (format-all-mode format-all-region-or-buffer)
	:init
	(setq format-all-show-errors 'errors)
	:config
	(setq-default format-all-formatters '(("Typescript" (prettierd))
																				("Javascript" (prettierd))
																				("Vue" (prettierd))
																				("GraphQL" (prettierd))
																				("Terraform" (terraform-fmt))
																				("Python" (ruff))
																				("Emacs Lisp" (emacs-lisp))
																				))
	(evil-define-key 'normal 'global
		(kbd "<leader>cf")    '("format all" . dual-format-function)
		)
	)

(add-hook 'prog-mode-hook #'hs-minor-mode)

;; (use-package copilot :elpaca (:host github
;; 																		:repo "zerolfx/copilot.el"
;; 																		:branch "main"
;; 																		:files ("dist" "*.el"))
;; 	:init
;; 	(setq copilot-indent-warning-suppress t)
;; 	:hook
;; 	(prog-mode . copilot-mode)
;; 	(org-mode . copilot-mode)
;; 	:config
;; 	(evil-define-key 'insert copilot-completion-map
;; 		(kbd "C-j")   'copilot-next-completion
;; 		(kbd "C-k")   'copilot-previous-completion
;; 		(kbd "C-l")   'copilot-accept-completion
;; 		(kbd "M-l")   'copilot-accept-completion-by-word
;; 		(kbd "ESC")   'copilot-clear-overlay
;; 		)
;; 	)

(use-package avy
	:demand t
	:config
	(evil-define-key 'normal 'global
		(kbd "<leader>jj")   '("jump 2char" . avy-goto-char-2)
		(kbd "<leader>jl")   '("jump line" . avy-goto-line)
		(kbd "<leader>jb")   '("jump tab" . centaur-tabs-ace-jump)
		)
	)

(use-package lsp-mode
	:init
	(setq lsp-auto-execute-action nil
				lsp-completion-enable nil  ;; disable this to allow cape to work
				lsp-completion-provider :none  ;; use corfu instead
				lsp-completion-show-detail t
				lsp-completion-show-kind t
				lsp-disabled-clients '(tfls)
				lsp-enable-links t
				lsp-enable-suggest-server-download t
				lsp-enable-snippet nil
				lsp-enable-symbol-highlighting t
				lsp-headerline-breadcrumb-mode t
				lsp-headerline-breadcrumb-segments '(file symbols)
				lsp-idle-delay 0.500
				lsp-log-io nil
				lsp-modeline-diagnostics-enable nil
				lsp-modeline-code-actions-mode t
				lsp-modeline-code-actions-segments '(icon count)
				lsp-modeline-code-action-fallback-icon (nerd-icons-codicon "nf-cod-lightbulb")
				lsp-progress-function 'lsp-on-progress-legacy
				lsp-progress-spinner-type 'moon
				lsp-semantic-tokens-enable t
				lsp-semantic-tokens-honor-refresh-requests t
				lsp-signature-auto-activate t
				lsp-signature-render-documentation nil
				lsp-symbol-highlighting-skip-current t
				lsp-warn-no-matched-clients nil
				lsp-ui-peek-enable t
				lsp-ui-sideline-enable t
				lsp-ui-sideline-show-code-actions nil
				lsp-ui-sideline-show-diagnostics t
				lsp-ui-sideline-show-hover nil
				lsp-ui-doc-enable nil
				lsp-ui-doc-show-with-cursor nil
				lsp-ui-doc-show-with-mouse nil
				;; lsp-pylsp-configuration-sources [""]
				lsp-pylsp-plugins-autopep8-enabled nil
				lsp-pylsp-plugins-black-enabled nil
				lsp-pylsp-plugins-flake8-enabled nil
				lsp-pylsp-plugins-isort-enabled nil
				lsp-pylsp-plugins-jedi-completion-enabled nil
				lsp-pylsp-plugins-mccabe-enabled nil
				lsp-pylsp-plugins-pycodestyle-enabled	nil
				;; lsp-pylsp-plugins-pycodestyle-max-line-length 88
				lsp-pylsp-plugins-pydocstyle-enabled nil
				;; lsp-pylsp-plugins-pydocstyle-convention "google"
				lsp-pylsp-plugins-pyflakes-enabled nil
				lsp-pylsp-plugins-pylint-enabled nil
				lsp-pylsp-plugins-rope-completion-enabled nil
				lsp-pylsp-plugins-yapf-enabled nil
				lsp-terraform-ls-enable-show-reference t
				lsp-terraform-ls-prefill-required-fields t
				lsp-terraform-ls-validate-on-save t
				)

	(defun my/orderless-dispatch-flex-first (_pattern index _total)
		(and (eq index 0) 'orderless-flex))

	(defun my/lsp-mode-setup-completion ()
		(setf (alist-get 'styles (alist-get 'lsp-capf completion-category-defaults))
					'(orderless))
		(add-hook 'orderless-style-dispatchers #'my/orderless-dispatch-flex-first nil 'local)
		(setq-local completion-at-point-functions (list (cape-capf-buster #'lsp-completion-at-point))))
	:hook ((prog-mode . lsp-deferred)
				 (lsp-completion-mode . my/lsp-mode-setup-completion)
				 (lsp-mode . lsp-enable-which-key-integration))
	:commands (lsp lsp-deferred)
	:config
	;; Pass additional settings to pylsp plugins
	(lsp-register-custom-settings '(("pylsp.plugins.ruff.enabled" t)
																	("pylsp.plugins.ruff.lineLength" 88)
																	("pylsp.plugins.ruff.ignore" "D")
																	))

	(evil-define-key 'normal lsp-mode-map
		(kbd "<leader>l <f2>")  '("rename" . lsp-rename)
		(kbd "<leader>lh")  '("help" . lsp-describe-thing-at-point)
		(kbd "<leader>la")  '("code actions" . lsp-execute-code-action)
		(kbd "<leader>lf")  '("format" . lsp-format-buffer)
		(kbd "<leader>ld")  '("definitions" . lsp-find-definition)
		(kbd "<leader>lD")  '("definitions peek" . xref-find-definitions)
		(kbd "<leader>lc")  '("declarations" . lsp-find-declaration)
		(kbd "<leader>lr")  '("references" . lsp-find-references)
		(kbd "<leader>lR")  '("references peek" . xref-find-references)
		(kbd "<leader>lt")  '("type definitions" . lsp-find-type-definition)
		(kbd "<leader>li")  '("implementations" . lsp-find-implementation)
		(kbd "<leader>lI")  '("implementations peek" . lsp-ui-peek-find-implementation)
		(kbd "<leader>lo")  '("organize imports" . lsp-organize-imports)
		)
	)

(use-package lsp-ui
	:commands lsp-ui-mode
	:config
	(define-key lsp-ui-mode-map [remap xref-find-definitions] #'lsp-ui-peek-find-definitions)
	(define-key lsp-ui-mode-map [remap xref-find-references] #'lsp-ui-peek-find-references)
	(evil-define-key 'nil lsp-ui-peek-mode-map
		(kbd "C-j")        '("next" . lsp-ui-peek--select-next)
		(kbd "C-k")        '("previous" . lsp-ui-peek--select-prev)
		(kbd "C-l")        '("next file" . lsp-ui-peek--select-next-file)
		(kbd "C-h")        '("previous file" . lsp-ui-peek--select-prev-file)
		)
	)

(use-package consult-lsp
	:demand t
	:after lsp-mode
	:config
	(define-key lsp-mode-map [remap xref-find-apropos] #'consult-lsp-symbols)
	(evil-define-key 'normal lsp-mode-map
		(kbd "<leader>le") '("diagnostics" . consult-lsp-diagnostics)
		(kbd "<leader>ls") '("symbols" . consult-lsp-symbols)))

;; (use-package eglot
;; 	:elpaca nil
;; 	:init
;; 	(setq eglot-events-buffer-config '(:size 0))
;; 	:config
;; 	(setq eglot-inlay-hints-mode nil
;; 				eglot-connect-timeout 120)
;; 	(evil-define-key 'normal eglot-mode-map
;; 		(kbd "<leader>lh")  '("help" . eldoc)
;; 		(kbd "<leader>la")  '("code actions" . eglot-code-actions)
;; 		(kbd "<leader>lf")  '("format" . eglot-format)
;; 		(kbd "<leader>lR")  '("lsp rename" . eglot-rename)
;; 		(kbd "<leader>ld")  '("definitions" . xref-find-definitions)
;; 		(kbd "<leader>lD")  '("declarations" . xref-find-declaration)
;; 		(kbd "<leader>lr")  '("references" . xref-find-references)
;; 		(kbd "<leader>lt")  '("type definitions" . eglot-find-typeDefinition)
;; 		(kbd "<leader>li")  '("implementations" . eglot-find-implementation))

;; 	(setq-default eglot-workspace-configuration
;; 								'((:pylsp . (:plugins (
;; 																			 :ruff (:enabled t
;; 																											 :lineLength 88
;; 																											 :format {"I", "F", "E", "W", "D", "UP", "NP", "RUF"}
;; 																											 :ignore {"D210"}
;; 																											 :perFileIgnores { ["__init__.py"] = "CPY001" })
;; 																			 :pydocstyle (:enabled t
;; 																														 :convention "google")
;; 																			 :pylsp_mypy (:enabled t
;; 																														 :live_mode :json-false
;; 																														 :dmypy t
;; 																														 :exclude = ["**/tests/*"])
;; 																			 )))))
;; 	)

;; ;; https://github.com/joaotavora/eglot/discussions/1184
;; (defun vue-eglot-init-options ()
;; 	(let ((tsdk-path (expand-file-name
;; 										"lib"
;; 										(shell-command-to-string "npm list --global --parseable typescript | head -n1 | tr -d \"\n\"")
;; 										)))
;; 		`(:typescript (:tsdk ,tsdk-path
;; 												 :languageFeatures (:completion
;; 																					 (:defaultTagNameCase "both"
;; 																																 :defaultAttrNameCase "kebabCase"
;; 																																 :getDocumentNameCasesRequest nil
;; 																																 :getDocumentSelectionRequest nil)
;; 																						:diagnostics
;; 																						(:getDocumentVersionRequest nil))
;; 												 :documentFeatures (:documentFormatting
;; 																						(:defaultPrintWidth 100
;; 																																:getDocumentPrintWidthRequest nil)
;; 																						:documentSymbol t
;; 																						:documentColor t)))))

;; (with-eval-after-load 'eglot
;; 	;; https://www.npmjs.com/package/@vue/language-server
;; 	(add-to-list 'eglot-server-programs
;; 							 '(vue-mode . ("vue-language-server" "--stdio" :initializationOptions ,(vue-eglot-init-options))))
;; 	;; https://github.com/hashicorp/terraform-ls
;; 	(add-to-list 'eglot-server-programs
;; 							 '(terraform-mode . ("terraform-ls" "serve")))
;; 	;; https://github.com/graphql/graphiql/tree/main/packages/graphql-language-service-cli
;; 	(add-to-list 'eglot-server-programs
;; 							 '(graphql-ts-mode . ("graphql-lsp" "server" "--method=stream")))
;; 	)

;; (add-hook 'python-ts-mode-hook 'eglot-ensure)
;; (add-hook 'typescript-ts-mode-hook 'eglot-ensure)
;; (add-hook 'vue-mode-hook 'eglot-ensure)
;; (add-hook 'terraform-mode-hook 'eglot-ensure)
;; (add-hook 'graphql-ts-mode-hook 'eglot-ensure)

(use-package flycheck
	:demand t
	:ensure t
	:custom
	(flycheck-display-errors-delay 0.2)
	:config
	(setq-default flycheck-disabled-checkers '(python-flake8 python-pylint python-mypy python-pycompile))
	(global-flycheck-mode))

(defvar-local my/flycheck-local-cache nil)

(defun my/flycheck-checker-get (fn checker property)
	(or (alist-get property (alist-get checker my/flycheck-local-cache))
			(funcall fn checker property)))

(advice-add 'flycheck-checker-get :around 'my/flycheck-checker-get)

(add-hook 'lsp-managed-mode-hook
					(lambda ()
						(when (derived-mode-p 'python-ts-mode)
							(setq my/flycheck-local-cache '((lsp . ((next-checkers . (python-pyright)))))))))

(setq treesit-font-lock-level 4)

(setq treesit-language-source-alist
			'((bash "https://github.com/tree-sitter/tree-sitter-bash")
				(cmake "https://github.com/uyha/tree-sitter-cmake")
				(css "https://github.com/tree-sitter/tree-sitter-css")
				(dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile")
				(elisp "https://github.com/Wilfred/tree-sitter-elisp")
				(go "https://github.com/tree-sitter/tree-sitter-go")
				(gomod "https://github.com/camdencheek/tree-sitter-go-mod")
				(graphql "https://github.com/bkegley/tree-sitter-graphql")
				(html "https://github.com/tree-sitter/tree-sitter-html")
				(javascript "https://github.com/tree-sitter/tree-sitter-javascript" "master" "src")
				(json "https://github.com/tree-sitter/tree-sitter-json")
				(make "https://github.com/alemuller/tree-sitter-make")
				(markdown "https://github.com/ikatyang/tree-sitter-markdown")
				(python "https://github.com/tree-sitter/tree-sitter-python")
				(toml "https://github.com/tree-sitter/tree-sitter-toml")
				(terraform "https://github.com/MichaHoffmann/tree-sitter-hcl")
				(tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
				(typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
				(yaml "https://github.com/ikatyang/tree-sitter-yaml")
				))

(use-package evil-textobj-tree-sitter
	:demand t
	:after evil
	:config
	(evil-define-key nil evil-outer-text-objects-map
		"f" (evil-textobj-tree-sitter-get-textobj "function.outer")
		"l" (evil-textobj-tree-sitter-get-textobj "loop.outer")
		"i" (evil-textobj-tree-sitter-get-textobj "conditional.outer")
		"c" (evil-textobj-tree-sitter-get-textobj "class.outer")
		"b" (evil-textobj-tree-sitter-get-textobj "block.outer")
		"a" (evil-textobj-tree-sitter-get-textobj "parameter.outer")
		)
	(evil-define-key nil evil-inner-text-objects-map
		"f" (evil-textobj-tree-sitter-get-textobj "function.inner")
		"l" (evil-textobj-tree-sitter-get-textobj "loop.inner")
		"i" (evil-textobj-tree-sitter-get-textobj "conditional.inner")
		"c" (evil-textobj-tree-sitter-get-textobj "class.inner")
		"b" (evil-textobj-tree-sitter-get-textobj "block.inner")
		"a" (evil-textobj-tree-sitter-get-textobj "parameter.inner")
		)
	)

(use-package diff-hl
	:demand t
	:hook
	(focus-in . diff-hl-update)
	(magit-pre-refresh . diff-hl-magit-pre-refresh)
	(magit-post-refresh . diff-hl-magit-post-refresh)
	:config
	(global-diff-hl-mode)
	(global-diff-hl-show-hunk-mouse-mode))

(use-package org
	:elpaca nil
	:defer t
	:config
	;; to avoid having to confirm each code block evaluation in the minibuffer
	(setq org-confirm-babel-evaluate nil)
	;; use python-mode in jupyter-python code blocks
	(org-babel-do-load-languages 'org-babel-load-languages '((python . t)
																													 (shell . t)
																													 (emacs-lisp . t)
																													 (jupyter . t)))
	(which-key-add-major-mode-key-based-replacements 'org-mode
		", i" "Insert"
		)
	(evil-define-key 'nil org-src-mode-map
		(kbd "<localleader>q")  '("abort" . org-edit-src-abort)
		(kbd "<localleader>s")  '("save" . org-edit-src-exit)
		)
	(evil-define-key 'normal org-mode-map
		(kbd "<localleader>x")   '("execute block" . org-babel-execute-src-block)
		(kbd "<localleader>X")   '("execute all" . org-babel-execute-buffer)
		(kbd "<localleader>e")	 '("edit block" . org-edit-special)
		(kbd "<localleader>ie")  '("emacs-lisp" . (lambda() (interactive) (org-insert-structure-template "src emacs-lisp")))
		(kbd "<localleader>ip")  '("python" . (lambda() (interactive) (org-insert-structure-template "src python")))
		(kbd "<localleader>ij")  '("jupyer" . (lambda() (interactive) (org-insert-structure-template src-jupyter-block-header)))
		)
	:hook
	(org-babel-after-execute . org-display-inline-images))

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
	 org-src-tab-acts-natively nil
	 org-insert-heading-respect-content t

	 ;; Org styling, hide markup etc.
	 org-hide-emphasis-markers nil
	 org-pretty-entities t

	 ;; Agenda styling
	 org-agenda-tags-column 0
	 org-agenda-block-separator ?-)
	:hook
	(org-mode . org-modern-mode))

(use-package evil-org
	:hook (org-mode . evil-org-mode)
	:config (evil-org-set-key-theme '(textobjects insert navigation shift todo)))

(with-eval-after-load 'org
	(add-to-list 'org-structure-template-alist '("se" . "src emacs-lisp"))
	(add-to-list 'org-structure-template-alist '("sj" . src-jupyter-block-header))
	(add-to-list 'org-structure-template-alist '("sp" . "src python")))

(use-package markdown-mode)

(with-eval-after-load 'evil
	(evil-define-key 'normal python-ts-mode-map
		(kbd "<localleader>s") '("start python" . run-python)
		(kbd "<localleader>x") '("send buffer" . python-shell-send-buffer))
	)

(setq python-shell-interpreter "~/.config/pdm/global-project/.venv/bin/python"
			python-shell-virtualenv-root "~/.config/pdm/global-project/.venv")

(add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))

(use-package pet
	:demand t
	:config
	(add-hook 'python-base-mode-hook 'pet-mode -10)
	(add-hook 'python-ts-mode-hook
						(lambda ()
							(setq-local python-shell-interpreter (pet-executable-find "python")
													python-shell-virtualenv-root (pet-virtualenv-root))

							(pet-flycheck-setup)

							(setq-local lsp-pylsp-server-command (pet-executable-find "pylsp"))
							(setq-local python-pytest-executable (pet-executable-find "pytest"))
							(setq-local dap-python-executable python-shell-interpreter)

							(setq-local lsp-jedi-executable-command (pet-executable-find "jedi-language-server")
													lsp-pylsp-plugins-jedi-environment python-shell-interpreter)

							(setq-local lsp-pyright-python-executable-cmd python-shell-interpreter
													lsp-pyright-venv-path python-shell-virtualenv-root)

							(when-let ((black-executable (pet-executable-find "black")))
								(setq-local python-black-command black-executable)
								(python-black-on-save-mode))

							(when-let ((isort-executable (pet-executable-find "isort")))
								(setq-local python-isort-command isort-executable)
								(python-isort-on-save-mode))))
	)

(use-package python-pytest
	:demand t
	:config
	(evil-define-key 'normal python-ts-mode-map
		(kbd "<localleader>t")   '("Tests" . python-pytest-dispatch)
		)
	)

(defvar src-jupyter-block-header "src jupyter-python :session jupyter :async yes")

(defun replace-current-header-with-src-jupyter ()
	(interactive)
	(move-beginning-of-line nil)
	(kill-line)
	(insert src-jupyter-block-header))

(defun replace-all-header-with-src-jupyter ()
	(interactive)
	(save-excursion
		(goto-char (point-min))
		(while (re-search-forward "^#\\+begin_src jupyter-python\\s-*$" nil t)
			(replace-match (concat "#+begin_" src-jupyter-block-header) nil nil))))

(use-package jupyter
	:after code-cells)

(use-package code-cells
	:init
	(setq code-cells-convert-ipynb-style '(("pandoc" "--to" "ipynb" "--from" "org")
																				 ("pandoc" "--to" "org" "--from" "ipynb")
																				 (lambda () #'org-mode)))
	(evil-define-key 'normal code-cells-mode-map
		(kbd "<localleader>D")   '("clear results" . jupyter-org-clear-all-results)
		(kbd "<localleader>r")   '("replace jupyter src" . replace-current-header-with-src-jupyter)
		(kbd "<localleader>R")   '("replace all jupyter src" .  replace-all-header-with-src-jupyter)
		)
	:hook
	((org-mode) . code-cells-mode)
	)

(use-package web-mode
	:init
	(define-derived-mode vue-mode web-mode "Vue")
	(add-to-list 'auto-mode-alist '("\\.vue\\'" . vue-mode)))

(add-to-list 'auto-mode-alist '("\\Dockerfile\\'" . dockerfile-ts-mode))

(use-package terraform-mode
	:custom (terraform-format-on-save nil))

(add-to-list 'auto-mode-alist '("\\.tf\\(vars\\)?\\'" . terraform-mode))

(add-to-list 'auto-mode-alist '("\\.ts\\(x\\)?\\'" . typescript-mode))
(add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode))

(use-package graphql-ts-mode
	:demand t
	:mode ("\\.graphql\\'" "\\.gql\\'"))

(add-to-list 'auto-mode-alist '("\\.go\\'" . go-ts-mode))
(add-to-list 'auto-mode-alist '("/go\\.mod\\'" . go-mod-ts-mode))
(setq go-ts-mode-indent-offset 2)

(use-package go-mode
	:mode ("\\.go\\'" "/go\\.mod\\'"))

(use-package gotest
	:demand t
	:config
	(evil-define-key 'normal go-ts-mode-map
		(kbd "<localleader>x")   '("run" . go-run)
		(kbd "<localleader>tc")   '("coverage" . go-test-current-coverage)
		(kbd "<localleader>tf")   '("test file" . go-test-current-file)
		(kbd "<localleader>tp")   '("test project" . go-test-current-project)
		)
	)
