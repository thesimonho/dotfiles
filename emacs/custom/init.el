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
  
(setq use-package-verbose nil		; don't print anything
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
      tool-bar-mode 0
      use-dialog-box nil
      set-charset-priority 'unicode
      prefer-coding-system 'utf-8-unix)

;; Silence compiler warnings as they can be pretty disruptive
(setq native-comp-async-report-warnings-errors nil)

;; Set the right directory to store the native comp cache
(add-to-list 'native-comp-eln-load-path (expand-file-name "eln-cache/" user-emacs-directory))

(setq user-full-name "Simon Ho"
      user-mail-address "simonho.ubc@gmail.com")

(use-package autothemer
  :demand t
  :config
  (load-theme 'kanagawa t))

(set-frame-font "FiraCode NF-11")

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

(add-hook 'prog-mode-hook #'display-line-numbers-mode)

(use-package dashboard
  :demand t
  :after projectile
  :init
  (setq
   dashboard-startup-banner 'official
   dashboard-projects-backend 'projectile
   dashboard-center-content t
   dashboard-icon-type 'nerd-icons
   dashboard-set-heading-icons t
   dashboard-set-file-icons t
   dashboard-show-shortcuts nil
   dashboard-set-init-info t
   dashboard-footer-messages '("Dashboard is pretty cool!")
   dashboard-projects-switch-function 'projectile-persp-switch-project)
  (setq initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
  (setq dashboard-items '((recents  . 5)
			  (projects . 5)))
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
	evil-ex-search-vim-style-regexp t
	evil-want-C-u-scroll t
	evil-want-C-i-jump nil)
  :config
  (setq evil-cross-lines t
	evil-kill-on-visual-paste nil
	evil-move-beyond-eol t
	evil-want-fine-undo t
	evil-v$-excludes-newline t)

  (setq evil-normal-state-cursor  '("DarkGoldenrod2" box)
	evil-insert-state-cursor  '("chartreuse3" (bar . 2))
	evil-emacs-state-cursor   '("SkyBlue2" box)
	evil-replace-state-cursor '("chocolate" (hbar . 2))
	evil-visual-state-cursor  '("gray" (hbar . 2))
	evil-motion-state-cursor  '("plum3" box))

  (evil-set-undo-system 'undo-redo)
  (evil-mode 1))

(use-package which-key
  :demand t
  :init
  (setq 
   which-key-idle-delay 0.1
   which-key-idle-secondary-delay 0.01
   which-key-allow-evil-operators t
   which-key-add-column-padding 1
   which-key-max-display-columns 4)
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
  "TAB"     '("last buffer" . alternate-buffer)
  "u"       '("universal arg" . universal-argument)

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

  "q"       (cons "quit" (make-sparse-keymap))
  "qd"      'restart-emacs-debug-init
  "qr"      'restart-emacs
  "qf"      'delete-frame
  "qq"      'save-buffers-kill-emacs
  )

(general-def universal-argument-map
    "SPC u" 'universal-argument-more)

(general-define-key
  :keymaps 'override
  "C-s" 'save-buffer)

(general-define-key
 :keymaps 'insert
 "C-v" 'yank)

(defun system-is-mswindows ()
  (eq system-type 'windows-nt))

(use-package projectile
  :demand t
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
    (add-to-list 'consult-preview-allowed-hooks 'global-hl-todo-mode-check-buffers)
    (recentf-mode)
    :general 
    (leader-def
    :wk-full-keys nil
      "b"       (cons "buffers" (make-sparse-keymap))
      "bb" '(persp-switch-to-buffer :wk "find buffer")
      "bd" '(persp-kill-buffer :wk "delete buffer")

      "f"       (cons "files" (make-sparse-keymap))
      "fed"       '((lambda () (interactive) (find-file "~/dotfiles/emacs/custom/init.org")) :wk "Open Emacs config")
      "fs" '(save-buffer :wk "Save") 
      "ff" '(consult-dir :wk "find file")
      "fr" '(consult-recent-file :wk "recent files")
      "fg" '(consult-ripgrep :wk "grep")
      "ft" '(treemacs :wk "file tree")
  ))

  (use-package consult-dir)

  (use-package marginalia
    :defer 1
    :config
    (marginalia-mode))

(add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup)

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
	centaur-tabs-show-navigation-buttons t
	centaur-tabs-show-new-tab-button t
	centaur-tabs-gray-out-icons 'buffer)
  :config
  (centaur-tabs-mode t)
  (centaur-tabs-headline-match))

(use-package lsp-mode
    :init
    (setq
    lsp-modeline-diagnostics-enable t
    lsp-modeline-code-actions-mode t
    lsp-headerline-breadcrumb-mode t
    lsp-warn-no-matched-clients nil
    lsp-enable-suggest-server-download t)
    :hook ((prog-mode . lsp-deferred)
	   (lsp-mode . (lambda () (setq lsp-keymap-prefix "SPC l")
			 (lsp-enable-which-key-integration))))
    :commands (lsp lsp-deferred)
    :config
    (general-def 'normal lsp-mode :definer 'minor-mode
      "SPC l" lsp-command-map))

(use-package lsp-ui :commands lsp-ui-mode)

(use-package consult-lsp)

(use-package lsp-treemacs
    :init
    (lsp-treemacs-sync-mode 1)
    :commands lsp-treemacs-errors-list)

(use-package flycheck
    :init (global-flycheck-mode))

(use-package lispy
  :hook
  ((emacs-lisp-mode org-mode). lispy-mode))

(use-package lispyville
  :hook
  (lispy-mode . lispyville-mode))

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

(major-mode-def
:keymaps 'org-mode-map
:wk-full-keys nil
"o" '(org-open-at-point :wk "open link")
"x" '(org-babel-execute-src-block :wk "execute block")
"i"       (cons "insert" (make-sparse-keymap))
"is" '((lambda() (interactive) (org-insert-structure-template "src")) :wk "src block")
"it" '((lambda() (interactive) (org-set-tags-command "TOC")) :wk "TOC"))
