(menu-bar-mode 0)
(tool-bar-mode 0)
(global-font-lock-mode t)
;;(setq load-path (cons "~/lib" load-path))
(setq visible-bell t) ;;disable system beep
(setq inhibit-startup-message t) ;;disable emacs start screen

;;;load libraries
(add-to-list 'load-path "~/lib/color-theme" "~/lib")


;;;color-theme settings
(require 'color-theme)
(eval-after-load "color-theme"
  '(progn
     (color-theme-initialize)
     (color-theme-hober)))


;;ido-mode settings
;;do not confirm a new file or buffer
(setq confirm-nonexistent-file-or-buffer nil)
(require 'ido)
(ido-mode 1)
(ido-everywhere 1)
(setq ido-enable-flex-matching t)
(setq ido-create-new-buffer 'always)
(setq ido-enable-tramp-completion nil)
(setq ido-enable-last-directory-history nil)
(setq ido-confirm-unique-completion nil) ;; wait for RET, even for unique?
(setq ido-show-dot-for-dired t) ;; put . as the first item
(setq ido-use-filename-at-point t) ;; prefer file names near point


;;;dired settings
(put 'dired-find-alternate-file 'disabled nil)
;;Disable creating new buffer on dired goto parent(^)
     (eval-after-load "dired"
       ;; don't remove `other-window', the caller expects it to be there
       '(defun dired-up-directory (&optional other-window)
          "Run Dired on parent directory of current directory."
          (interactive "P")
          (let* ((dir (dired-current-directory))
     	    (orig (current-buffer))
     	    (up (file-name-directory (directory-file-name dir))))
            (or (dired-goto-file (directory-file-name dir))
     	   ;; Only try dired-goto-subdir if buffer has more than one dir.
     	   (and (cdr dired-subdir-alist)
     		(dired-goto-subdir up))
     	   (progn
     	     (kill-buffer orig)
     	     (dired up)
     	     (dired-goto-file dir))))))
(put 'narrow-to-region 'disabled nil)

;;set HOME variable
(cond ((string= system-name "PBECKER-PC") (setq HOME "e:/home"))
      ((string= system-name "VALVE64") (setq HOME "c:/home")))

;;;cygwin settings

(cond ((string= system-name "PBECKER-PC") (setq cygwin-path "e:/cygwin"))
      ((string= system-name "VALVE64") (setq cygwin-path "c:/cygwin")))

(add-hook 'comint-output-filter-functions
    'shell-strip-ctrl-m nil t)
(add-hook 'comint-output-filter-functions
    'comint-watch-for-password-prompt nil t)
(setq explicit-shell-file-name (concat cygwin-path "/bin/bash.exe"))
;; For subprocesses invoked via the shell
;; (e.g., "shell -c command")
(setq shell-file-name explicit-shell-file-name)
;; Add cygwin directories to the emacs search path
(when (file-exists-p (concat cygwin-path "/bin"))
(setq exec-path (cons "C:/Program Files (x86)/Git/bin" exec-path))
(setq exec-path (cons (concat cygwin-path "/bin") exec-path))
(setq exec-path (cons (concat cygwin-path "/bin") exec-path))
(setenv "PATH" (concat "e:\\cygwin\\bin;" (getenv "PATH")))
(setenv "PATH" (concat "e:\\cygwin\\usr\\local\\bin;" (getenv "PATH"))))
;;Set aspell as spell checker
(setq-default ispell-program-name "aspell")

;;ibuffer
(global-set-key (kbd "C-x C-b") 'ibuffer)
(autoload 'ibuffer "ibuffer" "List buffers." t)

;;SLIME settings
(setq inferior-lisp-program (concat HOME "/bin/clisp/full/lisp.exe -B " HOME "/bin/clisp/full -M " HOME "/bin/clisp/full/lispinit.mem -ansi -q"))
(add-to-list 'load-path "~/bin/emacs/site-lisp/slime/")
(require 'slime)
(slime-setup)

;;w3m settings
(require 'w3m-load)
;;set w3m as default browser
(setq browse-url-browser-function 'w3m-browse-url)
(autoload 'w3m-browse-url "w3m" "Ask a WWW browser to show a URL." t)

