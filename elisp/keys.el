;; Use % to find the matching paren (as in vi).
;;   (http://www.gnu.org/software/emacs/emacs-faq.text)
(global-set-key "%" 'match-paren)
(defun match-paren (arg)
  "Go to the matching paren if on a paren; otherwise insert %."
  (interactive "p")
  (cond ((looking-at "\\s\(") (forward-list 1) (backward-char 1))
        ((looking-at "\\s\)") (forward-char 1) (backward-list 1))
        (t (self-insert-command (or arg 1)))))

;; Folding
(global-set-key "\C-c=" 'hs-toggle-hiding)
(global-set-key "\C-c-" 'hs-hide-block)
(global-set-key "\C-c\e-" 'hs-hide-all)
(global-set-key "\C-c+" 'hs-show-block)
(global-set-key "\C-c\e+" 'hs-show-all)

;; GTags (M-. and M-* already defined in gtags.el)
(global-set-key "\e," 'gtags-find-rtag)

;; Compilation
(global-set-key "\C-xc" 'compile)
(global-set-key "\C-xC" 'recompile)

;; Tags
(global-set-key (kbd "M-<return>") 'complete-tag)

;; Highlight
(global-set-key (kbd "C-!") 'lazy-highlight-cleanup)

;; Bind the sequence C-c c to switch comments.
(global-set-key (kbd "C-c c") 'comment-dwim)

;; Org
(global-set-key "\C-cl" 'org-store-link)
(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

;; Semantic
(defun my-cedet-hook ()
  (local-set-key [(control return)] 'semantic-ia-complete-symbol)
  (local-set-key "\C-c?" 'semantic-ia-complete-symbol-menu)
  (local-set-key "\C-c>" 'semantic-complete-analyze-inline)
  (local-set-key "\C-cp" 'semantic-analyze-proto-impl-toggle))
(add-hook 'c-mode-common-hook 'my-cedet-hook)

(defun my-c-mode-cedet-hook ()
 (local-set-key "." 'semantic-complete-self-insert)
 (local-set-key ">" 'semantic-complete-self-insert))
(add-hook 'c-mode-common-hook 'my-c-mode-cedet-hook)
