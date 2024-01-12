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
:config
(general-define-key
:states 'normal
"[t" '(hl-todo-previous :wk "previous todo")
"]t" '(hl-todo-next :wk "next todo"))
(global-hl-todo-mode 1))

(use-package yascroll
:demand t
:custom
(yascroll:delay-to-hide nil)
(yascroll:scroll-bar 'right-fringe)
:config
(global-yascroll-bar-mode 1))

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
	;; (setq dashboard-navigator-buttons
	;; 	`((
	;; 		(,(nerd-icons-sucicon "nf-seti-settings") "dotfiles" "Open Emacs config" (lambda (&rest _) (interactive) (find-file "~/dotfiles/emacs/init.org")) warning)
	;; 		(,(nerd-icons-codicon "nf-cod-package") "Elpaca" "Update Packages" (lambda (&rest _) (elpaca-fetch-all)) error)
	;; 		)))
	:config
	(add-hook 'elpaca-after-init-hook #'dashboard-insert-startupify-lists)
	(add-hook 'elpaca-after-init-hook #'dashboard-initialize)
	(dashboard-setup-startup-hook))

(use-package general
	:demand t
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
	"`"				'(eshell :wk "eshell")
	"u"       '("universal arg" . universal-argument)
	"y"				'(consult-yank-pop :wk "kill ring")

	"h"       (cons "help" (make-sparse-keymap))
	"hh" 			'helpful-at-point
	"hb"      'describe-bindings
	"hc"      'describe-char
	"hf"      'helpful-callable
	"hF"      'describe-face
	"hi"      'info-emacs-manual
	"hI"      'info-display-manual
	"hk"      'helpful-key
	"hK"      'describe-keymap
	"hm"      'describe-mode
	"hM"      'woman
	"hp"      'describe-package
	"ht"      'describe-text-properties
	"hv"      'helpful-variable

	"w"       (cons "windows" (make-sparse-keymap))
	"wm"      'switch-to-minibuffer
	"wd"      'delete-window
	"wD"      'delete-other-windows
	"wh"      'evil-window-left
	"wj"      'evil-window-down
	"wk"      'evil-window-up
	"wl"      'evil-window-right
	"wr"      'rotate-windows-forward
	"ws"      'split-window-vertically
	"wu"      'winner-undo
	"wU"      'winner-redo
	"wv"      'split-window-horizontally
	"wn"			'(clone-frame :wk "new frame")
	"wo"			'(other-frame :wk "switch frame")

	"z" (cons "tools" (make-sparse-keymap))
	"zu" 'use-package-report
	"zp" 'profiler-start
	"zP" 'profiler-report
	"zd" 'toggle-debug-on-quit

	"q"       (cons "quit" (make-sparse-keymap))
	"qd"      'restart-emacs-debug-init
	"qr"      'restart-emacs
	"qq"      'delete-frame
	"qQ"      'save-buffers-kill-emacs
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

(use-package evil
	:demand t
	:after general
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
	 evil-v$-excludes-newline t)
	:config
	(setq evil-normal-state-cursor  '("#FF9E3B" box)
				evil-insert-state-cursor  '("#C34043" (bar . 2))
				evil-emacs-state-cursor   '("#FF9E3B" box)
				evil-replace-state-cursor '("#C34043" (hbar . 2))
				evil-visual-state-cursor  '("#76946A" (hbar . 2))
				evil-motion-state-cursor  '("#FF9E3B" box))
	(evil-define-key 'motion 'global
		"j" 'evil-next-visual-line
		"k" 'evil-previous-visual-line)
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
	:diminish
	:config
	(evil-commentary-mode))

(use-package evil-surround
	:demand t
	:diminish
	:config
	(global-evil-surround-mode 1))

(use-package evil-collection
:after evil
:demand t
:config
(evil-collection-init))

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
    "pf" '(project-find-file :wk "project files")
    "pa" '(projectile-add-known-project :wk "add project")
    "pd" '(persp-kill :wk "close project")
    "px" '(projectile-remove-known-project :wk "remove project")
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
				eldoc-echo-area-use-multiline-p nil
				vertico-resize nil)
	(vertico-mode)
	:general (:keymaps 'vertico-map
										 "C-j" 'vertico-next
										 "C-k" 'vertico-previous))

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
	:general 
	(leader-def
		:wk-full-keys nil
		"b"       (cons "buffers" (make-sparse-keymap))
		"bb" '(persp-switch-to-buffer* :wk "find buffer")
		"bd" '(kill-current-buffer :wk "delete buffer")
		"bD" '(centaur-tabs-kill-other-buffers-in-current-group :wk "delete other buffers")

		"f"       (cons "files" (make-sparse-keymap))
		"fs" '(save-buffer :wk "save") 
		"ff" '(find-file :wk "find file")
		"fF" '(consult-locate :wk "locate file")
		"fg" '(consult-ripgrep :wk "grep string")
		"fr" '(consult-recent-file :wk "recent files")
		"fd" '(dirvish-side :wk "directory")
		))

(use-package consult-todo
:demand t
:after (consult hl-todo))

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

(use-package dirvish
:init
(setq dirvish-side-auto-expand t
			dired-mouse-drag-files t
			mouse-drag-and-drop-region-cross-program t
			delete-by-moving-to-trash t
			dirvish-reuse-session t
			dired-listing-switches "-l --almost-all --human-readable --group-directories-first --no-group"
			dirvish-attributes '(nerd-icons subtree-state))
:config
(define-key dirvish-mode-map (kbd "<mouse-1>") 'dirvish-subtree-toggle)
(define-key dirvish-mode-map (kbd "<mouse-3>") 'dired-mouse-find-file-other-window)
(dirvish-override-dired-mode)
(dirvish-side-follow-mode)
:hook
(dired-mode . (lambda () (setq-local mouse-1-click-follows-link nil)))
:general
(:keymaps 'dirvish-mode-map
"q" ' dirvish-quit
"TAB" 'dirvish-subtree-toggle
"<return>" 'dired-find-file
"h" 'dired-up-directory
"p" 'dirvish-yank
))

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
	:general
	(:keymaps 'evil-normal-state-map
						:prefix "g"
						"t" 'centaur-tabs-forward
						"T" 'centaur-tabs-backward))

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
	:general
	(leader-def
		:wk-full-keys nil
		"c"       (cons "code" (make-sparse-keymap))
		"cf" '(format-all-region-or-buffer :wk "format")
		"cs" '(consult-line :wk "search")
		"ct" '(consult-todo-all :wk "todo")
		"co" '(consult-imenu :wk "outline")))

(use-package anzu
:config
(global-anzu-mode +1)
:general
(leader-def
	:wk-full-keys nil
	"cr" '(anzu-query-replace-regexp :wk "replace")))

(use-package copilot :elpaca (:host github
															:repo "zerolfx/copilot.el"
															:branch "main"
															:files ("dist" "*.el"))
	:init
	(setq copilot-indent-warning-suppress t)
	:hook
	(prog-mode . copilot-mode)
	(org-mode . copilot-mode)
	:general
	(:keymaps 'copilot-completion-map
						"C-j" 'copilot-next-completion
						"C-k" 'copilot-previous-completion
						"C-l" 'copilot-accept-completion
						"M-l" 'copilot-accept-completion-by-word
						"ESC" 'copilot-clear-overlay))

(use-package avy
	:demand t
	:general
	(leader-def
			:wk-full-keys nil
			"j"       (cons "jump" (make-sparse-keymap))
			"jj" 'avy-goto-char-2
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
	 lsp-enable-symbol-highlighting t
	 lsp-warn-no-matched-clients nil
	 lsp-ui-peek-enable t
	 lsp-ui-sideline-enable t
	 lsp-ui-sideline-show-code-actions t
	 lsp-ui-doc-show-with-cursor nil
	 lsp-ui-doc-show-with-mouse nil
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

(use-package consult-lsp
	:after lsp-mode
	:general
	(leader-def
	:wk-full-keys nil
	"ld" '(consult-lsp-diagnostics :wk "diagnostics")
	"ls" '(consult-lsp-file-symbols :wk "symbols")))

(setq treesit-font-lock-level 4)

(use-package treesit-auto
	:custom
	(treesit-auto-install 'prompt)
	:config
	(treesit-auto-add-to-auto-mode-alist 'all)
	:hook
	(prog-mode . treesit-auto-mode))

(use-package evil-textobj-tree-sitter
	:after evil
	:general
	(:keymaps 'evil-outer-text-objects-map
						"f" (evil-textobj-tree-sitter-get-textobj "function.outer")
						"c" (evil-textobj-tree-sitter-get-textobj "class.outer")
						"a" (evil-textobj-tree-sitter-get-textobj "parameter.outer"))
	(:keymaps 'evil-inner-text-objects-map
						"f" (evil-textobj-tree-sitter-get-textobj "function.inner")
						"c" (evil-textobj-tree-sitter-get-textobj "class.inner")
						"a" (evil-textobj-tree-sitter-get-textobj "parameter.inner"))
	)

(use-package diff-hl
:demand t 
:hook
(after-save . diff-hl-update)
:config
(global-diff-hl-mode))

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
	:config (evil-org-set-key-theme '(textobjects insert navigation additional shift todo)))

(with-eval-after-load 'org
	(add-to-list 'org-structure-template-alist '("se" . "src emacs-lisp"))
	(add-to-list 'org-structure-template-alist '("sj" . src-jupyter-block-header))
	(add-to-list 'org-structure-template-alist '("sp" . "src python")))

(major-mode-def
	:keymaps 'org-mode-map
	:wk-full-keys nil
	"x" '(org-babel-execute-src-block :wk "execute block")
	"X" '(org-babel-execute-buffer :wk "execute all")
	"e"			'(org-edit-special :wk "edit block")
	"i"      (cons "insert" (make-sparse-keymap))
	"is"     (cons "src block" (make-sparse-keymap))
	"ise"		'((lambda() (interactive) (org-insert-structure-template "src emacs-lisp")) :wk "emacs-lisp")
	"isp"		'((lambda() (interactive) (org-insert-structure-template "src python")) :wk "python")
	"isj"	  '((lambda() (interactive) (org-insert-structure-template src-jupyter-block-header)) :wk "jupyter")
	"it"		'((lambda() (interactive) (org-set-tags-command "TOC")) :wk "TOC"))

(use-package npm
	:general
	(major-mode-def
		:keymaps '(js-mode-map typescript-ts-mode-map web-mode-map)
		:wk-full-keys nil
		"n" 'npm))

(use-package lispyville
  :hook
  (emacs-lisp-mode . lispyville-mode))

(major-mode-def
	:keymaps 'python-ts-mode-map
	:wk-full-keys nil
	"s" 'run-python
	"x" 'python-shell-send-buffer)

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
	:hook
	((org-mode python-mode python-ts-mode) . code-cells-mode)
	:general
	(major-mode-def
	:keymaps 'code-cells-mode-map
	:wk-full-keys nil
	"D" '(jupyter-org-clear-all-results :wk "clear results")
	"r" '(replace-current-header-with-src-jupyter :wk "replace jupyter src")
	"R" '(replace-all-header-with-src-jupyter :wk "replace all jupyter src")
	))

(use-package web-mode
	:init
	(add-to-list 'auto-mode-alist '("\\.vue\\'" . web-mode)))

(use-package terraform-mode
:custom (terraform-format-on-save t))

(add-to-list 'major-mode-remap-alist '(typescript-mode . typescript-ts-mode))

(use-package graphql-ts-mode
  :demand t
  :mode ("\\.graphql\\'" "\\.gql\\'")
  :config
  (with-eval-after-load 'treesit
    (add-to-list 'treesit-language-source-alist
                 '(graphql "https://github.com/bkegley/tree-sitter-graphql"))))
