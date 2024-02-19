;;; package: --- A theme inspired by the colors of the famous painting by Katsushika Hokusa

;;; Commentary: Original theme created by rebelot see: https://github.com/rebelot/kanagawa.nvim
;;; Code:

(eval-when-compile
  (require 'cl-lib))

(require 'autothemer)

(unless (>= emacs-major-version 24)
  (error "Requires Emacs 24 or later"))


(autothemer-deftheme
 kanagawa-paper "A theme inspired by the colors of the famous painting by Katsushika Hokusa"

 ((((class color) (min-colors #xFFFFFF))        ; col 1 GUI/24bit
   ((class color) (min-colors #xFF)))           ; col 2 Xterm/256

  ;; Define our color palette
  (fujiWhite		  "#DCD7BA" "#ffffff")
  (oldWhite		    "#C8C093" "#ffffff")

  (sumiInk-0		  "#16161D" "#000000")
  (sumiInk-1b	  	"#181820" "#000000")
  (sumiInk-1		  "#1F1F28" "#080808")
  (sumiInk-2	  	"#2A2A37" "#121212")
  (sumiInk-3		  "#363646" "#303030")
  (sumiInk-4	  	"#54546D" "#303030")

  (waveBlue-1		  "#223249" "#4e4e4e")
  (waveBlue-2	  	"#2D4F67" "#585858")
  (waveAqua1		  "#6A9589" "#6a9589")
  (waveAqua2		  "#7AA89F" "#717C7C")

  (winterGreen		"#2B3328" "#585858")
  (winterYellow		"#49443C" "#585858")
  (winterRed	  	"#43242B" "#585858")
  (winterBlue		  "#252535" "#585858")

  (autumnGreen		"#76946A" "#585858")
  (autumnRed		  "#C34043" "#585858")
  (autumnYellow		"#DCA561" "#585858")

  (samuraiRed	  	"#E82424" "#585858")
  (roninYellow		"#FF9E3B" "#585858")

  (dragonBlue		  "#658594" "#658594")
  (dragonBlue2		"#8ba4b0" "#8ba4b0")
  (dragonBlack0		"#0d0c0c" "#0d0c0c")
  (dragonBlack1		"#12120f" "#12120f")
  (dragonBlack2		"#1D1C19" "#1D1C19")
  (dragonBlack3		"#181616" "#181616")
  (dragonBlack4		"#282727" "#282727")
  (dragonBlack5		"#393836" "#393836")
  (dragonBlack6		"#625e5a" "#625e5a")
  (dragonWhite 		"#c5c9c5" "#c5c9c5")
  (dragonGreen 		"#87a987" "#87a987")
  (dragonGreen2		"#8a9a7b" "#8a9a7b")
  (dragonPink	  	"#a292a3" "#a292a3")
  (dragonOrange		"#b6927b" "#b6927b")
  (dragonOrange2	"#b98d7b" "#b98d7b")
  (dragonGray		  "#a6a69c" "#a6a69c")
  (dragonGray2		"#9e9b93" "#9e9b93")
  (dragonGray3		"#7a8382" "#7a8382")
  (dragonViolet		"#8992a7" "#8992a7")
  (dragonRed		  "#c4746e" "#c4746e")
  (dragonAqua	  	"#8ea4a2" "#8ea4a2")
  (dragonAsh		  "#737c73" "#737c73")
  (dragonTeal	  	"#949fb5" "#949fb5")
  (dragonYellow		"#c4b28a" "#c4b28a")

  (fujiGray       "#727169" "#717C7C")
  (oniViolet		  "#957FB8" "#717C7C")
  (springViolet1	"#938AA9" "#717C7C")
  (springViolet2	"#9CABCA" "#717C7C")
  (crystalBlue		"#7E9CD8" "#717C7C")
  (springBlue	  	"#7FB4CA" "#717C7C")
  (lightBlue		  "#A3D4D5" "#717C7C")
  (springGreen		"#98BB6C" "#717C7C")
  (boatYellow1		"#938056" "#717C7C")
  (boatYellow2		"#C0A36E" "#717C7C")
  (carpYellow		  "#E6C384" "#717C7C")
  (sakuraPink	  	"#D27E99" "#717C7C")
  (waveRed        "#E46876" "#717C7C")
  (peachRed       "#FF5D62" "#717C7C")
  (surimiOrange		"#FFA066" "#717C7C")
  (katanaGray		  "#717C7C" "#717C7C")
  (comet          "#54536D" "#4e4e4e"))

 ;; Customize faces
 (
  (default                                       (:background sumiInk-1 :foreground fujiWhite))
  (border                                        (:background sumiInk-2 :foreground sumiInk-0))
  (button                                        (:foreground waveAqua2))
  (child-frame                                   (:background sumiInk-0 :foreground sumiInk-0))
  (child-frame-border                            (:background sumiInk-0 :foreground sumiInk-0))
  (cursor                                        (:background lightBlue :foreground sumiInk-0 :bold t))
  (error                                         (:foreground samuraiRed))
  (fringe                                        (:foreground sumiInk-3))
  (glyph-face                                    (:background sumiInk-4))
  (glyphless-char                                (:foreground sumiInk-4))
  (header-line                                   (:background sumiInk-0))
  (highlight                                     (:background dragonViolet :foreground dragonBlack4))
  (hl-line                                       (:background sumiInk-2))
  (homoglyph                                     (:foreground lightBlue))
  (internal-border                               (:background sumiInk-1b))
  (line-number                                   (:foreground sumiInk-4))
  (line-number-current-line                      (:foreground dragonOrange :background sumiInk-2 :bold t))
  (lv-separator                                  (:foreground waveBlue-2 :background sumiInk-2))
  (match                                         (:background roninYellow :foreground sumiInk-0))
  (menu                                          (:background sumiInk-0 :foreground fujiWhite))
  (mode-line                                     (:background sumiInk-3))
  (mode-line-inactive                            (:background sumiInk-2 :foreground sumiInk-4 :bold nil))
  (mode-line-active                              (:background winterRed :foreground dragonGray2 :bold nil))
  (mode-line-highlight                           (:foreground boatYellow2))
  (mode-line-buffer-id                           (:foreground waveAqua2 :bold t))
  (numbers                                       (:background dragonPink))
  (region                                        (:background waveBlue-2))
  (separator-line                                (:background sumiInk-0))
  (shadow                                        (:background sumiInk-0))
  (success                                       (:foreground springGreen))
  (vertical-border                               (:foreground sumiInk-4))
  (warning                                       (:foreground roninYellow))
  (window-border                                 (:background sumiInk-1b))
  (window-divider                                (:foreground sumiInk-2))
  (hi-yellow                                     (:background carpYellow :foreground sumiInk-1b))

  ;; Font lock
  (font-lock-type-face                           (:foreground dragonBlue))
  (font-lock-regexp-grouping-backslash           (:foreground dragonRed))
  (font-lock-keyword-face                        (:foreground dragonRed :weight 'bold))
  (font-lock-warning-face                        (:foreground roninYellow))
  (font-lock-string-face                         (:foreground dragonGreen2 :italic t))
  (font-lock-number-face                         (:foreground dragonPink :italic t))
  (font-lock-builtin-face                        (:foreground dragonBlue))
  (font-lock-delimiter-face                      (:foreground dragonGray2))
  (font-lock-reference-face                      (:foreground dragonRed))
  (font-lock-constant-face                       (:foreground dragonOrange))
  (font-lock-function-name-face                  (:foreground dragonBlue2))
  (font-lock-variable-name-face                  (:foreground fujiWhite))
  (font-lock-variable-use-face                   (:foreground fujiWhite))
  (font-lock-property-use-face                   (:foreground dragonOrange))
  (font-lock-negation-char-face                  (:foreground dragonRed))
  (font-lock-operator-face											 (:foreground dragonGray2))
  (font-lock-comment-face                        (:foreground dragonAsh :italic t))
  (font-lock-comment-delimiter-face              (:foreground dragonAsh :italic t))
  (font-lock-doc-face                            (:foreground comet))
  (font-lock-doc-markup-face                     (:foreground comet))
  (font-lock-preprocessor-face	                 (:foreground boatYellow2))
  (elisp-shorthand-font-lock-face                (:foreground fujiWhite))

  (info-xref                                     (:foreground dragonYellow))
  (minibuffer-prompt-end                         (:foreground dragonRed :background winterRed))
  (minibuffer-prompt                             (:foreground dragonYellow :background winterYellow))
  (epa-mark                                      (:foreground waveRed))
  (dired-mark                                    (:foreground waveRed))
  (trailing-whitespace                           (:background comet))

  ;; Battery colors
  (doom-modeline-battery-critical                (:foreground peachRed))
  (doom-modeline-battery-warning                 (:foreground springGreen))
  (doom-modeline-battery-charging                (:foreground fujiGray))
  (doom-modeline-battery-error                   (:foreground peachRed))
  (doom-modeline-battery-normal                  (:foreground springViolet1))
  (doom-modeline-battery-full                    (:foreground waveAqua2))

  ;; Doom visual state
  (doom-modeline-evil-motion-state               (:foreground roninYellow))
  (doom-modeline-evil-emacs-state                (:foreground roninYellow))
  (doom-modeline-evil-insert-state               (:foreground autumnRed))
  (doom-modeline-evil-normal-state               (:foreground roninYellow))
  (doom-modeline-evil-visual-state               (:foreground autumnGreen))
  (doom-modeline-evil-replace-state              (:foreground autumnRed))
  (doom-modeline-evil-operator-state             (:foreground autumnRed))

  (persp-selected-face				                   (:bold t :foreground waveAqua1))
  (doom-modeline-project-dir                     (:foreground waveAqua2))
  (doom-modeline-buffer-path                     (:foreground waveAqua2))
  (doom-modeline-buffer-file                     (:bold t :foreground dragonBlue))
  (doom-modeline-buffer-modified                 (:inherit 'bold :foreground dragonYellow))
  (doom-modeline-buffer-major-mode               (:bold t :foreground dragonBlue))
  (doom-modeline-buffer-minor-mode               (:foreground dragonGray3)) ;; minions
  (doom-modeline-error                           (:background peachRed))
  (doom-modeline-warning                         (:foreground roninYellow))
  (doom-modeline-info                            (:foreground dragonGray2)) ;; VCS branch
  (doom-modeline-bar                             (:background dragonWhite))
  (doom-modeline-panel                           (:background waveBlue-2 :foreground oldWhite))
  (doom-themes-visual-bell                       (:background autumnRed))

  ;; message colors
  (message-header-name                           (:foreground sumiInk-4))
  (message-header-other                          (:foreground surimiOrange))
  (message-header-subject                        (:foreground carpYellow))
  (message-header-to                             (:foreground oldWhite))
  (message-header-cc                             (:foreground waveAqua2))
  (message-header-xheader                        (:foreground oldWhite))
  (custom-link                                   (:foreground crystalBlue))
  (link                                          (:foreground crystalBlue))

	;; transient
  (transient-inactive-value                      (:foreground dragonGray))
  (transient-inactive-argument                   (:foreground dragonGray))
  (transient-delimiter													 (:foreground dragonGray))
  (transient-unreachable												 (:foreground dragonRed))
  (transient-unreachable-key                     (:foreground dragonBlue))

	;; elpaca
  (elpaca-log-info															 (:foreground dragonGray))

  ;; org-mode
  (org-done                                      (:foreground dragonBlue))
  (org-code                                      (:background sumiInk-0))
  (org-meta-line                                 (:background winterGreen :foreground springGreen))
  (org-block                                     (:background sumiInk-0 :foreground fujiWhite))
  (org-block-begin-line                          (:background winterBlue :foreground springBlue))
  (org-block-end-line														 (:background winterRed :foreground peachRed))
  (org-headline-done                             (:foreground dragonBlue :strike-through t))
  (org-todo                                      (:foreground surimiOrange :bold t))
  (org-headline-todo                             (:foreground sumiInk-2))
  (org-upcoming-deadline                         (:foreground peachRed))
  (org-footnote                                  (:foreground waveAqua2))
  (org-indent                                    (:background sumiInk-1b :foreground sumiInk-1b))
  (org-hide                                      (:background sumiInk-1b :foreground sumiInk-1b))
  (org-date                                      (:foreground waveBlue-2))
  (org-ellipsis                                  (:foreground waveBlue-2 :bold t))
  (org-level-1                                   (:foreground dragonRed :height 1.3 :bold t))
  (org-level-2                                   (:foreground dragonViolet :height 1.15 :bold t))
  (org-level-3                                   (:foreground dragonYellow :height 1.05))
  (org-level-4                                   (:foreground fujiWhite))
  (org-level-5                                   (:foreground oldWhite))
  (org-level-6                                   (:foreground dragonAqua))
  (org-level-7                                   (:foreground dragonOrange))
  (org-level-8                                   (:foreground dragonGreen))

  ;; which-key
  (which-key-key-face                            (:foreground dragonOrange :bold t))
  (which-func                                    (:inherit 'font-lock-function-name-face :bold t))
  (which-key-group-description-face              (:foreground waveRed))
  (which-key-command-description-face            (:foreground crystalBlue))
  (which-key-local-map-description-face          (:foreground carpYellow))
  (which-key-posframe                            (:background waveBlue-1))
  (which-key-posframe-border										 (:background waveBlue-1))

  ;; rainbow delimiters
  (rainbow-delimiters-mismatched-face            (:foreground peachRed))
  (rainbow-delimiters-unmatched-face             (:foreground waveAqua2))
  (rainbow-delimiters-base-error-face            (:foreground peachRed))
  (rainbow-delimiters-base-face                  (:foreground sumiInk-4))

  (rainbow-delimiters-depth-1-face               (:foreground dragonViolet))
  (rainbow-delimiters-depth-2-face               (:foreground dragonBlue))
  (rainbow-delimiters-depth-3-face               (:foreground springViolet1))
  (rainbow-delimiters-depth-4-face               (:foreground dragonGreen))
  (rainbow-delimiters-depth-5-face               (:foreground dragonAqua))
  (rainbow-delimiters-depth-6-face               (:foreground dragonYellow))
  (rainbow-delimiters-depth-7-face               (:foreground dragonRed))
  (rainbow-delimiters-depth-8-face               (:foreground dragonBlue))
  (rainbow-delimiters-depth-9-face               (:foreground dragonGreen))

  ;; show-paren
  (show-paren-match                              (:background waveAqua1 :foreground sumiInk-0 :bold t))
  (show-paren-match-expression	                 (:background waveAqua1 :foreground sumiInk-0 :bold t))
  (show-paren-mismatch                           (:background dragonRed :foreground oldWhite))
  (tooltip                                       (:foreground sumiInk-0 :background carpYellow :bold t))

	;; indents
	(indent-guide-face														 (:foreground dragonGray3))

  ;; flymake
  (flymake-error								                 (:foreground samuraiRed))
  (flymake-warning												       (:foreground roninYellow))
  (flymake-note																	 (:foreground dragonBlue))
  (flymake-posframe-background-face							 (:background dragonViolet))
  (flymake-posframe-foreground-face							 (:foreground dragonBlack4))

  ;; lsp and lsp-ui
  (lsp-headerline-breadcrumb-path-error-face     (:underline (:color dragonRed :style 'wave)))
  (lsp-headerline-breadcrumb-path-warning-face   (:underline (:color roninYellow :style 'wave)))
  (lsp-headerline-breadcrumb-path-face           (:background sumiInk-0))
  (lsp-headerline-breadcrumb-path-hint-face      (:background sumiInk-0))
  (lsp-headerline-breadcrumb-path-info-face      (:background sumiInk-0))
  (lsp-headerline-breadcrumb-separator-face      (:background sumiInk-0))
  (lsp-headerline-breadcrumb-project-prefix-face (:background sumiInk-0))
  (lsp-headerline-breadcrumb-symbols-face        (:background sumiInk-0))
  (lsp-headerline-breadcrumb-symbols-error-face     (:underline (:color dragonRed :style 'wave)))
  (lsp-headerline-breadcrumb-symbols-warning-face   (:underline (:color roninYellow :style 'wave)))

  (lsp-ui-doc-background                         (:background sumiInk-0 :foreground peachRed))
  (lsp-ui-doc-header                             (:background sumiInk-0 :foreground peachRed))
  (lsp-ui-doc-border                             (:foreground lightBlue))
  (lsp-ui-peek-filename                          (:foreground lightBlue))
  (lsp-ui-sideline-code-action                   (:foreground carpYellow))
  (lsp-ui-sideline-current-symbol                (:foreground springBlue))
  (lsp-ui-sideline-symbol                        (:foreground dragonBlue))

	(eglot-diagnostic-tag-unnecessary-face         (:foreground sumiInk-3))
	(eglot-diagnostic-tag-deprecated-face          (:foreground sumiInk-3 :strike-through t))

  ;; dashboard
  (dashboard-heading                             (:foreground autumnRed :bold t))
  (dashboard-items-face                          (:bold nil :foreground fujiWhite))
  (dashboard-banner-logo-title                   (:bold t :height 200 :foreground dragonGreen))
	(dashboard-text-banner                         (:foreground dragonBlue))

  ;; all-the-icons
  (all-the-icons-dgreen                          (:foreground waveAqua2))
  (all-the-icons-green                           (:foreground waveAqua2))
  (all-the-icons-dpurple                         (:foreground springViolet2))
  (all-the-icons-purple                          (:foreground springViolet2))

  ;; evil
  (evil-ex-lazy-highlight                        (:foreground winterGreen :background autumnGreen :bold t))
  (evil-ex-substitute-matches                    (:foreground winterRed :background autumnRed :bold t))
  (evil-ex-substitute-replacement                (:foreground surimiOrange :strike-through nil :inherit 'evil-ex-substitute-matches))
  (evil-search-highlight-persist-highlight-face  (:background carpYellow))

  ;; popup
  (popup-face                                    (:inherit 'tooltip))
  (popup-selection-face                          (:inherit 'tooltip))
  (popup-tip-face                                (:inherit 'tooltip))

  ;; vertico
  (vertico-multiline                             (:background samuraiRed))
  (vertico-group-title                           (:background winterBlue :foreground lightBlue :bold t))
  (vertico-group-separator                       (:background winterBlue :foreground lightBlue :strike-through t))
  (vertico-current                               (:foreground carpYellow :bold t :italic t :background waveBlue-1))

  (vertico-posframe-border                       (:background sumiInk-3))
  (vertico-posframe                              (:background sumiInk-2))
  (orderless-match-face-0                        (:foreground crystalBlue :bold t))
  (marginalia-file-priv-no                       (:foreground crystalBlue))

  (comint-highlight-prompt                       (:background springViolet2 :foreground sumiInk-1))
  (completions-annotations                       (:foreground dragonBlue :italic t))

  ;; hydra
  (hydra-face-amaranth                           (:foreground autumnRed))
  (hydra-face-blue                               (:foreground springBlue))
  (hydra-face-pink                               (:foreground sakuraPink))
  (hydra-face-red                                (:foreground peachRed))
  (hydra-face-teal                               (:foreground lightBlue))

  ;; centaur-tabs
  (tab-line                                      (:background sumiInk-0))
  (centaur-tabs-default                          (:background sumiInk-0 :foreground sumiInk-4))
  (centaur-tabs-active-bar-face	 	               (:background dragonPink))

  (centaur-tabs-selected                         (:background sumiInk-1 :foreground fujiWhite :bold t))
  (centaur-tabs-selected-modified                (:inherit 'centaur-tabs-selected))

  (centaur-tabs-unselected                       (:background sumiInk-0 :foreground sumiInk-4))
  (centaur-tabs-unselected-modified              (:inherit 'centaur-tabs-unselected))

  (centaur-tabs-modified-marker-selected         (:inherit 'centaur-tabs-selected :foreground autumnYellow))
  (centaur-tabs-modified-marker-unselected       (:inherit 'centaur-tabs-unselected))

  (centaur-tabs-close-selected                   (:inherit 'centaur-tabs-selected))
  (centaur-tabs-close-unselected                 (:inherit 'centaur-tabs-unselected))

  (centaur-tabs-close-mouse-face                 (:foreground peachRed))
  (centaur-tabs-name-mouse-face                  (:foreground dragonBlue :bold t))

  (centaur-tabs-jump-identifier-selected         (:inherit 'centaur-tabs-selected :foreground samuraiRed :bold t))
  (centaur-tabs-jump-identifier-unselected       (:inherit 'centaur-tabs-unselected :foreground samuraiRed :bold t))

	;; dirvish
	(dirvish-hl-line															 (:background sumiInk-2))
	(dirvish-subtree-state												 (:background nil :foreground sumiInk-3))
	(dirvish-subtree-guide												 (:background sumiInk-1 :foreground sumiInk-3))

	;; vcs
  (diff-hl-change															   (:foreground autumnYellow :background winterYellow))
  (diff-hl-delete																 (:foreground autumnRed :background winterRed))
  (diff-hl-insert																 (:foreground autumnGreen :background winterGreen))

	(magit-branch-local														 (:foreground springGreen :bold t))
	(magit-branch-current													 (:foreground springGreen :box 1 :bold t))
	(magit-branch-remote													 (:foreground oniViolet))
	(magit-branch-remote-head											 (:foreground oniViolet :box 1))
	(magit-log-author															 (:foreground dragonOrange))
	(magit-diff-hunk-heading-highlight						 (:background oniViolet :foreground dragonBlack3 :bold t))
	(magit-diff-hunk-heading											 (:background springViolet2 :foreground dragonBlack3))

	;; markdown
	(markdown-list-face														 (:foreground dragonViolet))
	(markdown-header-delimiter-face								 (:foreground dragonViolet))
	(markdown-markup-face													 (:foreground oldWhite))

	;; copilot
	(copilot-overlay-face													 (:foreground sumiInk-4))

	(focus-unfocused (:foreground sumiInk-4))

	;; term
  (term                                          (:background sumiInk-0 :foreground fujiWhite))
  (term-color-blue                               (:background dragonBlue2 :foreground dragonBlue2))
  (term-color-bright-blue                        (:inherit 'term-color-blue))
  (term-color-green                              (:background dragonGreen2 :foreground dragonGreen2))
  (term-color-bright-green                       (:inherit 'term-color-green))
  (term-color-black                              (:background dragonBlack0 :foreground fujiWhite))
  (term-color-bright-black                       (:background dragonGray :foreground sumiInk-1b))
  (term-color-white                              (:background oldWhite :foreground fujiWhite))
  (term-color-bright-white                       (:background dragonWhite :foreground oldWhite))
  (term-color-red                                (:background dragonRed :foreground dragonRed))
  (term-color-bright-red                         (:background waveRed :foreground waveRed))
  (term-color-yellow                             (:background dragonYellow :foreground dragonYellow))
  (term-color-bright-yellow                      (:background carpYellow :foreground carpYellow))
  (term-color-cyan                               (:background dragonAqua :foreground dragonAqua))
  (term-color-bright-cyan                        (:background waveAqua2 :foreground waveAqua2))
  (term-color-magenta                            (:background dragonPink :foreground dragonPink))
  (term-color-bright-magenta                     (:background springViolet1 :foreground springViolet1))

	(ansi-color-green                              (:foreground dragonGreen2))
  (ansi-color-black                              (:background dragonBlack0))
  (ansi-color-cyan                               (:foreground dragonAqua))
  (ansi-color-magenta                            (:foreground dragonPink))
  (ansi-color-blue                               (:foreground dragonBlue2))
  (ansi-color-red                                (:foreground dragonRed))
  (ansi-color-white                              (:foreground oldWhite))
  (ansi-color-yellow                             (:foreground dragonYellow))
  (ansi-color-bright-white                       (:foreground dragonWhite))

  ;;treemacs
  ;; (treemacs-directory-collapsed-face             (:foreground fujiWhite))
  ;; (treemacs-directory-face                       (:foreground fujiWhite))
  ;; (treemacs-file-face                            (:foreground fujiWhite))

  ;; (treemacs-git-added-face                       (:foreground winterGreen))
  ;; (treemacs-git-renamed-face                     (:foreground fujiWhite))
  ;; (treemacs-git-ignored-face                     (:foreground dragonGray))
  ;; (treemacs-git-unmodified-face                  (:foreground fujiWhite))
  ;; (treemacs-git-modified-face                    (:foreground dragonOrange))

  ;; anzu
  ;; (anzu-match-1                                  (:foreground waveAqua2 :background sumiInk-2))
  ;; (anzu-match-2                                  (:foreground carpYellow :background sumiInk-2))
  ;; (anzu-match-3                                  (:foreground lightBlue :background sumiInk-2))

  ;; (anzu-mode-line                                (:foreground sumiInk-0 :background springViolet2))
  ;; (anzu-mode-no-match	                           (:foreground fujiWhite :background peachRed))
  ;; (anzu-replace-to                               (:foreground springBlue :background winterBlue))
  ;; (anzu-replace-highlight                        (:foreground peachRed :background winterRed :strike-through t))

	;; yascroll
	;; (yascroll:thumb-fringe                         (:background sumiInk-3 :foreground sumiInk-3))

  ;; ace
  ;; (ace-jump-face-background                      (:foreground waveBlue-2))
  ;; (ace-jump-face-foreground                      (:foreground peachRed :background sumiInk-0 :bold t))

	;; swiper
  ;; (swiper-line-face                              (:foreground carpYellow))
  ;; (swiper-background-match-face-1                (:background surimiOrange :foreground sumiInk-0))
  ;; (swiper-background-match-face-2                (:background crystalBlue :foreground sumiInk-0))
  ;; (swiper-background-match-face-3                (:background boatYellow2 :foreground sumiInk-0))
  ;; (swiper-background-match-face-4                (:background peachRed :foreground sumiInk-0))
  ;; (swiper-match-face-1                           (:inherit 'swiper-background-match-face-1))
  ;; (swiper-match-face-2                           (:inherit 'swiper-background-match-face-2))
  ;; (swiper-match-face-3                           (:inherit 'swiper-background-match-face-3))
  ;; (swiper-match-face-4                           (:inherit 'swiper-background-match-face-4))

  ;; (counsel-outline-default                       (:foreground carpYellow))
  ;; (info-header-xref                              (:foreground carpYellow))
  ;; (xref-file-header                              (:foreground carpYellow))
  ;; (xref-match                                    (:foreground carpYellow))

	;; company-box
  ;; (company-tooltip                               (:background sumiInk-2))
  ;; (company-tooltip-common                        (:foreground autumnYellow))
  ;; (company-tooltip-quick-access                  (:foreground springViolet2))
  ;; (company-tooltip-scrollbar-thumb               (:background autumnRed))
  ;; (company-tooltip-scrollbar-track               (:background sumiInk-2))
  ;; (company-tooltip-search                        (:background carpYellow :foreground sumiInk-0 :distant-foreground fujiWhite))
  ;; (company-tooltip-selection                     (:background peachRed :foreground winterRed :bold t))
  ;; (company-tooltip-mouse                         (:background sumiInk-2 :foreground sumiInk-0 :distant-foreground fujiWhite))
  ;; (company-tooltip-annotation                    (:foreground peachRed :distant-foreground sumiInk-1))
  ;; (company-scrollbar-bg                          (:inherit 'tooltip))
  ;; (company-scrollbar-fg                          (:background peachRed))
  ;; (company-preview                               (:foreground carpYellow))
  ;; (company-preview-common                        (:foreground peachRed :bold t))
  ;; (company-preview-search                        (:inherit 'company-tooltip-search))
  ;; (company-template-field                        (:inherit 'match))

	;; indent dots
  ;; (highlight-indent-guides-character-face        (:foreground sumiInk-3))
  ;; (highlight-indent-guides-stack-character-face  (:foreground sumiInk-3))
  ;; (highlight-indent-guides-stack-odd-face        (:foreground sumiInk-3))
  ;; (highlight-indent-guides-stack-even-face       (:foreground comet))
  ;; (highlight-indent-guides-stack-character-face  (:foreground sumiInk-3))
  ;; (highlight-indent-guides-even-face             (:foreground sumiInk-2))
  ;; (highlight-indent-guides-odd-face              (:foreground comet))

  ;; (highlight-operators-face                      (:foreground boatYellow2))
  ;; (highlight-quoted-symbol                       (:foreground springGreen))
  ;; (highlight-numbers-face                        (:foreground sakuraPink))
  ;; (highlight-symbol-face                         (:background waveBlue-1 :foreground lightBlue))

  ;; ivy
  ;; (ivy-current-match                             (:background crystalBlue :foreground sumiInk-0 :bold t))
  ;; (ivy-action                                    (:foreground fujiWhite))
  ;; (ivy-grep-line-number                          (:foreground springGreen))
  ;; (ivy-minibuffer-match-face-1                   (:foreground waveRed))
  ;; (ivy-minibuffer-match-face-2                   (:foreground springGreen))
  ;; (ivy-minibuffer-match-highlight                (:foreground lightBlue))
  ;; (ivy-grep-info                                 (:foreground lightBlue))
  ;; (ivy-grep-line-number                          (:foreground springViolet2))
  ;; (ivy-confirm-face                              (:foreground waveAqua2))

  ;; posframe's
  ;; (ivy-posframe                                  (:background sumiInk-2))
  ;; (ivy-posframe-border                           (:background sumiInk-3))


  ;; (bm-fringe-face                                (:background peachRed :foreground sumiInk-3))
  ;; (bm-fringe-persistent-face                     (:background peachRed :foreground sumiInk-3))

  ;; (tree-sitter-hl-face:attribute                 (:foreground surimiOrange))
  ;; (tree-sitter-hl-face:escape                    (:foreground waveRed))
  ;; (tree-sitter-hl-face:constructor               (:foreground waveRed :weight 'semi-bold))

  ;; (tree-sitter-hl-face:constant                  (:foreground surimiOrange))
  ;; (tree-sitter-hl-face:constant.builtin          (:foreground carpYellow :weight 'semi-bold))

  ;; (tree-sitter-hl-face:embedded                  (:foreground boatYellow2))

  ;; (tree-sitter-hl-face:function                  (:foreground dragonRed))
  ;; (tree-sitter-hl-face:function.builtin          (:foreground peachRed :italic t :background winterRed))
  ;; (tree-sitter-hl-face:function.call             (:foreground springViolet2))
  ;; (tree-sitter-hl-face:function.macro            (:foreground samuraiRed))
  ;; (tree-sitter-hl-face:function.special          (:foreground sakuraPink))
  ;; (tree-sitter-hl-face:function.label            (:foreground surimiOrange))

  ;; (tree-sitter-hl-face:method                    (:foreground dragonYellow))
  ;; (tree-sitter-hl-face:method.call               (:foreground lightBlue))

  ;; (tree-sitter-hl-face:property                  (:foreground carpYellow))
  ;; (tree-sitter-hl-face:property.definition       (:foreground oldWhite :italic t))

  ;; (tree-sitter-hl-face:tag                       (:foreground peachRed))

  ;; (tree-sitter-hl-face:type                      (:foreground waveAqua2 :weight 'semi-bold))
  ;; (tree-sitter-hl-face:type.argument             (:foreground surimiOrange))
  ;; (tree-sitter-hl-face:type.builtin              (:foreground autumnRed))
  ;; (tree-sitter-hl-face:type.parameter            (:foreground surimiOrange))
  ;; (tree-sitter-hl-face:type.super                (:foreground samuraiRed :bold t))

  ;; (tree-sitter-hl-face:variable                  (:foreground springBlue :italic t))
  ;; (tree-sitter-hl-face:variable.builtin          (:foreground waveRed))
  ;; (tree-sitter-hl-face:variable.parameter        (:foreground springViolet2 :italic t))
  ;; (tree-sitter-hl-face:variable.special          (:foreground surimiOrange))
  ;; (tree-sitter-hl-face:variable.synthesized      (:foreground lightBlue))

  ;; (tree-sitter-hl-face:number                    (:foreground sakuraPink))
  ;; (tree-sitter-hl-face:operator                  (:foreground sakuraPink :bold t))

  ;; (tree-sitter-hl-face:punctuation               (:foreground lightBlue))
  ;; (tree-sitter-hl-face:punctuation.bracket       (:foreground springViolet2 :bold t))
  ;; (tree-sitter-hl-face:punctuation.delimiter     (:foreground springViolet2 :bold t))
  ;; (tree-sitter-hl-face:punctuation.special       (:foreground peachRed))

  ;; (tree-sitter-hl-face:case-pattern              (:foreground waveRed))
  ;; (tree-sitter-hl-face:variable.synthesized      (:foreground waveRed))
  ;; (tree-sitter-hl-face:keyword.compiler          (:foreground peachRed :bold t :italic t))

	;; flycheck
  ;; (flycheck-posframe-background-face             (:background sumiInk-0))
  ;; (flycheck-posframe-face                        (:background sumiInk-0))
  ;; (flycheck-posframe-info-face                   (:background sumiInk-0 :foreground autumnGreen))
  ;; (flycheck-posframe-warning-face                (:background sumiInk-0 :foreground lightBlue))
  ;; (flycheck-posframe-error-face                  (:background sumiInk-0 :foreground samuraiRed))
  ;; (flycheck-fringe-warning                       (:foreground roninYellow))
  ;; (flycheck-fringe-error                         (:foreground samuraiRed))
  ;; (flycheck-fringe-info                          (:foreground dragonBlue))
  ;; (flycheck-error-list-warning                   (:foreground roninYellow :bold t))
  ;; (flycheck-error-list-error                     (:foreground samuraiRed :bold t))
  ;; (flycheck-error-list-info                      (:foreground dragonBlue :bold t))
  ;; (flycheck-inline-error                         (:foreground samuraiRed :background winterRed :italic t :bold t :height 138))
  ;; (flycheck-inline-info                          (:foreground dragonBlue :background winterBlue :italic t  :bold t :height 138))
  ;; (flycheck-inline-warning                       (:foreground winterYellow :background carpYellow :italic t :bold t :height 138))
	))

;;;###autoload
(and load-file-name
     (boundp 'custom-theme-load-path)
     (add-to-list 'custom-theme-load-path
                  (file-name-as-directory
                   (file-name-directory load-file-name))))

(provide-theme 'kanagawa-paper)
;;; kanagawa-paper-theme.el ends here
