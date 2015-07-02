;;; init.el --- Cody Reichert's Emacs Configuration

;;; Commentary:
;;; This is yet another config file.

;;; Code:
(add-to-list 'load-path "~/.emacs.d/config")
(add-to-list 'load-path "~/.emacs.d/scripts")

(require 'init-packages)
(require 'init-utils)
(require 'init-settings)
(require 'init-sml)

(require 'init-autocomplete)
(require 'init-circe)
(require 'init-compilation)
(require 'init-eshell)
(require 'init-evil)
(require 'init-haskell)
(require 'init-helm)
(require 'init-ido)
(require 'init-magit)
(require 'init-mu)
(require 'init-org)
(require 'init-orgpage)
(require 'init-projectile)
(require 'init-web)
(require 'init-yasnippets)


(provide 'init)

;;; init.el ends here