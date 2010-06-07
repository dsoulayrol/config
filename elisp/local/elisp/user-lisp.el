;; Lisp related stuff
;; --------------------

(when (require 'elk-test "elk-test-0.3.2/elk-test" 'noerror)
  (autoload 'elk-test-mode "elk-test" nil t)
  (add-to-list 'auto-mode-alist '("\\.elk\\'" . elk-test-mode)))
