;; CEDET
;;(load-library "cedet-common/cedet.el")
(load-file "~/src/cedet-1.0pre6/common/cedet.el")

;; Project mode.
(global-ede-mode t)

;; Semantic's customization.
(semantic-load-enable-code-helpers)

;; Prevent semantic to make semantic.cache everywhere.
(setq semanticdb-default-save-directory "~/.emacs.d/semantic")

;; Enable folding
(global-semantic-tag-folding-mode 1)

;; Enable template insertion menu.
(global-srecode-minor-mode 1)

;; COGRE
;;(cogre-uml-enable-unicode)

;;
(require 'semantic-ia)

;; Automatically find system include file paths.
(require 'semantic-gcc)

;; Support for GNU Global
(require 'semanticdb-global)
(semanticdb-enable-gnu-global-databases 'c-mode)
(semanticdb-enable-gnu-global-databases 'c++-mode)


