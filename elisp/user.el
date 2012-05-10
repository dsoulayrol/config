;; Make fun of this damn mouse cursor
;; (no more necessary since 23.2 where the cursor is hidden when typing).
; (mouse-avoidance-mode (quote animate))

;; el-get
(add-to-list 'load-path "~/.emacs.d/el-get/el-get")
(unless (require 'el-get nil t)
  (url-retrieve
   "https://raw.github.com/dimitri/el-get/master/el-get-install.el"
   (lambda (s)
     (end-of-buffer)
     (eval-print-last-sexp))))

(setq my:el-get-packages
      '(browse-kill-ring
        diminish
        fixme-mode
        google-weather
        google-maps
        highlight-parentheses
        rainbow-mode
        ))

(el-get 'sync my:el-get-packages)

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

;; Frame title
;;   (http://emacs-fu.blogspot.com/2011/01/setting-frame-title.html)
(setq frame-title-format
      '("" invocation-name ": "(:eval (if (buffer-file-name)
                                          (abbreviate-file-name (buffer-file-name))
                                        "%b"))))

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

;; Colorful parenthesis nesting around the point.
(require 'highlight-parentheses nil 'noerror)
(add-hook 'java-mode-hook 'highlight-parentheses-mode)
(add-hook 'perl-mode-hook 'highlight-parentheses-mode)
(add-hook 'c++-mode-hook 'highlight-parentheses-mode)
(add-hook 'c-mode-hook 'highlight-parentheses-mode)
(add-hook 'emacs-lisp-mode-hook 'highlight-parentheses-mode)

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
                (mode . java-mode)
                (mode . perl-mode)
                (mode . python-mode)
                (mode . ruby-mode)
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
(when (require 'post nil 'noerror)
  (autoload 'post-mode "post" "mode for e-mail" t)
  (add-to-list 'auto-mode-alist
               '("\\.*mutt-*\\|.article\\|\\.followup"
                 . post-mode))
  (add-hook 'post-mode-hook
            (lambda()
              (auto-fill-mode t)
              (setq fill-column 72) ; rfc 1855 for usenet messages
              (if (require 'footnote nil 'noerror) (footnote-mode t))
              (if (require 'flyspell nil 'noerror) (flyspell-mode t)))))


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


(load-user-elisp "local/elisp/user-org.el")

;; Unclutter the mode-line
;;   (think C-h m to check loaded minor modes)
(when (require 'diminish nil 'noerror)
  (eval-after-load "abbrev"
    '(diminish 'abbrev-mode "Ab"))
  (eval-after-load "yasnippet"
    '(diminish 'yas/minor-mode " Y")))


;; Programming Modes
;; =================

;; Lua
;; ---
(when (load "flymake" t)
  (defun flymake-lua-init ()
    "Invoke luac with '-p' to get syntax checking"
    (let* ((temp-file   (flymake-init-create-temp-buffer-copy
                         'flymake-create-temp-inplace))
           (local-file  (file-relative-name
                         temp-file
                         (file-name-directory buffer-file-name))))
      (list "luac" (list "-p" local-file))))

  (push '("\\.lua\\'" flymake-lua-init) flymake-allowed-file-name-masks)
  (push '("^.*luac[0-9.]*\\(.exe\\)?: *\\(.*\\):\\([0-9]+\\): \\(.*\\)$" 2 3 nil 4)
        flymake-err-line-patterns))

(add-hook 'lua-mode-hook
          '(lambda ()
	     "Don't want flymake mode for lua regions in rhtml
	      files and also on read only files"
	     (if (and (not (null buffer-file-name)) (file-writable-p buffer-file-name))
		 (flymake-mode))))


;; Python
;; ------
;;
;; The following handles pylint outputs with flymake
;;   (http://www.emacswiki.org/emacs/PythonMode).
;;
;; epylint is now provided in the pylint package. If it is not
;; available, the following script must replace it in the path:

;; #!/usr/bin/env python
;;
;; import re
;; import sys
;;
;; from subprocess import *
;;
;; p = Popen("pylint -f parseable -r n --disable-msg-cat=C,R %s" %
;;           sys.argv[1], shell = True, stdout = PIPE).stdout
;;
;; for line in p.readlines():
;;     match = re.search("\\[([WE])(, (.+?))?\\]", line)
;;     if match:
;;         kind = match.group(1)
;;         func = match.group(3)
;;
;;         if kind == "W":
;;             msg = "Warning"
;;         else:
;;             msg = "Error"
;;
;;         if func:
;;             line = re.sub("\\[([WE])(, (.+?))?\\]",
;;                           "%s (%s):" % (msg, func), line)
;;         else:
;;             line = re.sub("\\[([WE])?\\]", "%s:" % msg, line)
;;     print line,
;;
;; p.close()

(when (load "flymake" t)
  (defun flymake-pylint-init ()
    (let* ((temp-file (flymake-init-create-temp-buffer-copy
                       'flymake-create-temp-inplace))
           (local-file (file-relative-name
                        temp-file
                        (file-name-directory buffer-file-name))))
      (list "epylint" (list local-file))))

  (add-to-list 'flymake-allowed-file-name-masks
               '("\\.py\\'" flymake-pylint-init)))

(add-hook 'python-mode-hook
          '(lambda ()
	     "Don't want flymake mode for python regions in rhtml
	      files and also on read only files"
	     (if (and (not (null buffer-file-name)) (file-writable-p buffer-file-name))
		 (flymake-mode))))


;; Lastly, configuration local to the machine
(load-user-elisp "local/elisp/user-local.el")


