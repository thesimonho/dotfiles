(setq package-enable-at-startup nil)

(setenv "LSP_USE_PLISTS" "true")

(when (fboundp 'startup-redirect-eln-cache)
	(startup-redirect-eln-cache
	 (convert-standard-filename
		(expand-file-name  "var/eln-cache/" user-emacs-directory))))
