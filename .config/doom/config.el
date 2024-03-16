;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq shell-file-name (executable-find "zsh"))

(setq-default vterm-shell (executable-find "fish"))
(setq-default explicit-shell-file-name (executable-find "fish"))

(setq user-full-name "Evan Riley"
      user-mail-address (rot13 "rina@rinaevyrl.arg"))

(setq auth-sources '("~/.authinfo.gpg")
      auth-source-cache-expiry nil) ; default is 7200 (2h)

(setq-default
 delete-by-moving-to-trash t                      ; Delete files to trash
 window-combination-resize t                      ; take new window space from all other windows (not just current)
 x-stretch-cursor t)                              ; Stretch cursor to the glyph width

(setq undo-limit 80000000                         ; Raise undo-limit to 80Mb
      evil-want-fine-undo t                       ; By default while in insert all changes are one big blob. Be more granular
      auto-save-default t                         ; Nobody likes to loose work, I certainly don't
      password-cache-expiry nil                   ; I can trust my computers ... can't I?
      ;; scroll-preserve-screen-position 'always     ; Don't have `point' jump around
      scroll-margin 2                             ; It's nice to maintain a little margin
      display-time-default-load-average nil)      ; I don't think I've ever found this useful

(display-time-mode 1)                             ; Enable time in the mode-line

(global-subword-mode 1)                           ; Iterate through CamelCase words

(setq-default custom-file (expand-file-name ".custom.el" doom-private-dir))
(when (file-exists-p custom-file)
  (load custom-file))

(setq doom-font (font-spec :family "0xProto Nerd Font" :size 17)
      doom-big-font (font-spec :family "OxProto Nerd Font" :size 32)
      doom-variable-pitch-font (font-spec :family "Overpass" :size 17)
      doom-unicode-font (font-spec :family "JuliaMono")
      doom-serif-font (font-spec :family "IBM Plex Mono" :size 22 :weight 'light))

(setq doom-theme 'doom-badger)

(setq display-line-numbers-type 'relative)

(defvar fancy-splash-image-directory
  (expand-file-name "misc/splash-images/" doom-private-dir)
  "Directory in which to look for splash image templates.")

(defvar fancy-splash-image-template
  (expand-file-name "emacs-e-template.svg" fancy-splash-image-directory)
  "Default template svg used for the splash image.
Colours are substituted as per `fancy-splash-template-colours'.")

(defvar fancy-splash-template-colours
  '(("#111112" :face default   :attr :foreground)
    ("#8b8c8d" :face shadow)
    ("#eeeeef" :face default   :attr :background)
    ("#e66100" :face highlight :attr :background)
    ("#1c71d8" :face font-lock-keyword-face)
    ("#f5c211" :face font-lock-type-face)
    ("#813d9c" :face font-lock-constant-face)
    ("#865e3c" :face font-lock-function-name-face)
    ("#2ec27e" :face font-lock-string-face)
    ("#c01c28" :face error)
    ("#000001" :face ansi-color-black)
    ("#ff0000" :face ansi-color-red)
    ("#ff00ff" :face ansi-color-magenta)
    ("#00ff00" :face ansi-color-green)
    ("#ffff00" :face ansi-color-yellow)
    ("#0000ff" :face ansi-color-blue)
    ("#00ffff" :face ansi-color-cyan)
    ("#fffffe" :face ansi-color-white))
  "Alist of colour-replacement plists.
Each plist is of the form (\"$placeholder\" :doom-color 'key :face 'face).
If the current theme is a doom theme :doom-color will be used,
otherwise the colour will be face foreground.")

(defun fancy-splash-check-buffer ()
  "Check the current SVG buffer for bad colours."
  (interactive)
  (when (eq major-mode 'image-mode)
    (xml-mode))
  (when (and (featurep 'rainbow-mode)
             (not (bound-and-true-p rainbow-mode)))
    (rainbow-mode 1))
  (let* ((colours (mapcar #'car fancy-splash-template-colours))
         (colourise-hex
          (lambda (hex)
            (propertize
             hex
             'face `((:foreground
                      ,(if (< 0.5
                              (cl-destructuring-bind (r g b) (x-color-values hex)
                                ;; Values taken from `rainbow-color-luminance'
                                (/ (+ (* .2126 r) (* .7152 g) (* .0722 b))
                                   (* 256 255 1.0))))
                           "white" "black")
                      (:background ,hex))))))
         (cn 96)
         (colour-menu-entries
          (mapcar
           (lambda (colour)
             (cl-incf cn)
             (cons cn
                   (cons
                    (substring-no-properties colour)
                    (format " (%s) %s %s"
                            (propertize (char-to-string cn)
                                        'face 'font-lock-keyword-face)
                            (funcall colourise-hex colour)
                            (propertize
                             (symbol-name
                              (plist-get
                               (cdr (assoc colour fancy-splash-template-colours))
                               :face))
                             'face 'shadow)))))
           colours))
         (colour-menu-template
          (format
           "Colour %%s is unexpected! Should this be one of the following?\n
%s
 %s to ignore
 %s to quit"
           (mapconcat
            #'cddr
            colour-menu-entries
            "\n")
           (propertize "SPC" 'face 'font-lock-keyword-face)
           (propertize "ESC" 'face 'font-lock-keyword-face)))
         (colour-menu-choice-keys
          (append (mapcar #'car colour-menu-entries)
                  (list ?\s)))
         (buf (get-buffer-create "*fancy-splash-lint-colours-popup*"))
         (good-colour-p
          (lambda (colour)
            (or (assoc colour fancy-splash-template-colours)
                ;; Check if greyscale
                (or (and (= (length colour) 4)
                         (= (aref colour 1)   ; r
                            (aref colour 2)   ; g
                            (aref colour 3))) ; b
                    (and (= (length colour) 7)
                         (string= (substring colour 1 3)       ; rr =
                                  (substring colour 3 5))      ; gg
                         (string= (substring colour 3 5)       ; gg =
                                  (substring colour 5 7))))))) ; bb
         (prompt-to-replace
          (lambda (target)
            (with-current-buffer buf
              (erase-buffer)
              (insert (format colour-menu-template
                              (funcall colourise-hex target)))
              (setq-local cursor-type nil)
              (set-buffer-modified-p nil)
              (goto-char (point-min)))
            (save-window-excursion
              (pop-to-buffer buf)
              (fit-window-to-buffer (get-buffer-window buf))
              (car (alist-get
                    (read-char-choice
                     (format "Select replacement, %s-%s or SPC: "
                             (char-to-string (caar colour-menu-entries))
                             (char-to-string (caar (last colour-menu-entries))))
                     colour-menu-choice-keys)
                    colour-menu-entries))))))
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "#[0-9A-Fa-f]\\{6\\}\\|#[0-9A-Fa-f]\\{3\\}" nil t)
        (recenter)
        (let* ((colour (match-string 0))
               (replacement (and (not (funcall good-colour-p colour))
                                 (funcall prompt-to-replace colour))))
          (when replacement
            (replace-match replacement t t))))
      (message "Done"))))

(defvar fancy-splash-cache-dir (expand-file-name "theme-splashes/" doom-cache-dir))

(defvar fancy-splash-sizes
  `((:height 300 :min-height 50 :padding (0 . 2))
    (:height 250 :min-height 42 :padding (2 . 4))
    (:height 200 :min-height 35 :padding (3 . 3))
    (:height 150 :min-height 28 :padding (3 . 3))
    (:height 100 :min-height 20 :padding (2 . 2))
    (:height 75  :min-height 15 :padding (2 . 1))
    (:height 50  :min-height 10 :padding (1 . 0))
    (:height 1   :min-height 0  :padding (0 . 0)))
  "List of plists specifying image sizing states.
Each plist should have the following properties:
- :height, the height of the image
- :min-height, the minimum `frame-height' for image
- :padding, a `+doom-dashboard-banner-padding' (top . bottom) padding
  specification to apply
Optionally, each plist may set the following two properties:
- :template, a non-default template file
- :file, a file to use instead of template")

(defun fancy-splash-filename (theme template height)
  "Get the file name for the splash image with THEME and of HEIGHT."
  (expand-file-name (format "%s-%s-%d.svg" theme (file-name-base template) height) fancy-splash-cache-dir))

(defun fancy-splash-generate-image (template height)
  "Create a themed image from TEMPLATE of HEIGHT.
The theming is performed using `fancy-splash-template-colours'
and the current theme."
  (with-temp-buffer
    (insert-file-contents template)
    (goto-char (point-min))
    (if (re-search-forward "$height" nil t)
        (replace-match (number-to-string height) t t)
      (if (re-search-forward "height=\"100\\(?:\\.0[0-9]*\\)?\"" nil t)
          (progn
            (replace-match (format "height=\"%s\"" height) t t)
            (goto-char (point-min))
            (when (re-search-forward "\\([ \t\n]\\)width=\"[\\.0-9]+\"[ \t\n]*" nil t)
              (replace-match "\\1")))
        (warn "Warning! fancy splash template: neither $height nor height=100 not found in %s" template)))
    (dolist (substitution fancy-splash-template-colours)
      (goto-char (point-min))
      (let* ((replacement-colour
              (face-attribute (plist-get (cdr substitution) :face)
                              (or (plist-get (cdr substitution) :attr) :foreground)
                              nil 'default))
             (replacement-hex
              (if (string-prefix-p "#" replacement-colour)
                  replacement-colour
                (apply 'format "#%02x%02x%02x"
                       (mapcar (lambda (c) (ash c -8))
                               (color-values replacement-colour))))))
        (while (search-forward (car substitution) nil t)
          (replace-match replacement-hex nil nil))))
    (unless (file-exists-p fancy-splash-cache-dir)
      (make-directory fancy-splash-cache-dir t))
    (let ((inhibit-message t))
      (write-region nil nil (fancy-splash-filename (car custom-enabled-themes) template height)))))

(defun fancy-splash-generate-all-images ()
  "Perform `fancy-splash-generate-image' in bulk."
  (dolist (size fancy-splash-sizes)
    (unless (plist-get size :file)
      (fancy-splash-generate-image
       (or (plist-get size :template)
           fancy-splash-image-template)
       (plist-get size :height)))))

(defun fancy-splash-ensure-theme-images-exist (&optional height)
  "Ensure that the relevant images exist.
Use the image of HEIGHT to check, defaulting to the height of the first
specification in `fancy-splash-sizes'. If that file does not exist for
the current theme, `fancy-splash-generate-all-images' is called. "
  (unless (file-exists-p
           (fancy-splash-filename
            (car custom-enabled-themes)
            fancy-splash-image-template
            (or height (plist-get (car fancy-splash-sizes) :height))))
    (fancy-splash-generate-all-images)))

(defun fancy-splash-clear-cache (&optional delete-files)
  "Clear all cached fancy splash images.
Optionally delete all cache files and regenerate the currently relevant set."
  (interactive (list t))
  (dolist (size fancy-splash-sizes)
    (unless (plist-get size :file)
      (let ((image-file
             (fancy-splash-filename
              (car custom-enabled-themes)
              (or (plist-get size :template)
                  fancy-splash-image-template)
              (plist-get size :height))))
        (image-flush (create-image image-file) t))))
  (message "Fancy splash image cache cleared!")
  (when delete-files
    (delete-directory fancy-splash-cache-dir t)
    (fancy-splash-generate-all-images)
    (message "Fancy splash images cache deleted!")))

(defun fancy-splash-switch-template ()
  "Switch the template used for the fancy splash image."
  (interactive)
  (let ((new (completing-read
              "Splash template: "
              (mapcar
               (lambda (template)
                 (replace-regexp-in-string "-template\\.svg$" "" template))
               (directory-files fancy-splash-image-directory nil "-template\\.svg\\'"))
              nil t)))
    (setq fancy-splash-image-template
          (expand-file-name (concat new "-template.svg") fancy-splash-image-directory))
    (fancy-splash-clear-cache)
    (message "") ; Clear message from `fancy-splash-clear-cache'.
    (setq fancy-splash--last-size nil)
    (fancy-splash-apply-appropriate-image)))

(defun fancy-splash-get-appropriate-size ()
  "Find the firt `fancy-splash-sizes' with min-height of at least frame height."
  (let ((height (frame-height)))
    (cl-some (lambda (size) (when (>= height (plist-get size :min-height)) size))
             fancy-splash-sizes)))

(setq fancy-splash--last-size nil)
(setq fancy-splash--last-theme nil)

(defun fancy-splash-apply-appropriate-image (&rest _)
  "Ensure the appropriate splash image is applied to the dashboard.
This function's signature is \"&rest _\" to allow it to be used
in hooks that call functions with arguments."
  (let ((appropriate-size (fancy-splash-get-appropriate-size)))
    (unless (and (equal appropriate-size fancy-splash--last-size)
                 (equal (car custom-enabled-themes) fancy-splash--last-theme))
      (unless (plist-get appropriate-size :file)
        (fancy-splash-ensure-theme-images-exist (plist-get appropriate-size :height)))
      (setq fancy-splash-image
            (or (plist-get appropriate-size :file)
                (fancy-splash-filename (car custom-enabled-themes)
                                       fancy-splash-image-template
                                       (plist-get appropriate-size :height)))
            +doom-dashboard-banner-padding (plist-get appropriate-size :padding)
            fancy-splash--last-size appropriate-size
            fancy-splash--last-theme (car custom-enabled-themes))
      (+doom-dashboard-reload))))

(defun doom-dashboard-draw-ascii-emacs-banner-fn ()
  (let* ((banner
          '(",---.,-.-.,---.,---.,---."
            "|---'| | |,---||    `---."
            "`---'` ' '`---^`---'`---'"))
         (longest-line (apply #'max (mapcar #'length banner))))
    (put-text-property
     (point)
     (dolist (line banner (point))
       (insert (+doom-dashboard--center
                +doom-dashboard--width
                (concat
                 line (make-string (max 0 (- longest-line (length line)))
                                   32)))
               "\n"))
     'face 'doom-dashboard-banner)))

(unless (display-graphic-p) ; for some reason this messes up the graphical splash screen atm
  (setq +doom-dashboard-ascii-banner-fn #'doom-dashboard-draw-ascii-emacs-banner-fn))

(defvar splash-phrase-source-folder
  (expand-file-name "misc/splash-phrases" doom-private-dir)
  "A folder of text files with a fun phrase on each line.")

(defvar splash-phrase-sources
  (let* ((files (directory-files splash-phrase-source-folder nil "\\.txt\\'"))
         (sets (delete-dups (mapcar
                             (lambda (file)
                               (replace-regexp-in-string "\\(?:-[0-9]+-\\w+\\)?\\.txt" "" file))
                             files))))
    (mapcar (lambda (sset)
              (cons sset
                    (delq nil (mapcar
                               (lambda (file)
                                 (when (string-match-p (regexp-quote sset) file)
                                   file))
                               files))))
            sets))
  "A list of cons giving the phrase set name, and a list of files which contain phrase components.")

(defvar splash-phrase-set
  (nth (random (length splash-phrase-sources)) (mapcar #'car splash-phrase-sources))
  "The default phrase set. See `splash-phrase-sources'.")

(defun splash-phrase-set-random-set ()
  "Set a new random splash phrase set."
  (interactive)
  (setq splash-phrase-set
        (nth (random (1- (length splash-phrase-sources)))
             (cl-set-difference (mapcar #'car splash-phrase-sources) (list splash-phrase-set))))
  (+doom-dashboard-reload t))

(defun splash-phrase-select-set ()
  "Select a specific splash phrase set."
  (interactive)
  (setq splash-phrase-set (completing-read "Phrase set: " (mapcar #'car splash-phrase-sources)))
  (+doom-dashboard-reload t))

(defvar splash-phrase--cached-lines nil)

(defun splash-phrase-get-from-file (file)
  "Fetch a random line from FILE."
  (let ((lines (or (cdr (assoc file splash-phrase--cached-lines))
                   (cdar (push (cons file
                                     (with-temp-buffer
                                       (insert-file-contents (expand-file-name file splash-phrase-source-folder))
                                       (split-string (string-trim (buffer-string)) "\n")))
                               splash-phrase--cached-lines)))))
    (nth (random (length lines)) lines)))

(defun splash-phrase (&optional set)
  "Construct a splash phrase from SET. See `splash-phrase-sources'."
  (mapconcat
   #'splash-phrase-get-from-file
   (cdr (assoc (or set splash-phrase-set) splash-phrase-sources))
   " "))

(defun splash-phrase-dashboard-formatted ()
  "Get a splash phrase, flow it over multiple lines as needed, and fontify it."
  (mapconcat
   (lambda (line)
     (+doom-dashboard--center
      +doom-dashboard--width
      (with-temp-buffer
        (insert-text-button
         line
         'action
         (lambda (_) (+doom-dashboard-reload t))
         'face 'doom-dashboard-menu-title
         'mouse-face 'doom-dashboard-menu-title
         'help-echo "Random phrase"
         'follow-link t)
        (buffer-string))))
   (split-string
    (with-temp-buffer
      (insert (splash-phrase))
      (setq fill-column (min 70 (/ (* 2 (window-width)) 3)))
      (fill-region (point-min) (point-max))
      (buffer-string))
    "\n")
   "\n"))

(defun splash-phrase-dashboard-insert ()
  "Insert the splash phrase surrounded by newlines."
  (insert "\n" (splash-phrase-dashboard-formatted) "\n"))

(defun +doom-dashboard-setup-modified-keymap ()
  (setq +doom-dashboard-mode-map (make-sparse-keymap))
  (map! :map +doom-dashboard-mode-map
        :desc "Find file" :ng "f" #'find-file
        :desc "Recent files" :ng "r" #'consult-recent-file
        :desc "Config dir" :ng "C" #'doom/open-private-config
        :desc "Open config.org" :ng "c" (cmd! (find-file (expand-file-name "config.org" doom-user-dir)))
        :desc "Open org-mode root" :ng "O" (cmd! (find-file (expand-file-name "lisp/org/" doom-user-dir)))
        :desc "Open dotfile" :ng "." (cmd! (doom-project-find-file "~/.config/"))
        :desc "Notes (roam)" :ng "n" #'org-roam-node-find
        :desc "Switch buffer" :ng "b" #'+vertico/switch-workspace-buffer
        :desc "Switch buffers (all)" :ng "B" #'consult-buffer
        :desc "IBuffer" :ng "i" #'ibuffer
        :desc "Previous buffer" :ng "p" #'previous-buffer
        :desc "Set theme" :ng "t" #'consult-theme
        :desc "Quit" :ng "Q" #'save-buffers-kill-terminal
        :desc "Show keybindings" :ng "h" (cmd! (which-key-show-keymap '+doom-dashboard-mode-map))))

(add-transient-hook! #'+doom-dashboard-mode (+doom-dashboard-setup-modified-keymap))
(add-transient-hook! #'+doom-dashboard-mode :append (+doom-dashboard-setup-modified-keymap))
(add-hook! 'doom-init-ui-hook :append (+doom-dashboard-setup-modified-keymap))

(map! :leader :desc "Dashboard" "d" #'+doom-dashboard/open)

(defun +doom-dashboard-benchmark-line ()
  "Insert the load time line."
  (when doom-init-time
    (insert
     "\n\n"
     (propertize
      (+doom-dashboard--center
       +doom-dashboard--width
       (doom-display-benchmark-h 'return))
      'face 'doom-dashboard-loaded))))

(remove-hook 'doom-after-init-hook #'doom-display-benchmark-h)

(setq +doom-dashboard-functions
      (list #'doom-dashboard-widget-banner
            #'+doom-dashboard-benchmark-line
            #'splash-phrase-dashboard-insert))

(add-hook 'window-size-change-functions #'fancy-splash-apply-appropriate-image)
(add-hook 'doom-load-theme-hook #'fancy-splash-apply-appropriate-image)

(after! company
  (setq company-idle-delay 0.2
        company-minimum-prefix-length 1))

(after! lsp-mode
  (setq lsp-file-watch-threshold 1500))

(map! "C-'" #'avy-goto-char-timer)

(after! avy
  (setq avy-timeout-seconds 0.3))

(use-package! comment-dwim-2
  :bind ([remap comment-dwim] . comment-dwim-2)
  :config (setq cd2/region-command 'cd2/comment-or-uncomment-region))

(setq org-directory "~/Documents/Org/")

(defvar org-agenda-files nil)
(add-to-list 'org-agenda-files org-directory)

(after! org
(setq org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "WAITING(w)" "ONHOLD(h)" "|" "DONE(d)")
                          (sequence "EMAIL(e)" "|" "SENT(s)")
                          (sequence "|" "CANCELLED(c)")
                          (sequence "|" "MOVED(m)")))

(setq org-enforce-todo-dependencies t)
(setq org-return-follows-link t)
(setq org-highlight-latex-and-related '(native script entities))
(setq org-startup-with-latex-preview nil
      org-startup-with-inline-images nil)

(map! :map org-mode-map "C-'" nil)

(map! :map evil-org-mode-map
      :n "zf" #'org-toggle-latex-fragment)
  )

(defun tq/org-exit-link-forward ()
  "Jump just outside a link forward"
  (interactive)
  (when (org-in-regexp org-link-any-re)
    (goto-char (match-end 0))
    (insert " ")))

(defun tq/org-exit-link-backward ()
  "Jump just outside a link backward"
  (interactive)
  (when (org-in-regexp org-link-any-re)
    (goto-char (match-beginning 0))
    (save-excursion (insert " "))))

(map! :map (evil-org-mode-map org-mode-map)
      :ni "C-k" #'tq/org-exit-link-forward
      :ni "C-j" #'tq/org-exit-link-backward)

(after! org-archive
  (setq org-archive-location "archive/%s_archive::datetree/"))

(after! org-clock
  (setq org-clock-out-remove-zero-time-clocks t))

(map! :leader "j" #'org-capture)

(defadvice! tq/setup-capture-templates ()
  :after #'+org-init-capture-defaults-h
  (setq org-default-notes-file (expand-file-name "inbox.org" org-directory))

  (setq org-capture-templates
        `(("t" "todo" entry (file org-default-notes-file)
           "* TODO %?")
          ("a" "appointment" entry (file org-default-notes-file)
           "* %?")
          ("j" "journal" plain (file+olp+datetree ,(concat org-directory "journal.org"))
           (file ,(concat org-directory "templates/journal.org"))
           :immediate-finish t :jump-to-captured t :tree-type 'week)
          ("w" "workout" plain
           (file+olp+datetree ,(concat org-directory "exercise.org") "Workouts")
           (file ,(concat org-directory "templates/workout.org"))
           :immediate-finish t :jump-to-captured t :tree-type 'week))))

(setq org-roam-directory (concat (file-name-as-directory org-directory) "Notes/"))

(setq org-roam-db-location (concat doom-cache-dir "org-roam.db"))

(setq org-roam-verbose nil)

(setq org-roam-tag-sources '(prop all-directories))

(setq org-roam-tag-sources '(prop all-directories))

(setq org-roam-dailies-capture-templates
      '(("d" "default" entry "* %?"
         :if-new (file+head
                  "%<%Y-%m-%d>.org"
                  "#+title: %<%Y-%m-%d>\n")
         :unnarrowed t
         :immediate-finish t
         :jump-to-captured t)))

(setq org-roam-db-update-method 'immediate)

(defun tq/org-agenda-nearby-notes (&optional distance)
  (interactive "P")
  (let ((org-agenda-files (org-roam-db--links-with-max-distance
                           buffer-file-name (or distance 3)))
        (org-agenda-custom-commands '(("e" "" ((alltodo ""))))))
    (org-agenda nil "e")))

(map! :leader :prefix "n" :desc "Agenda nearby" "a" #'tq/org-agenda-nearby-notes)

(add-hook! 'org-roam-file-setup-hook
  (setq-local completion-ignore-case t))

(add-hook! 'after-save-hook
           (defun org-rename-to-new-title ()
             (when-let*
                 ((old-file (buffer-file-name))
                  (is-roam-file (org-roam-file-p old-file))
                  (in-roam-base-directory? (string-equal
                                            (expand-file-name org-roam-directory)
                                            (file-name-directory old-file)))
                  (file-node (save-excursion
                               (goto-char 1)
                               (org-roam-node-at-point)))
                  (slug (org-roam-node-slug file-node))
                  (new-file (expand-file-name (concat slug ".org")))
                  (different-name? (not (string-equal old-file new-file))))
               (rename-buffer new-file)
               (rename-file old-file new-file)
               (set-visited-file-name new-file)
               (set-buffer-modified-p nil))))

(use-package org-roam-ui
  :after org-roam
  :hook (after-init . org-roam-ui-mode))

(after! python
  (setq! lsp-pylsp-plugins-pydocstyle-ignore t))

(setq gofmt-command "goimports")
(add-hook 'before-save-hook 'gofmt-before-save)
