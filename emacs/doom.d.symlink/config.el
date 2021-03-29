;; My user information
(setq user-full-name "Evan Riley"
      user-mail-address "evanriley@hey.com")
;; Change the Mac Modifiers to be better
(cond (IS-MAC
         (setq mac-command-modifier      'meta
               mac-option-modifier       'alt
               mac-right-option-modifier 'alt)))

;; Enable auto-save and backup files
(setq auto-save-default t
      make-backup-files t)

;; Set a nice looking splash image
;;(setq fancy-splash-image (concat doom-private-dir "misc/splash-images/doom-emacs-color.png"))
;; Simple ascii emacs banner
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
      'face 'doom-dashboard-banner))

 (setq +doom-dashboard-ascii-banner-fn #'doom-dashboard-draw-ascii-emacs-banner-fn))

;; Set fonts
(setq
 doom-font (font-spec :family "JetBrains Mono" :size 16)
 doom-big-font (font-spec :family "JetBrains Mono" :size 36)
 doom-variable-pitch-font (font-spec :fammily "Overpass" :size 16)
 doom-serif-font (font-spec :family "IBM Plex Mono" :weight 'light))

;; Set theme
;;(setq doom-theme 'doom-wilmersdorf)
(setq doom-theme 'doom-city-lights)
;;(setq doom-theme 'doom-acario-light)
;;(setq doom-theme 'doom-tomorrow-day)
;;(setq doom-theme 'doom-opera-light)
;;(setq doom-theme 'doom-ayu-light)
;;(setq doom-theme 'doom-horizon)
;;(setq doom-theme 'doom-ayu-dark)

;; Modeline Settings
(defun doom-modeline-conditional-buffer-encoding ()
  (setq-local doom-modeline-buffer-encoding
        (unless (and (memq (plist-get (coding-system-plist buffer-file-coding-system) :category)
                           '(coding-category-undecided coding-category-utf-8))
                     (not (memq (coding-system-eol-type buffer-file-coding-system) '(1 2))))
          t)))

(add-hook 'after-change-major-mode-hook #'doom-modeline-conditional-buffer-encoding)

;; Relative line numbers
(setq display-line-numbers-type 'relative)

;; Buffer names
(setq doom-fallback-buffer-name "► Doom"
      +doom-dashboard-name "► Doom")

;; Window title
(setq frame-title-format
      '(""
        (:eval
         (if (s-contains-p org-roam-directory (or buffer-file-name ""))
             (replace-regexp-in-string
              ".*/[0-9]*-?" "☰ "
              (subst-char-in-string ?_ ? buffer-file-name))
           "%b"))
        (:eval
         (let ((project-name (projectile-project-name)))
           (unless (string= "-" project-name)
             (format (if (buffer-modified-p) " ◉ %s" "  ●  %s") project-name))))))

;; Simple Settings/Better Defaults
(setq-default
 delete-by-moving-to-trash t
 window-combination-resize t
 x-stretch-cursor t)

(setq password-cache-expiry nil)

(setq undo-limit 8000000
      evil-want-fine-undo t)

(display-time-mode 1)
(global-subword-mode 1)

;; Ask which buffer I want to see after splitting window.
(setq evil-vsplit-window-right t
      evil-split-window-below t)

(defadvice! prompt-for-buffer (&rest)
  :after '(evil-window-split evil-window-vsplit)
  (+ivy/switch-buffer))

(setq +ivy-buffer-preview

;; Use SPC w for window rotation
 (map! :map evil-window-map
      "SPC" #'rotate-layout
      ;; Navigation
      "<left>"     #'evil-window-left
      "<down>"     #'evil-window-down
      "<up>"       #'evil-window-up
      "<right>"    #'evil-window-right
      ;; Swapping windows
      "C-<left>"       #'+evil/window-move-left
      "C-<down>"       #'+evil/window-move-down
      "C-<up>"         #'+evil/window-move-up
      "C-<right>"      #'+evil/window-move-right))

;; Default Directories for Org and Org-Roam
(setq
 org-directory "~/Code/org/"
 org-roam-directory "~/Code/org/notes")

;; Hide Org Markup Indicators
(after! org (setq org-hide-emphasis-markers t))

;; Insert Org Headings At Point.
(after! org (setq org-insert-heading-respect-content nil))

;; Nested YASnippet
(setq yas-triggers-in-field t)

;; Magit Settings
(setq +magit-hub-features t)
