;; The Org mode
;; ------------
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

(setq org-export-html-style-include-default nil)
(setq org-empty-line-terminates-plain-lists 'true)

;; Automatically change to DONE when all children are done
(defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
  (let (org-log-done org-log-states)   ; turn off logging
    (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

;; Integrate Remember with Org
(org-remember-insinuate)
(setq org-directory "~/org/")
(setq org-default-notes-file (concat org-directory "/notes.org"))
(define-key global-map "\C-cr" 'org-remember)
