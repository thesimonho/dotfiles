;; -*- mode: emacs-lisp; lexical-binding: t; -*-

;; Load layers
(add-to-list 'load-path (expand-file-name "layers" user-emacs-directory))
(load "appearance/init")
(load "editing/init")
(load "org/init")

;; Maximize the Emacs frame at startup
(add-to-list 'initial-frame-alist '(fullscreen . maximized))
