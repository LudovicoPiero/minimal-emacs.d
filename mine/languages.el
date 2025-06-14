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

(use-package format-all
  :defer t
  :config
  (setq-default format-all-formatters
                '(("Nix"        (nixfmt "--strict"))
                  ("C"          (clang-format))
                  ("Go"         (gofmt))
                  ("Python"     (ruff))
                  ("Rust"       (rustfmt))
                  ("Emacs Lisp" (emacs-lisp))
	              ("JavaScript" (prettierd))
	              ("JSON"       (prettierd))
	              ("TypeScript" (prettierd))
	              ("Vue"        (prettierd))
	              ("HTML"       (prettierd)))))

(use-package lsp-mode
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l"
        lsp-enable-suggest-server-download nil) ;; disable server downloading suggestions
  :hook (lsp-mode . lsp-enable-which-key-integration))

(use-package lsp-ui
  :commands lsp-ui-mode
  :init
  (setq ;; Sideline
   lsp-ui-sideline-enable nil
   lsp-ui-sideline-show-hover t
   lsp-ui-sideline-show-diagnostics t
   lsp-ui-sideline-show-code-actions t
   lsp-ui-sideline-show-hover t

   ;; Headerline
   lsp-headerline-breadcrumb-enable nil

   ;; Peek
   lsp-ui-peek-enable t
   lsp-ui-peek-show-directory t

   ;; Docs
   lsp-ui-doc-enable t
   lsp-ui-doc-position 'top
   lsp-ui-doc-side 'right
   lsp-ui-doc-delay 0
   lsp-ui-doc-show-with-mouse nil

   ;; imenu
   lsp-ui-imenu-kind-position 'top
   lsp-ui-imenu-buffer-position 'right
   lsp-ui-imenu-window-fix-width nil
   lsp-ui-imenu-auto-refresh nil
   lsp-ui-imenu-auto-refresh-delay 1.0))

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
  :defer t
  :mode "\\.nix\\'"

  :custom
  (lsp-nix-nixd-server-path "nixd")
  (lsp-nix-nixd-formatting-command [ "nixfmt" "--strict" ])
  (lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }")
  (lsp-nix-nixd-nixos-options-expr
   (concat "(builtins.getFlake \"/home/airi/Code/nixos\")"
           ".nixosConfigurations.sforza.options"))
  (lsp-nix-nixd-home-manager-options-expr
   (concat "(builtins.getFlake \"/home/airi/Code/nvim-flake\")"
           ".homeConfigurations.\"airi@sforza\".options"))

  :hook (nix-mode . lsp-deferred)
  :interpreter ("\\(?:cached-\\)?nix-shell" . +nix-shell-init-mode))

(add-to-list 'auto-mode-alist '("flake\\.lock\\'" . json-ts-mode))

(use-package nix-update
  :commands nix-update-fetch)

;; Golang
(use-package go-mode
  :ensure t
  :mode ("\\.go\\'" . go-ts-mode)
  :hook (go-ts-mode . lsp-deferred)
  :config
  (setq lsp-gopls-server-path "gopls"))

;; Python setup
(use-package python
  :ensure nil
  :mode ("\\.py\\'" . python-ts-mode)
  :hook (python-ts-mode . lsp-deferred)
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
  :hook (rust-ts-mode . lsp-deferred))

;;;;;;;;;;;;;;;;;;;;;;;;
;;  Web development   ;;
;;;;;;;;;;;;;;;;;;;;;;;;
(dolist (remap '((js-mode         . js-ts-mode)
                 (typescript-mode . typescript-ts-mode)
                 (html-mode       . html-ts-mode)
                 (php-mode        . php-ts-mode)
                 (tsx-mode        . tsx-ts-mode)
                 (jsx-mode        . js-ts-mode)))
  (add-to-list 'major-mode-remap-alist remap))

;; HTML (Tree-sitter)
(use-package html-ts-mode
  :ensure nil
  :mode ("\\.html?\\'" . html-ts-mode)
  :hook (html-ts-mode . lsp-deferred)
  :config
  (setq-local indent-tabs-mode nil
              tab-width 2))

;; PHP (Tree-sitter)
(use-package php-ts-mode
  :ensure nil
  :mode ("\\.php\\'" . php-ts-mode)
  :hook (php-ts-mode . lsp-deferred)
  :config
  (setq-local indent-tabs-mode nil
              tab-width 2))

;; CSS
(use-package css-mode
  :ensure nil
  :mode "\\.css\\'"
  :hook (css-mode . lsp-deferred)
  :config
  (setq css-indent-offset 2))

;; TypeScript (Tree-sitter)
(use-package typescript-mode
  :ensure nil
  :mode ("\\.ts\\'" . typescript-ts-mode)
  :hook (typescript-ts-mode . lsp-deferred)
  :config
  (setq typescript-indent-level 2
        tab-width 2
        indent-tabs-mode nil))

;; JavaScript (Tree-sitter)
(use-package js
  :ensure nil
  :mode (("\\.js\\'" . js-ts-mode)
         ("\\.jsx\\'" . js-ts-mode))
  :hook (js-ts-mode . lsp-deferred)
  :config
  (setq-local js-indent-level 2
              tab-width 2
              indent-tabs-mode nil))

;; TSX (Tree-sitter)
(use-package tsx-ts-mode
  :ensure nil
  :mode ("\\.tsx\\'" . tsx-ts-mode)
  :hook (tsx-ts-mode . lsp-deferred)
  :config
  (setq-local tab-width 2
              indent-tabs-mode nil))

;; Optional: Astro, Vue, ERB, EJS, etc. using web-mode
(defun airi/web-mode-lsp-if-supported ()
  (when (member (file-name-extension (or buffer-file-name "")) '("astro" "vue" "erb" "ejs" "tmpl"))
    (lsp-deferred)))

(use-package web-mode
  :ensure t
  :mode (("\\.astro\\'" . web-mode)
         ("\\.vue\\'"  . web-mode)
         ("\\.erb\\'"  . web-mode)
         ("\\.ejs\\'"  . web-mode)
         ("\\.tmpl\\'" . web-mode))
  :hook (web-mode . airi/web-mode-lsp-if-supported)
  :config
  (setq-local indent-tabs-mode nil
              tab-width 2
              web-mode-enable-current-column-highlight t
              web-mode-enable-current-element-highlight t
              web-mode-markup-indent-offset 2
              web-mode-css-indent-offset 2
              web-mode-code-indent-offset 2))

(provide 'languages)
;;; languages.el ends here
