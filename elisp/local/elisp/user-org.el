;; The Org mode
;; ------------

(setq org-directory "~/org/")
(add-to-list 'auto-mode-alist '("\\.org\\'" . org-mode))
(setq org-agenda-files '("~/org/tasks.org" "~/org/remind.org"))

(setq org-export-html-style-include-default nil)
(setq org-empty-line-terminates-plain-lists 'true)

;; Automatically change to DONE when all children are done
(defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
  (let (org-log-done org-log-states)   ; turn off logging
    (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

;; TODO: remove if OK.
;; ;; Integrate Remember with Org
;; (org-remember-insinuate)
(setq org-default-notes-file (concat org-directory "/notes.org"))
(define-key global-map "\C-cr" 'org-capture)

;; Captures
(setq org-capture-templates
      '(("t" "Todo" entry (file+headline "tasks.org" "Tasks")
         "* TODO %^{Brief Description} %^g\nADDED: %U\n%i%?\n")
        ("j" "Journal" entry (file+datetree "journal.org")
         "* %?\nEntered on %U\n  %i\n  %a")))

;; Refiling
(setq org-refile-targets (quote (("tasks.org" :regexp . "Tasks")
                                 ("tasks.org" :tag . "project")
                                 ("someday.org" :level . 2))))

;; Agendas
(setq org-agenda-custom-commands
      '(
        ("O" "Agenda and office tasks"
         ((agenda)
          (tags-todo "office"))
         nil ("~/public/office_agenda.html" "~/public/office_agenda.ics"))
        ("H" "Agenda and home tasks"
         ((agenda)
          (tags-todo "home"))
         nil ("~/public/office_home.html" "~/public/office_home.ics"))
        ("d" "Daily Action List"
         ((agenda "" ((org-agenda-ndays 1)
                      (org-agenda-sorting-strategy
                       (quote ((agenda time-up priority-down tag-up) )))
                      (org-deadline-warning-days 0)))))
        ("w" "New Week Action List"
         ((agenda "" ((org-agenda-ndays 7)
                      (org-agenda-start-on-weekday nil)
                      (org-agenda-repeating-timestamp-show-all t)
                      (org-agenda-entry-types '(:timestamp :sexp))))))
        ("g" . "GTD contexts")
        ("go" "Office" tags-todo "office")
        ("gh" "Home" tags-todo "home")
        ("gr" "Reading" tags-todo "reading")
        ("gg" "Gaming" tags-todo "gaming")
        ("G" "GTD Block Agenda"
         ((tags-todo "office")
          (tags-todo "home")))
        ("p" "Tasks list for printing"
         ((agenda "" ((org-agenda-ndays 1)
                      (org-deadline-warning-days 7)
                      (org-agenda-todo-keyword-format "[ ]")
                      (org-agenda-scheduled-leaders '("" ""))
                      (org-agenda-prefix-format "%t%s")
                      (org-agenda-overriding-header "\nToday\n-----\n")))
          (todo "TODO"
                ((org-agenda-prefix-format "[ ] %T: ")
                 (org-agenda-sorting-strategy '(tag-up priority-down))
                 (org-agenda-todo-keyword-format "")
                 (org-agenda-overriding-header "\nTasks by Context\n----------------\n"))))
         ((org-agenda-with-colors nil)
          (org-agenda-compact-blocks t)
          (org-agenda-remove-tags t)
          (ps-number-of-columns 2)
          (ps-landscape-mode t))
         ("~/tasks.ps"))
        ))

(setq org-agenda-exporter-settings
      '((ps-number-of-columns 2)
        (ps-landscape-mode t)
        (org-agenda-add-entry-text-maxlines 5)
        (htmlize-output-type 'css)))

;; Shortcut
(defun open-tasks ()
   (interactive)
   (find-file "~/org/tasks.org")
)
(global-set-key (kbd "C-c t") 'open-tasks)
