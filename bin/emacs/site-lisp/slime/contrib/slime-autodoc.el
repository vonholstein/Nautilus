;;; slime-autodoc.el --- show fancy arglist in echo area
;;
;; Authors: Luke Gorrie  <luke@bluetail.com>
;;          Lawrence Mitchell  <wence@gmx.li>
;;          Matthias Koeppe  <mkoeppe@mail.math.uni-magdeburg.de>
;;          Tobias C. Rittweiler <tcr@freebits.de>
;;          and others
;; 
;; License: GNU GPL (same license as Emacs)
;;
;;; Installation:
;;
;; Add this to your .emacs: 
;;
;;   (add-to-list 'load-path "<directory-of-this-file>")
;;   (add-hook 'slime-load-hook (lambda () (require 'slime-autodoc)))
;;

(eval-and-compile
  (assert (not (featurep 'xemacs)) ()
	  "slime-autodoc doesn't work with XEmacs"))

(require 'slime-parse)
(require 'slime-enclosing-context)

(defcustom slime-use-autodoc-mode t
  "When non-nil always enable slime-autodoc-mode in slime-mode.")

(defcustom slime-autodoc-use-multiline-p nil
  "If non-nil, allow long autodoc messages to resize echo area display."
  :type 'boolean
  :group 'slime-ui)

(defcustom slime-autodoc-delay 0.3
  "*Delay before autodoc messages are fetched and displayed, in seconds."
  :type 'number
  :group 'slime-ui)

(defcustom slime-autodoc-accuracy-depth 10
  "Number of paren levels that autodoc takes into account for
  context-sensitive arglist display (local functions. etc)")



(defun slime-arglist (name)
  "Show the argument list for NAME."
  (interactive (list (slime-read-symbol-name "Arglist of: " t)))
  (let ((arglist (slime-retrieve-arglist name)))
    (if (eq arglist :not-available)
        (error "Arglist not available")
        (message "%s" (slime-fontify-string arglist)))))

(defun slime-retrieve-arglist (name)
  (let ((name (etypecase name
                 (string name)
                 (symbol (symbol-name name)))))
    (slime-eval `(swank:arglist-for-echo-area '(,name ,slime-cursor-marker)))))


;;;; Autodocs (automatic context-sensitive help)

(defun slime-make-autodoc-rpc-form ()
  "Return a cache key and a swank form."
  (let ((global (slime-autodoc-global-at-point)))
    (if global
        (values (slime-qualify-cl-symbol-name global)
                `(swank:variable-desc-for-echo-area ,global))
        (let* ((levels slime-autodoc-accuracy-depth)
               (buffer-form (slime-parse-form-upto-point levels)))
          (values buffer-form
                  (multiple-value-bind (width height)
                      (slime-autodoc-message-dimensions)
                    `(swank:arglist-for-echo-area ',buffer-form
                                                  :print-right-margin ,width
                                                  :print-lines ,height)))))))

(defun slime-autodoc-global-at-point ()
  "Return the global variable name at point, if any."
  (when-let (name (slime-symbol-at-point))
    (and (slime-global-variable-name-p name) name)))

(defcustom slime-global-variable-name-regexp "^\\(.*:\\)?\\([*+]\\).+\\2$"
  "Regexp used to check if a symbol name is a global variable.

Default value assumes +this+ or *that* naming conventions."
  :type 'regexp
  :group 'slime)

(defun slime-global-variable-name-p (name)
  "Is NAME a global variable?
Globals are recognised purely by *this-naming-convention*."
  (and (< (length name) 80) ; avoid overflows in regexp matcher
       (string-match slime-global-variable-name-regexp name)))

(defvar slime-autodoc-dimensions-function nil)

(defun slime-autodoc-message-dimensions ()
  "Return the available width and height for pretty printing autodoc
messages."
  (cond
   (slime-autodoc-dimensions-function
    (funcall slime-autodoc-dimensions-function))
   (slime-autodoc-use-multiline-p 
    ;; Use the full width of the minibuffer;
    ;; minibuffer will grow vertically if necessary
    (values (window-width (minibuffer-window))
            nil))
   (t
    ;; Try to fit everything in one line; we cut off when displaying
    (values 1000 1))))


;;;; Autodoc cache

(defvar slime-autodoc-cache-type 'last
  "*Cache policy for automatically fetched documentation.
Possible values are:
 nil  - none.
 last - cache only the most recently-looked-at symbol's documentation.
        The values are stored in the variable `slime-autodoc-cache'.

More caching means fewer calls to the Lisp process, but at the risk of
using outdated information.")

(defvar slime-autodoc-cache nil
  "Cache variable for when `slime-autodoc-cache-type' is 'last'.
The value is (SYMBOL-NAME . DOCUMENTATION).")

(defun slime-get-cached-autodoc (symbol-name)
  "Return the cached autodoc documentation for SYMBOL-NAME, or nil."
  (ecase slime-autodoc-cache-type
    ((nil) nil)
    ((last)
     (when (equal (car slime-autodoc-cache) symbol-name)
       (cdr slime-autodoc-cache)))
    ((all)
     (when-let (symbol (intern-soft symbol-name))
       (get symbol 'slime-autodoc-cache)))))

(defun slime-store-into-autodoc-cache (symbol-name documentation)
  "Update the autodoc cache for SYMBOL with DOCUMENTATION.
Return DOCUMENTATION."
  (ecase slime-autodoc-cache-type
    ((nil) nil)
    ((last)
     (setq slime-autodoc-cache (cons symbol-name documentation)))
    ((all)
     (put (intern symbol-name) 'slime-autodoc-cache documentation)))
  documentation)


;;;; Formatting autodoc

(defun slime-format-autodoc (doc)
  (setq doc (slime-fontify-string doc))
  (unless slime-autodoc-use-multiline-p
    (setq doc (slime-oneliner doc)))
  doc)

(defun slime-fontify-string (string)
  "Fontify STRING as `font-lock-mode' does in Lisp mode."
  (with-current-buffer (get-buffer-create " *slime-fontify*")
    (erase-buffer)
    (unless (eq major-mode 'lisp-mode)
      ;; Just calling (lisp-mode) will turn slime-mode on in that buffer,
      ;; which may interfere with this function
      (setq major-mode 'lisp-mode)
      (lisp-mode-variables t))
    (insert string)
    (let ((font-lock-verbose nil))
      (font-lock-fontify-buffer))
    (goto-char (point-min))
    (when (re-search-forward "===> \\(\\(.\\|\n\\)*\\) <===" nil t)
      (let ((highlight (match-string 1)))
        ;; Can't use (replace-match highlight) here -- broken in Emacs 21
        (delete-region (match-beginning 0) (match-end 0))
	(slime-insert-propertized '(face highlight) highlight)))
    (buffer-substring (point-min) (point-max))))


;;;; slime-autodoc-mode


(defun slime-compute-autodoc ()
  "Returns the cached arglist information as string, or nil.
If it's not in the cache, the cache will be updated asynchronously."
  (save-excursion
    ;; Save match data just in case. This is automatically run in
    ;; background, so it'd be rather disastrous if it touched match
    ;; data.
    (save-match-data
      (unless (slime-inside-string-or-comment-p)
        (multiple-value-bind (cache-key retrieve-form) (slime-make-autodoc-rpc-form)
          (let ((cached (slime-get-cached-autodoc cache-key)))
            (if cached
                cached
                ;; If nothing is in the cache, we first decline, and fetch
                ;; the arglist information asynchronously.
                (prog1 nil
                  (slime-eval-async retrieve-form
                    (lexical-let ((cache-key cache-key)) 
                      (lambda (doc)
                        (let ((doc (if (eq doc :not-available)
                                       ""
                                       (slime-format-autodoc doc))))
                          ;; Now that we've got our information, get it to
                          ;; the user ASAP.
                          (eldoc-message doc)
                          (slime-store-into-autodoc-cache cache-key doc)))))))))))))

(make-variable-buffer-local (defvar slime-autodoc-mode nil))

(defun slime-autodoc-mode (&optional arg)
  (interactive "P")
  (make-local-variable 'eldoc-documentation-function)
  (make-local-variable 'eldoc-idle-delay)
  (setq eldoc-documentation-function 'slime-compute-autodoc)
  (setq eldoc-idle-delay slime-autodoc-delay)
  (eldoc-mode arg)
  (cond (eldoc-mode
	 (setq slime-echo-arglist-function 
	       (lambda () (eldoc-message (slime-compute-autodoc))))
	 (setq slime-autodoc-mode t))
	(t
	 (setq slime-echo-arglist-function 'slime-show-arglist)
	 (setq slime-autodoc-mode nil))))

(defadvice eldoc-display-message-no-interference-p 
    (after slime-autodoc-message-ok-p)
  (when slime-autodoc-mode
    (setq ad-return-value
          (and ad-return-value
               ;; Display arglist only when the minibuffer is
               ;; inactive, e.g. not on `C-x C-f'.
               (not (active-minibuffer-window))
               ;; Display arglist only when inferior Lisp will be able
               ;; to cope with the request.
               (slime-background-activities-enabled-p))))
  ad-return-value)


;;;; Initialization

(defun slime-autodoc-init ()
  (dolist (h '(slime-mode-hook slime-repl-mode-hook sldb-mode-hook))
    (add-hook h 'slime-autodoc-maybe-enable)))

(defun slime-autodoc-maybe-enable ()
  (when slime-use-autodoc-mode 
    (slime-autodoc-mode 1)))

;;; FIXME: This doesn't disable eldoc-mode in existing buffers.
(defun slime-autodoc-unload ()
  (setq slime-echo-arglist-function 'slime-show-arglist)
  (dolist (h '(slime-mode-hook slime-repl-mode-hook sldb-mode-hook))
    (remove-hook h 'slime-autodoc-maybe-enable)))

(slime-require :swank-arglists)



;;;; Test cases

(defun slime-check-autodoc-at-point (arglist)
  (slime-test-expect (format "Autodoc in `%s' (at %d) is as expected" 
                             (buffer-string) (point)) 
                     arglist
                     (slime-eval (second (slime-make-autodoc-rpc-form)))
                     'equal))

(def-slime-test autodoc.1
    (buffer-sexpr wished-arglist)
    ""
    '(("(swank::emacs-connected*HERE*"    "(emacs-connected)")
      ("(swank::create-socket*HERE*"      "(create-socket host port)")
      ("(swank::create-socket *HERE*"     "(create-socket ===> host <=== port)")
      ("(swank::create-socket foo *HERE*" "(create-socket host ===> port <===)")

      ("(swank::symbol-status foo *HERE*" 
       "(symbol-status symbol &optional ===> (package (symbol-package symbol)) <===)")

      ("(defmethod swank::arglist-dispatch (*HERE*"
       "(defmethod arglist-dispatch (===> operator <=== arguments) &body body)")
      ("(apply 'swank::eval-for-emacs*HERE*"
       "(apply 'eval-for-emacs &optional form buffer-package id &rest args)")

      ("(apply #'swank::eval-for-emacs*HERE*"
       "(apply #'eval-for-emacs &optional form buffer-package id &rest args)")

      ("(apply 'swank::eval-for-emacs foo *HERE*"
       "(apply 'eval-for-emacs &optional form ===> buffer-package <=== id &rest args)")

      ("(apply #'swank::eval-for-emacs foo *HERE*"
       "(apply #'eval-for-emacs &optional form ===> buffer-package <=== id &rest args)"))
  (slime-check-top-level)
  (with-temp-buffer
    (setq slime-buffer-package "COMMON-LISP-USER")
    (lisp-mode)
    (insert buffer-sexpr)
    (search-backward "*HERE*")
    (delete-region (match-beginning 0) (match-end 0))
    (slime-check-autodoc-at-point wished-arglist)
    (insert ")") (backward-char)
    (slime-check-autodoc-at-point wished-arglist)
    ))

(provide 'slime-autodoc)
