;;; languages.el --- Programming languages configuration -*- lexical-binding: t -*-

;; Author: Ludovico Piero <lewdovico@gnuweeb.org>
;; Version: 0.1.1

;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; TODO

;;; Code:

(use-package lsp-bridge
  :straight '(lsp-bridge :type git :host github :repo "manateelazycat/lsp-bridge"
            :files (:defaults "*.el" "*.py" "acm" "core" "langserver" "multiserver" "resources")
            :build (:not compile))
  :init
  (global-lsp-bridge-mode))

(use-package lsp-ui
 :commands lsp-ui-mode)

(setq major-mode-remap-alist
      '((python-mode . python-ts-mode)
        (rust-mode . rust-ts-mode)
        (js-mode . js-ts-mode)
        (typescript-mode . typescript-ts-mode)))

;; Nix shell interpreter detection
(defun +nix-shell-init-mode ()
  "Resolve a (cached-)?nix-shell shebang to the correct major mode."
  (save-excursion
    (goto-char (point-min))
    (save-match-data
      (if (not (and (re-search-forward "\\_<nix-shell " (line-end-position 2) t)
                    (re-search-forward "-i +\"?\\([^ \"\n]+\\)" (line-end-position) t)))
          (message "Couldn't determine mode for this script")
        (let* ((interp (match-string 1))
               (mode
                (assoc-default
                 interp
                 (mapcar (lambda (e)
                           (cons (format "\\`%s\\'" (car e))
                                 (cdr e)))
                         interpreter-mode-alist)
                 #'string-match-p)))
          (when mode
            (funcall mode)
            (when (eq major-mode 'sh-mode)
              (sh-set-shell interp))
            (setq-local quickrun-option-shebang nil)))))))

(use-package nix-mode
  :ensure t
  :mode "\\.nix\\'"
  :config
  (setq lsp-bridge-nix-lsp-server "nixd"
        lsp-nix-nixd-formatting-command ["nixfmt" "--strict"]
        lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }"
        lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/home/airi/Code/nixos\").nixosConfigurations.sforza.options")
  :hook (nix-mode . lsp)
  :interpreter ("\\(?:cached-\\)?nix-shell" . +nix-shell-init-mode))

(add-to-list 'auto-mode-alist '("/flake\\.lock\\'" . json-mode))

(use-package nix-update
  :commands nix-update-fetch)

;; Golang
(use-package go-mode
  :ensure t
  :mode ("\\.go\\'" . go-ts-mode)
  :hook (go-ts-mode . lsp)
  :config
  (setq lsp-gopls-server-path "gopls"))

;; Python setup
(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-ts-mode)
  :hook (python-ts-mode . lsp)
  :config
  (setq lsp-bridge-python-lsp-server "basedpyright"
        lsp-bridge-python-multi-lsp-server "basedpyright_ruff"))

(with-eval-after-load 'flycheck
  (flycheck-define-checker python-ruff
    "A Python linter using ruff."
    :command ("ruff" "check" source)
    :error-patterns
    ((error line-start (file-name) ":" line ":" column ": " (message) line-end))
    :modes (python-ts-mode))
  (add-to-list 'flycheck-checkers 'python-ruff))

;; Rust setup
(use-package rust-mode
  :ensure nil
  :mode ("\\.rs\\'" . rust-ts-mode)
  :hook (rust-ts-mode . lsp))

;; Web development
(use-package web-mode
  :ensure t
  :mode ("\\.html?\\'" "\\.php\\'")
  :hook (web-mode . lsp)
  :config
  (setq web-mode-enable-current-column-highlight t
        web-mode-enable-current-element-highlight t
        web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2))

(use-package css-mode
  :ensure nil
  :mode "\\.css\\'"
  :hook (css-mode . lsp))

(use-package js
  :ensure nil
  :mode ("\\.js\\'" . js-ts-mode)
  :hook (js-ts-mode . lsp)
  :config
  (setq js-indent-level 2))

(use-package typescript-mode
  :ensure nil
  :mode ("\\.ts\\'" . typescript-ts-mode)
  :hook (typescript-ts-mode . lsp)
  :config
  (setq typescript-indent-level 2))

(provide 'languages)
;;; languages.el ends here
