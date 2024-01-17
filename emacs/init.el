;; -*- lexical-binding: t; -*- 
(defun org-babel-tangle-config ()
 (when (string-equal (file-name-nondirectory (buffer-file-name)) "init.org"))
 (let ((org-confirm-babel-evaluate nil))
   (org-babel-tangle)
   (message "%s tangled" buffer-file-name)))
 (add-hook 'org-mode-hook (lambda () (add-hook 'after-save-hook #'org-babel-tangle-config)))

(defun system-is-mswindows ()
  (eq system-type 'windows-nt))

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

(use-package explain-pause-mode :elpaca (:host github
		:repo "lastquestion/explain-pause-mode")
		:config
		(explain-pause-mode))

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
(add-to-list 'initial-frame-alist '(fullscreen . maximized))

;; Make sure conda python is found before emacs python
(setq python-path (if (system-is-mswindows)
											"~/anaconda3"
											"~/anaconda3/bin"))
(setq exec-path (cons python-path exec-path))

(setq gc-cons-threshold 100000000
	read-process-output-max (* 1024 1024)
	warning-minimum-level :error
	ring-bell-function 'ignore
	visible-bell t
	pixel-scroll-precision-mode t
	scroll-margin 3
	sentence-end-double-space nil
	save-interprogram-paste-before-kill t
	compilation-scroll-output 'first-error
	use-short-answers t
	make-backup-files nil
	auto-save-default nil
	create-lockfiles nil
	global-auto-revert-mode t
	global-auto-revert-non-file-buffers t
	revert-without-query t
	delete-selection-mode t
	column-number-mode t
	use-dialog-box nil
	confirm-kill-processes nil
	history-length 25
	kill-ring-max 50
	display-line-numbers-type 'relative
	set-charset-priority 'unicode
	prefer-coding-system 'utf-8-unix
	garbage-collection-messages t
	native-comp-async-report-warnings-errors nil)

	;; Run garbage collection when Emacs is idle for 15 seconds
	(run-with-idle-timer 15 t #'garbage-collect)

	;; Run garbage collection when the Emacs window loses focus
	(add-hook 'focus-out-hook 'garbage-collect)

(setq-default tab-width 2)

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

(set-frame-font "FiraCode Nerd Font-11")

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
:init
(setq beacon-blink-when-window-scrolls nil
beacon-blink-when-window-changes t
beacon-blink-when-point-moves t)
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
	(add-to-list
	'dimmer-prevent-dimming-predicates
	#'corfu-frame-p))
:config
(advice-add
 'dimmer-config-change-handler
 :override 'advise-dimmer-config-change-handler)
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
	 dashboard-startup-banner (concat (expand-file-name "images/" user-emacs-directory) "zzz_small.png")
	 dashboard-projects-backend 'projectile
	 dashboard-center-content t
	 dashboard-display-icons-p t
	 dashboard-icon-type 'nerd-icons
	 dashboard-set-navigator t
	 dashboard-set-heading-icons t
	 dashboard-set-file-icons t
	 dashboard-show-shortcuts t
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
	;; (setq dashboard-navigator-buttons
	;; 	`((
	;; 		(,(nerd-icons-sucicon "nf-seti-settings") "dotfiles" "Open Emacs config" (lambda (&rest _) (interactive) (find-file "~/dotfiles/emacs/init.org")) warning)
	;; 		(,(nerd-icons-codicon "nf-cod-package") "Elpaca" "Update Packages" (lambda (&rest _) (elpaca-fetch-all)) error)
	;; 		)))
	:config
	(add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists)
	(add-hook 'elpaca-after-init-hook #'dashboard-initialize)
	(dashboard-setup-startup-hook))

;; https://github.com/noctuid/evil-guide

	(use-package evil
		:demand t
		:init
		(setq
		 evil-want-integration t
		 evil-want-keybinding nil
		 evil-symbol-word-search t
		 evil-ex-search-vim-style-regexp t
		 evil-want-C-u-scroll t
		 evil-want-C-i-jump nil
		 evil-cross-lines t
		 evil-respect-visual-line-mode t
		 evil-kill-on-visual-paste nil
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
		(scroll-on-jump-advice-add evil-undo)
		(scroll-on-jump-advice-add evil-redo)
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

	(use-package evil-commentary
		:demand t
		:after evil
		:diminish
		:config
		(evil-commentary-mode))

	(use-package evil-surround
		:demand t
		:after evil
		:diminish
		:config
		(global-evil-surround-mode 1))

	(use-package evil-collection
		:demand t
		:after evil
		:config
		(evil-collection-init))

(defun mark-gg ()
	(interactive)
	(evil-set-marker ?g (point))
	(evil-goto-first-line)
	)

(defun mark-G ()
	(interactive)
	(evil-set-marker ?g (point))
	(end-of-buffer)
	)

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
	(evil-define-key '(normal visual) 'global
		"j" 'evil-next-visual-line
		"k" 'evil-previous-visual-line
		"gg" 'mark-gg
		"G"  'mark-G
		(kbd "<leader>SPC")     '("M-x" . execute-extended-command)
		(kbd "<leader>`")       '("shell" . eshell)
		(kbd "<leader>y")				'("kill ring" . consult-yank-pop)

		(kbd "<leader>hh") 			'("help" . helpful-at-point)
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
		(kbd "TAB") 'tab-to-tab-stop
		(kbd "<C-backspace>") 'backward-kill-spaces-or-char-or-word
		(kbd "<C-delete>") 'forward-kill-spaces-or-char-or-word
	)
)

(use-package which-key
	:demand t
	:diminish
	:init
	(setq 
	 which-key-idle-delay 0.3
	 which-key-idle-secondary-delay 0.01
	 which-key-allow-evil-operators t
	 which-key-add-column-padding 5
	 which-key-max-display-columns 6)
	(which-key-mode))

(use-package helpful)

(use-package projectile
  :demand t
  :diminish
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

(use-package corfu
  :custom
  (corfu-cycle t)
  (corfu-auto t)
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

	(evil-define-key 'nil corfu-map
   "TAB" 'corfu-next
   [tab] 'corfu-next
   "S-TAB" 'corfu-previous
   [backtab] 'corfu-previous)
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
	(setq completion-styles '(orderless basic substring partial-completion flex)
				completion-category-defaults nil
				completion-category-overrides '((file (styles partial-completion)))))

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
					dired-mouse-drag-files t
					mouse-drag-and-drop-region-cross-program t
					delete-by-moving-to-trash t
					dirvish-reuse-session t
					dired-listing-switches "-l --almost-all --human-readable --group-directories-first --no-group"
					dirvish-attributes '(nerd-icons subtree-state))
:hook
	(dired-mode . (lambda () (setq-local mouse-1-click-follows-link nil)))
:config
	(dirvish-override-dired-mode)
	(dirvish-side-follow-mode)
	(evil-define-key nil dirvish-mode-map
			(kbd "<mouse-1>") 'dirvish-subtree-toggle
			(kbd "<mouse-3>") 'dired-mouse-find-file-other-window
			(kbd "q")					'dirvish-quit
			(kbd "TAB")				'dirvish-subtree-toggle
			(kbd "<return>")  'dired-find-file
			(kbd "h")					'dired-up-directory
			(kbd "p")					'dirvish-yank
	)
)

(use-package centaur-tabs
	:demand t
	:init
	(setq centaur-tabs-style "bar"
				centaur-tabs-set-bar 'left
				centaur-tabs-modified-marker "\u2022"
				centaur-tabs-height 22
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
	:hook
	((dashboard-mode eshell-mode compilation-mode) . centaur-tabs-local-mode)
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
	"Format code using lsp-format if eglot is active, otherwise use format-all."
	(interactive)
	(if (bound-and-true-p eglot--managed-mode)
			(eglot-format)
		(format-all-region-or-buffer)))

(use-package format-all
	:diminish
	:commands format-all-mode
	:hook (prog-mode . format-all-mode)
	:config
	(setq-default format-all-formatters '(("Typescript" (prettierd))
																				("Javascript" (prettierd))
																				("Vue" (prettierd))
																				("GraphQL" (prettierd))
																				("Python" (ruff))
																				))
	(evil-define-key 'normal 'global
		(kbd "<leader>cf")    '("format all" . dual-format-function)
	)
)

(add-hook 'prog-mode-hook #'hs-minor-mode)

(use-package drag-stuff
:demand t
:config
(drag-stuff-global-mode 1)
(evil-define-key 'nil drag-stuff-mode-map
		(kbd "<M-up>")			'drag-stuff-up
		(kbd "<M-down>")		'drag-stuff-down
		(kbd "<M-left>")		'drag-stuff-left
		(kbd "<M-right>")   'drag-stuff-right
		)
)

(use-package vundo
	:demand t
	:init
	(setq vundo-glyph-alist vundo-unicode-symbols)
	:config
	(evil-define-key 'normal 'global
		(kbd "<leader>u")			'vundo
		)
)

(use-package aggressive-indent
:config
(global-aggressive-indent-mode 1))

(use-package anzu
:config
	(global-anzu-mode +1)
:init
	(evil-define-key 'normal 'global
		(kbd "<leader>cr")    '("search replace" . anzu-query-replace-regexp)
	)
)

(use-package copilot :elpaca (:host github
															:repo "zerolfx/copilot.el"
															:branch "main"
															:files ("dist" "*.el"))
	:init
	(setq copilot-indent-warning-suppress t)
	:hook
	(prog-mode . copilot-mode)
	(org-mode . copilot-mode)
	:config
	(evil-define-key 'nil copilot-completion-map
			(kbd "C-j")   'copilot-next-completion
			(kbd "C-k")   'copilot-previous-completion
			(kbd "C-l")   'copilot-accept-completion
			(kbd "M-l")   'copilot-accept-completion-by-word
			(kbd "ESC")   'copilot-clear-overlay
			)
)

(use-package avy
	:demand t
	:config
	(evil-define-key 'normal 'global
		(kbd "<leader>jj")   '("jump 2char" . avy-goto-char-2)
		(kbd "<leader>jl")   '("jump line" . avy-goto-line)
		(kbd "<leader>jb")   '("jump tab" . centaur-tabs-ace-jump)
		(kbd "<leader>jw")   '("jump window" . ace-window)
	)
)

(use-package ace-window
	:init
	(setq aw-keys '(?a ?s ?d ?f ?g ?h ?j ?k ?l)
				aw-minibuffer-flag t
				aw-ignore-current t))

;; (use-package lsp-mode
;; 	:diminish
;; 	:init
;; 	(setq
;; 	 lsp-modeline-diagnostics-enable nil
;; 	 lsp-modeline-code-actions-mode t
;; 	 lsp-modeline-code-actions-segments '(icon count)
;; 	 lsp-modeline-code-action-fallback-icon (nerd-icons-codicon "nf-cod-lightbulb")
;;	 lsp-log-io nil
;; 	 lsp-enable-snippet nil
;; 	 lsp-headerline-breadcrumb-mode t
;; 	 lsp-headerline-breadcrumb-segments '(file symbols)
;; 	 lsp-enable-symbol-highlighting t
;; 	 lsp-warn-no-matched-clients nil
;; 	 lsp-ui-peek-enable t
;; 	 lsp-ui-sideline-enable t
;; 	 lsp-ui-sideline-show-code-actions t
;; 	 lsp-ui-doc-show-with-cursor nil
;; 	 lsp-ui-doc-show-with-mouse nil
;; 	 lsp-enable-suggest-server-download t)
;; 	:hook ((prog-mode . lsp-deferred)
;; 				 (lsp-mode . (lambda () (setq lsp-keymap-prefix "SPC l")
;; 											 (lsp-enable-which-key-integration))))
;; 	:commands (lsp lsp-deferred)
;; 	:config
;; 	(evil-define-key 'normal lsp-mode :definer 'minor-mode
;; 		(kbd "<leader>l") lsp-command-map))

;; (use-package lsp-ui
;; 	:commands lsp-ui-mode)

;; (use-package consult-lsp
;; 	:after lsp-mode
;;  :config
;;	(evil-define-key 'normal 'global
;; 	(kbd "<leader>ld")   '("diagnostics" . consult-lsp-diagnostics)
;; 	(kbd "<leader>ls")   '("symbols" . consult-lsp-file-symbols)
;;	)
;;	)

(use-package eglot
	:elpaca nil
	:init
	(setq eglot-events-buffer-config '(:size 0))
	:config
	(setq eglot-inlay-hints-mode nil)
	(evil-define-key 'normal eglot-mode-map
		(kbd "<leader>lh")  '("help" . eldoc)
		(kbd "<leader>la")  '("code actions" . eglot-code-actions)
		(kbd "<leader>lf")  '("format" . eglot-format)
		(kbd "<leader>lR")  '("lsp rename" . eglot-rename)
		(kbd "<leader>ld")  '("definitions" . xref-find-definitions)
		(kbd "<leader>lD")  '("declarations" . xref-find-declaration)
		(kbd "<leader>lr")  '("references" . xref-find-references)
		(kbd "<leader>lt")  '("type definitions" . eglot-find-typeDefinition)
		(kbd "<leader>li")  '("implementations" . eglot-find-implementation))

	(setq-default eglot-workspace-configuration
								'((:pylsp . (:plugins (
																			 :ruff (:enabled t
																											 :lineLength 88
																											 :format {"I", "F", "E", "W", "D", "UP", "NP", "RUF"}
																											 :ignore {"D210"}
																											 :perFileIgnores { ["__init__.py"] = "CPY001" })
																			 :pydocstyle (:enabled t
																														 :convention "google")
																			 :pylsp_mypy (:enabled t
																														 :live_mode :json-false
																														 :dmypy t
																														 :exclude = ["**/tests/*"])
																			 )))))
	)

(defun vue-eglot-init-options ()
	(let ((tsdk-path (expand-file-name
										"lib"
										(shell-command-to-string "npm list --global --parseable typescript | head -n1 | tr -d \"\n\""))))
		`(:typescript (:tsdk ,tsdk-path
												 :languageFeatures (:completion
																						(:defaultTagNameCase "both"
																																 :defaultAttrNameCase "kebabCase"
																																 :getDocumentNameCasesRequest nil
																																 :getDocumentSelectionRequest nil)
																						:diagnostics
																						(:getDocumentVersionRequest nil))
												 :documentFeatures (:documentFormatting
																						(:defaultPrintWidth 100
																																:getDocumentPrintWidthRequest nil)
																						:documentSymbol t
																						:documentColor t)))))

(with-eval-after-load 'eglot
	(add-to-list 'eglot-server-programs
							 '(vue-mode . ("vue-language-server" "--stdio" :initializationOptions ,(vue-eglot-init-options)))
							 '(terraform-mode . ("terraform-ls" "serve"))
	))


(add-hook 'python-ts-mode-hook 'eglot-ensure)
(add-hook 'typescript-ts-mode-hook 'eglot-ensure)
(add-hook 'vue-mode-hook 'eglot-ensure)
(add-hook 'terraform-mode-hook 'eglot-ensure)

(setq treesit-font-lock-level 4)

(use-package evil-textobj-tree-sitter
	:demand t
	:after evil
	:config
	(evil-define-key nil evil-outer-text-objects-map
			"f" (evil-textobj-tree-sitter-get-textobj "function.outer")
			"c" (evil-textobj-tree-sitter-get-textobj "class.outer")
			"a" (evil-textobj-tree-sitter-get-textobj "parameter.outer"))
	(evil-define-key nil evil-inner-text-objects-map
			"f" (evil-textobj-tree-sitter-get-textobj "function.inner")
			"c" (evil-textobj-tree-sitter-get-textobj "class.inner")
			"a" (evil-textobj-tree-sitter-get-textobj "parameter.inner"))
)

(use-package diff-hl
:demand t 
:hook
(after-save . diff-hl-update)
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
	(evil-define-key 'nil org-src-mode-map
			(kbd "<localleader>q")  '("abort" . org-edit-src-abort)
			(kbd "<localleader>s")  '("save" . org-edit-src-exit)
	)
	(evil-define-key 'normal org-mode-map
			(kbd "<localleader>x")   '("execute block" . org-babel-execute-src-block)
			(kbd "<localleader>X")   '("execute all" . org-babel-execute-buffer)
			(kbd "<localleader>e")	 '("edit block" . org-edit-special)
			(kbd "<localleader>ie")  '("insert emacs-lisp" . (lambda() (interactive) (org-insert-structure-template "src emacs-lisp")))
			(kbd "<localleader>ip")  '("insert python" . (lambda() (interactive) (org-insert-structure-template "src python")))
			(kbd "<localleader>ij")  '("insert jupyer" . (lambda() (interactive) (org-insert-structure-template src-jupyter-block-header)))
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
	:diminish
	:hook (org-mode . evil-org-mode)
	:config (evil-org-set-key-theme '(textobjects insert navigation shift todo)))

(with-eval-after-load 'org
	(add-to-list 'org-structure-template-alist '("se" . "src emacs-lisp"))
	(add-to-list 'org-structure-template-alist '("sj" . src-jupyter-block-header))
	(add-to-list 'org-structure-template-alist '("sp" . "src python")))

(use-package markdown-mode)

(use-package npm)
(with-eval-after-load 'evil
	(evil-define-key 'normal web-mode-map
	(kbd "<localleader>n")  '("npm" . npm))
)

(with-eval-after-load 'evil
	(evil-define-key 'normal python-ts-mode-map
			(kbd "<localleader>s") '("start python" . run-python)
			(kbd "<localleader>x") '("send buffer" . python-shell-send-buffer))
)
(setq python-shell-interpreter (if (system-is-mswindows)
											"python.exe"
											"python3"))

(setq lsp-ruff-lsp-python-path (if (system-is-mswindows)
											"python.exe"
											"python3"))

(add-to-list 'major-mode-remap-alist '(python-mode . python-ts-mode))
(add-hook 'python-mode-hook (lambda () (setq-local tab-width 4)))

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

(use-package terraform-mode
:custom (terraform-format-on-save t))

(add-to-list 'auto-mode-alist '("\\.tf\\(vars\\)?\\'" . terraform-mode))

(add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode))

(use-package graphql-ts-mode
  :demand t
  :mode ("\\.graphql\\'" "\\.gql\\'")
  :config
  (with-eval-after-load 'treesit
    (add-to-list 'treesit-language-source-alist
                 '(graphql "https://github.com/bkegley/tree-sitter-graphql"))))
