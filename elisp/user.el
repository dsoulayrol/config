;; Make fun of this damn mouse cursor
(mouse-avoidance-mode (quote animate))

;; Turn off the default backup behaviour
(if (file-directory-p "~/.emacs.d/backup")
    (setq backup-directory-alist '(("." . "~/.emacs.d/backup")))
    (message "Directory does not exist: ~/.emacs.d/backup"))

;; Display trailing spaces
(add-hook 'find-file-hook
          '(lambda ()
	     "Show trailing spaces and empty lines on every buffer"
             (setq show-trailing-whitespace t)
             (setq indicate-empty-lines t)))


;; Typed text replaces the selection if the selection is active
;; Also allows to delete (not kill) the highlighted region by pressing <DEL>.
(delete-selection-mode t)

;; Completion for mini-buffer.
;;(icomplete-mode t)
;;(iswitchb-mode t)
(require 'ido)
(ido-mode t)

;; Customize compilation
(setq compilation-scroll-output 1)
(cons '"*Compilation*" 'same-window-buffer-names)

;; Improve names for buffer with similar filenames.
(require 'uniquify)
(setq uniquify-buffer-name-style 'forward
      uniquify-separator ":")

;; Folding - or hideshow minor mode for programming
;;   (http://www.emacswiki.org/cgi-bin/wiki/HideShow)
;;   (http://www.delorie.com/gnu/docs/emacs/emacs_293.html)
(load-library "hideshow")
(add-hook 'java-mode-hook 'hs-minor-mode)
(add-hook 'perl-mode-hook 'hs-minor-mode)
(add-hook 'c++-mode-hook 'hs-minor-mode)
(add-hook 'c-mode-hook 'hs-minor-mode)
(add-hook 'emacs-lisp-mode-hook 'hs-minor-mode)

;; Open folded code on goto
(defadvice goto-line (after expand-after-goto-line activate compile)
  "hideshow-expand affected block when using goto-line in a collapsed buffer"
  (save-excursion (hs-show-block)))

;; Authorize region narrowing
(put 'narrow-to-region 'disabled nil)

;; TRAMP
(setq tramp-default-method "ssh")

;; GNU Global
;;   (http://www.gnu.org/software/global/globaldoc.html)
(load-library "global/gtags.el")
(add-hook 'java-mode-hook 'gtags-mode)
(add-hook 'c++-mode-hook 'gtags-mode)
(add-hook 'c-mode-hook 'gtags-mode)



;; Mutt
;; ----
(autoload 'post-mode "post" "mode for e-mail" t)
(add-to-list 'auto-mode-alist
             '("\\.*mutt-*\\|.article\\|\\.followup"
               . post-mode))
(add-hook 'post-mode-hook
  (lambda()
    (auto-fill-mode t)
    (setq fill-column 72) ; rfc 1855 for usenet messages
    (footmode-mode t)))


;; Yasnippet
;; ---------
;; TODO: should not hard write src/elisp here.
(setq yas/root-directory '("~/src/elisp/snippets"
                           "/usr/share/emacs/site-lisp/yasnippet/snippets/"))

;; Map `yas/load-directory' to every element
(mapc 'yas/load-directory yas/root-directory)


;; Flymake
;; -------
:; Automatically spawning flymake.
:;  (this is commented out because it should need a lot of
:;   customization for the cases)
;(add-hook 'find-file-hook 'flymake-find-file-hook)

(defadvice flymake-goto-next-error (after display-message activate compile)
  "Display the error in the mini-buffer rather than having to mouse over it"
  (show-fly-err-at-point))

(defadvice flymake-goto-prev-error (after display-message activate compile)
  "Display the error in the mini-buffer rather than having to mouse over it"
  (show-fly-err-at-point))

(defadvice flymake-mode (before post-command-stuff activate compile)
  "Add functionality to the post command hook so that if the
cursor is sitting on a flymake error the error information is
displayed in the minibuffer (rather than having to mouse over
it)"
  (set (make-local-variable 'post-command-hook)
       (cons 'show-fly-err-at-point post-command-hook)))



(load-user-elisp "dist/elisp/sacha.el")


(load-user-elisp "local/elisp/user-cedet.el")
(load-user-elisp "local/elisp/user-org.el")

;; Programming Modes
(load-user-elisp "local/elisp/user-lua.el")
(load-user-elisp "local/elisp/user-python.el")

;; Lastly, configuration local to the machine
(load-user-elisp "local/elisp/user-local.el")


