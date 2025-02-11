;;
;; .emacs
;;

;;disable splash screen and startup message
(setq inhibit-startup-message t) 
(setq initial-scratch-message nil)

;; ESC SPACE is set-mark-command
(define-key global-map "\M- " 'set-mark-command)

;; Japanese Settings
(set-language-environment "Japanese")
(prefer-coding-system  'utf-8-unix)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-buffer-file-coding-system 'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
(set-default-coding-systems 'utf-8)
(setq file-name-coding-system 'utf-8)

;; タブにスペースを使用する
(setq-default tab-width 4 indent-tabs-mode nil)

;; 改行コードを表示する
(setq eol-mnemonic-dos "(CRLF)")
(setq eol-mnemonic-mac "(CR)")
(setq eol-mnemonic-unix "(LF)")

;; シフト＋矢印で範囲選択
;;(setq pc-select-selection-keys-only t)
;;(pc-selection-mode 1)

;;; uncomment this line to disable loading of "default.el" at startup
;; (setq inhibit-default-init t)

;; turn on font-lock mode
;(when (fboundp 'global-font-lock-mode)
;  (global-font-lock-mode t))

;; enable visual feedback on selections
;(setq transient-mark-mode t)

;; default to better frame titles
;(setq frame-title-format
;      (concat  "%b - emacs@" (system-name)))

;; default to unified diffs
(setq diff-switches "-u")

;; always end a file with a newline
;(setq require-final-newline 'query)

;; do not create backup file
(setq backup-inhibited t)

;; delete auto-save file on exit
(setq delete-auto-save-files t)

;; display cursor column
(column-number-mode t)

;; display cursor line
(line-number-mode t)

;; set scroll line to 2
(setq scroll-step 2)

;; display time into mode line
(display-time)

;;
;; eww setting
;;

;; 開始サイト
;; google に変更
;; (setq eww-search-prefix "https://www.google.co.jp/search?q=")

;; eww buffer の名前を webページのタイトル名に変更する
(setq eww-auto-rename-buffer t)

;; cookie を保存する間隔 (秒)
(setq url-cookie-save-interval 60)

;;
;; ewwのテキストの色設定を無効にする。黒背景だとgoogle検索の文字が見えないので。
;;
(defvar eww-disable-colorize t)
(defun shr-colorize-region--disable (orig start end fg &optional bg &rest _)
  (unless eww-disable-colorize
    (funcall orig start end fg)))
(advice-add 'shr-colorize-region :around 'shr-colorize-region--disable)
(advice-add 'eww-colorize-region :around 'shr-colorize-region--disable)
(defun eww-disable-color ()
  "eww で文字色を反映させない"
  (interactive)
  (setq-local eww-disable-colorize t)
  (eww-reload))
(defun eww-enable-color ()
  "eww で文字色を反映させる"
  (interactive)
  (setq-local eww-disable-colorize nil)
  (eww-reload))

