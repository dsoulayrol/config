;; Fonte d'affichage par défaut
;;   (http://www.lowing.org/fonts/
;;    http://www.emacswiki.org/cgi-bin/wiki/GoodFonts)
(set-frame-font "-bitstream-Bitstream Vera Sans Mono-normal-normal-normal-*-12-*-*-*-m-0-iso8859-1")
(setq default-frame-alist '((font . "-bitstream-Bitstream Vera Sans Mono-normal-normal-normal-*-12-*-*-*-m-0-iso8859-1")))

(menu-bar-mode 0)
(tool-bar-mode 0)
(column-number-mode t)
(mouse-wheel-mode t)
(setq visible-bell t)

(if (require 'sml-modeline nil 'noerror)
    (progn
      (sml-modeline-mode 1)
      (scroll-bar-mode -1))
  (scroll-bar-mode 1)
  (set-scroll-bar-mode 'right))
