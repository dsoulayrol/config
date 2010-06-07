;; Make fun of this damn mouse cursor
;; (no more necessary since 23.2 where the cursor is hidden when typing).
; (mouse-avoidance-mode (quote animate))

;; Turn off the default backup behaviour
(if (file-directory-p "~/.emacs.d/backup")
    (setq backup-directory-alist '(("." . "~/.emacs.d/backup")))
    (message "Directory does not exist: ~/.emacs.d/backup"))

;; Display trailing spaces
(add-hook 'find-file-hook
          '(lambda ()
	     "Show trailing spaces and empty lines on every buffer"
             (setq show-trailing-whitespace t
                   indicate-empty-lines t
                   default-indicate-buffer-boundaries 'left)))

;; Kill Ring
;; ---------
;; Typed text replaces the selection if the selection is active
;; Also allows to delete (not kill) the highlighted region by pressing <DEL>.
(delete-selection-mode t)

;; Use browse-kill-ring if available.
;; (http://emacs-fu.blogspot.com/2010/04/navigating-kill-ring.html)
(when (require 'browse-kill-ring nil 'noerror)
  (browse-kill-ring-default-keybindings)
  (global-set-key "\C-cy" '(lambda () (interactive) (popup-menu 'yank-menu))))


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
(when (require 'gtags "global/gtags.el" 'noerror)
  (add-hook 'java-mode-hook 'gtags-mode)
  (add-hook 'c++-mode-hook 'gtags-mode)
  (add-hook 'c-mode-hook 'gtags-mode))


;; Buffers Management
;; ------------------
;; IBuffer
(setq ibuffer-saved-filter-groups
  (quote (("default"
            ("Org"
              (mode . org-mode))
            ("Programming"
              (or
                (mode . c-mode)
                (mode . c++-mode)
                (mode . perl-mode)
                (mode . python-mode)
                (mode . emacs-lisp-mode)
                ))
            ("Web"
              (or
                (mode . xhtml-mode)
                (mode . jabascript-mode)
                ))
            ))))

(add-hook 'ibuffer-mode-hook
  (lambda ()
    (ibuffer-switch-to-saved-filter-groups "default")))
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; Midnight
(require 'midnight)


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
    (if (require 'footnote nil 'noerror) (footnote-mode t)))
    (if (require 'flyspell nil 'noerror) (flyspell-mode t)))


;; Address Book (http://savannah.nongnu.org/projects/addressbook/)
;; ------------
(require 'abook "addressbook/abook.el" 'noerror)

;; Yasnippet
;; ---------
(when (require 'yasnippet nil 'noerror)
  (setq yas/root-directory '("~/.config/elisp/snippets"
                             "/usr/share/emacs/site-lisp/yasnippet/snippets/"))
  ;; Map `yas/load-directory' to every element
  (mapc 'yas/load-directory yas/root-directory))


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
(load-user-elisp "local/elisp/user-org.el")

;; Unclutter the mode-line
;;   (think C-h m to check loaded minor modes)
(when (require 'diminish nil 'noerror)
  (eval-after-load "abbrev"
    '(diminish 'abbrev-mode "Ab"))
  (eval-after-load "yasnippet"
    '(diminish 'yas/minor-mode " Y")))

;; Programming Modes
(load-user-elisp "local/elisp/user-lua.el")
(load-user-elisp "local/elisp/user-python.el")

;; Lastly, configuration local to the machine
(load-user-elisp "local/elisp/user-local.el")


