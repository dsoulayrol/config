;; Lua
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
