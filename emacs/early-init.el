(setq package-enable-at-startup nil
			native-comp-deferred-compilation nil)

(setenv "LSP_USE_PLISTS" "true")

(when (fboundp 'startup-redirect-eln-cache)
	(startup-redirect-eln-cache
	 (convert-standard-filename
		(expand-file-name  "var/eln-cache/" user-emacs-directory))))

;; Premature redisplays can substantially affect startup times and produce
;; ugly flashes of unstyled Emacs.
(setq-default inhibit-redisplay t
              inhibit-message t)
(add-hook 'window-setup-hook
          (lambda ()
            (setq-default inhibit-redisplay nil
                          inhibit-message nil)
            (redisplay)))
