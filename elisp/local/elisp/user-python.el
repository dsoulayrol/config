;; Python related stuff
;; --------------------
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

;; The same with pyflakes
; (when (load "flymake" t)
;   (defun flymake-pyflakes-init ()
;     (let* ((temp-file (flymake-init-create-temp-buffer-copy
;                        'flymake-create-temp-inplace))
;            (local-file (file-relative-name
;                         temp-file
;                         (file-name-directory buffer-file-name))))
;       (list "pyflakes" (list local-file))))

;   (add-to-list 'flymake-allowed-file-name-masks
;                '("\\.py\\'" flymake-pyflakes-init)))

(add-hook 'python-mode-hook
          '(lambda ()
	     "Don't want flymake mode for python regions in rhtml
	      files and also on read only files"
	     (if (and (not (null buffer-file-name)) (file-writable-p buffer-file-name))
		 (flymake-mode))))

;; Flymake notification without mouse hover.
;; (look for flymake-cursor.el)
(defun show-fly-err-at-point ()
  "If the cursor is sitting on a flymake error, display the
message in the minibuffer"
  (interactive)
  (let ((line-no (line-number-at-pos)))
    (dolist (err flymake-err-info)
      (if (eq (car err) line-no)
          (let ((line-err-info (car (nth 1 err))))
            (message "%s" (fly-pyflake-determine-message line-err-info)))))))

(defun fly-pyflake-determine-message (line-err-info)
  "pyflake is flakey if it has compile problems, this adjusts the
message to display, so there is one ;)"
  (cond ((not (or (eq major-mode 'Python) (eq major-mode 'python-mode) t)))
	((null (flymake-ler-file line-err-info)) ;; normal message do your thing
	 (flymake-ler-text line-err-info))
	(t ;; could not compile err
	 (format "compile error, problem on line %s" (flymake-ler-line line-err-info)))))


;; Ropemacs
;;(require 'pymacs)
;;(pymacs-load "ropemacs" "rope-")
;(setq ropemacs-confirm-saving 'nil)
