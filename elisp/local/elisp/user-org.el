;; The Org mode
;; ------------
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))

;; Automatically change to DONE when all children are done
(defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
  (let (org-log-done org-log-states)   ; turn off logging
    (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

;; Setting personal TODO tags
(setq org-todo-keywords
      '((sequence "TODO(t)" "WAITING(w)" "DEFERRED(e)" "|" "DONE(d!)")
        (sequence "BUG(b)" "REVIEWED(r)" "|" "FIXED(f!)")
        (sequence "|" "CANCELED(c!)")))

(setq org-todo-keyword-faces '(("DEFERRED"  . shadow)))

;; Integrate Remember with Org
(org-remember-insinuate)
(setq org-directory "~/org/")
(setq org-default-notes-file (concat org-directory "/notes.org"))
(define-key global-map "\C-cr" 'org-remember)

(setq org-remember-templates
      '(("Todo" ?t "* TODO %?\n  %i\n  %a" "~/org/todo.org" "Tasks")
        ("Memo" ?m "* %^{Title}\n  %i\n  %a" "~/org/memo.org")
        ("Idea" ?i "* %^{Title}\n  %i\n  %a" "~/org/journal.org" "New Ideas")))
