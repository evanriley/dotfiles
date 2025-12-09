(setq user-full-name "Evan Riley"
      user-real-login-name "Evan Riley"
      user-login-name "evan"
      user-mail-address (rot13 "rina@rinaevyrl.pbz"))

(setq auth-sources '("~/.authinfo.gpg")
      auth-source-cache-expiry nil)

(setq-default custom-file (expand-file-name ".custom.el" doom-private-dir))
(when (file-exists-p custom-file)
  (load custom-file))

;; Performance
(setq gcmh-idle-delay 10
      gcmh-high-cons-threshold (* 512 1024 1024)) ; 512MB idle GC
(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)
(setq inhibit-compacting-font-caches t)

;; Behavior
(setq-default
 delete-by-moving-to-trash t
 window-combination-resize t
 x-stretch-cursor t)

(setq undo-limit 80000000
      evil-want-fine-undo t
      auto-save-default t
      create-lockfiles nil
      display-time-default-load-average nil)

(display-time-mode 1)
(global-subword-mode 1)

(setq doom-theme 'doom-earl-grey)

(setq doom-font (font-spec :family "Berkeley Mono" :size 14)
      doom-big-font (font-spec :family "Berkeley Mono" :size 24)
      doom-variable-pitch-font (font-spec :family "Overpass" :size 24)
      doom-symbol-font (font-spec :family "JuliaMono" :size 14)
      doom-emoji-font (font-spec :family "Twitter Color Emoji")
      doom-serif-font (font-spec :family "IBM Plex Mono" :size 22 :weight 'light))

(defun modeline-contitional-buffer-encoding ()
  "Hide \"LF UTF-8\" in modeline."
  (setq-local doom-modeline-buffer-encoding
              (unless (and (memq (plist-get (coding-system-plist buffer-file-coding-system) :category)
                                 '(coding-category-undecided coding-category-utf-8))
                           (not (memq (coding-system-eol-type buffer-file-coding-system) '(1 2))))
                t)))
(add-hook 'after-change-major-mode-hook #'modeline-contitional-buffer-encoding)

(setq doom-modeline-enable-word-count nil
      doom-modeline-continuous-word-count-modes nil
      doom-modeline-checker-simple-format t)

(setq frame-title-format
      '(""
        (:eval
         (if (string-match-p (regexp-quote (or (bound-and-true-p org-roam-directory) "\u0000"))
                             (or buffer-file-name ""))
             (replace-regexp-in-string
              ".*/[0-9]*-?" "☰ "
              (subst-char-in-string ?_ ?\s buffer-file-name))
           "%b"))
        (:eval
         (when-let ((project-name (and (featurep 'projectile) (projectile-project-name))))
           (unless (string= "-" project-name)
             (format (if (buffer-modified-p)  " ◉ %s" "  ●  %s") project-name))))))

(use-package! ultra-scroll
  :init
  (setq scroll-conservatively 101
        scroll-margin 0)
  :config
  (ultra-scroll-mode 1))

(setq visible-bell t)

(add-hook 'before-save-hook #'whitespace-cleanup)
(setq-default sentence-end-double-space nil)
(setq-default indent-tabs-mode nil)
(add-hook 'prog-mode-hook (lambda () (setq indent-tabs-mode nil)))

;; Line numbers
(setq display-line-numbers 'relative)
(setq display-line-numbers-type 'visual)

;; Fill column
(setq display-fill-column-indicator-column 80)
(add-hook 'prog-mode-hook #'display-fill-column-indicator-mode)

;; Ensure proper indentation with TAB in insert mode
(map! :i [tab] #'indent-for-tab-command
      :i "TAB" #'indent-for-tab-command)

;; Ensure Org-cycle works in Org mode
(map! :after org
      :map org-mode-map
      :n [tab] #'org-cycle
      :n "TAB" #'org-cycle)

;; Prevent minibuffer completion hijacking
(after! corfu
  (setq corfu-auto t
        corfu-auto-delay 0.2
        corfu-auto-prefix 2)
  (global-corfu-mode))

(after! magit
  (setq magit-revision-show-gravatars '("^Author:     " . "^Commit:     ")))

;; Better diffs with Delta
(use-package! magit-delta
  :after magit
  :config
  (magit-delta-mode +1))

(after! zig-mode
  (setq zig-format-on-save t))

(after! cider
  (setq cider-repl-display-help-banner nil
        cider-repl-pop-to-buffer-on-connect 'display-only))

(after! projectile
  (setq projectile-enable-caching t)
  (setq projectile-indexing-method 'alien)
  (setq projectile-files-cache-expire 604800)
  (setq projectile-project-search-path '("~/Code/Personal/" "~/Code/Work/")
        projectile-auto-discover t))

(after! lsp-mode
  (setq lsp-idle-delay 0.5)
  (setq lsp-file-watch-threshold 2000))

(add-hook! 'mu4e-view-mode-hook #'visual-line-mode)
(add-hook! 'mu4e-compose-mode-hook #'visual-line-mode)

;; Org-Msg for rich email composition
(after! org-msg
  (setq org-msg-options "html-postamble:nil H:5 num:nil ^:{} toc:nil author:nil email:nil \\n:t"
        org-msg-startup "hidestars indent inlineimages"
        org-msg-greeting-fmt "\nHi *%s*,\n\n"
        org-msg-greeting-name-limit 3
        org-msg-convert-citation t))

;; Prefer plain text over HTML in mu4e (Gnus-based viewer in mu4e 1.8+)
(with-eval-after-load 'mm-decode
  (add-to-list 'mm-discouraged-alternatives "text/html")
  (add-to-list 'mm-discouraged-alternatives "text/richtext"))

(after! mu4e
  (setq mu4e-maildir "~/.local/share/mail/"
        mu4e-get-mail-command "mbsync -a"
        mu4e-update-interval 300
        mu4e-index-update-in-background t
        mu4e-change-filenames-when-moving t
        mu4e-headers-date-format "%Y-%m-%d %H:%M"
        mu4e-headers-fields '((:date . 20)
                              (:flags . 6)
                              (:from . 22)
                              (:subject))
        mu4e-context-policy 'pick-first
        mu4e-compose-context-policy 'always-ask
        mu4e-view-prefer-html nil
        mu4e-view-html-plaintext-ratio-heuristic most-positive-fixnum)

  ;; Toggle HTML view with H
  (map! :map mu4e-view-mode-map
        "H" #'mu4e-view-toggle-html)

  (setq mu4e-bookmarks
      `((:name "Inbox"
         :query ,(format "maildir:/%s/INBOX" user-mail-address)
         :key ?i)
        (:name "Archive"
         :query ,(format "maildir:/%s/Archive" user-mail-address)
         :key ?a)
        (:name "Spam"
         :query ,(format "maildir:/%s/INBOX.spam" user-mail-address)
         :key ?s)
        (:name "Unread messages"
         :query "flag:unread AND NOT flag:trashed"
         :key ?u)
        (:name "Today's messages"
         :query "date:today..now"
         :key ?t)
        (:name "Last 7 days"
         :query "date:7d..now"
         :key ?w)
        (:name "With images"
         :query "mime:image/*"
         :key ?p)
        (:name "Flagged"
         :query "flag:flagged"
         :key ?f))))

(set-email-account! user-mail-address
  `((mu4e-sent-folder       . ,(format "/%s/Sent" user-mail-address))
    (mu4e-drafts-folder     . ,(format "/%s/Drafts" user-mail-address))
    (mu4e-trash-folder      . ,(format "/%s/Trash" user-mail-address))
    (mu4e-refile-folder     . ,(format "/%s/Archive" user-mail-address))
    (user-mail-address      . ,user-mail-address)
    (user-full-name         . "Evan Riley"))
  t)

(setq sendmail-program (executable-find "msmtp")
      send-mail-function #'sendmail-send-it
      message-sendmail-f-is-evil t
      message-sendmail-extra-arguments '("--read-envelope-from")
      message-send-mail-function #'message-send-mail-with-sendmail)

(setq epg-pinentry-mode 'loopback)

(if (string= (daemonp) "server")
    (setenv "INSIDE_EMACS" "true"))

(after! elfeed
  (setq elfeed-search-filter "@1-week-ago +unread"
        elfeed-search-title-max-width 100
        elfeed-search-title-min-width 30
        elfeed-search-trailing-width 30
        elfeed-show-entry-switch #'pop-to-buffer
        elfeed-db-directory (concat doom-cache-dir "elfeed/"))

  (defun elfeed-mark-all-as-read ()
    "Mark all visible entries as read."
    (interactive)
    (mark-whole-buffer)
    (elfeed-search-untag-all-unread))

  (map! :map elfeed-search-mode-map
        :localleader
        "m" #'elfeed-mark-all-as-read
        "u" #'elfeed-update))

(use-package! elfeed-org
  :after elfeed
  :config
  (setq rmh-elfeed-org-files (list (concat org-directory "feeds.org")))
  (elfeed-org))

(add-hook! 'elfeed-search-mode-hook #'elfeed-update)

(unpin! org)
(use-package! org-contrib)
(use-package! org-roam-ui)
(use-package! org-modern)
(use-package! org-appear)
(use-package! org-ol-tree
  :commands org-ol-tree)

(setq org-directory "~/cloud/org/")
(setq org-agenda-files (list org-directory))
(add-hook! 'org-mode-hook #'visual-line-mode)

(after! org
  (setq org-todo-keywords '((sequence "TODO(t)" "NEXT(n)" "WAITING(w)" "ONHOLD(h)" "|" "DONE(d)")
                            (sequence "EMAIL(e)" "|" "SENT(s)")
                            (sequence "|" "CANCELLED(c)")
                            (sequence "|" "MOVED(m)")))
  (setq org-log-done 'time
        org-list-allow-alphabetical t
        org-catch-invisible-edits t
        org-enforce-todo-dependencies t
        org-return-follows-link t
        org-fontify-quote-and-verse-blocks nil
        org-fontify-whole-heading-line nil
        org-highlight-latex-and-related '(native script entities)
        org-startup-with-latex-preview nil
        org-startup-with-inline-images nil))

(use-package! org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-star '("◉" "○" "✸" "✿" "✤" "✜" "◆" "▶")
        org-modern-table-vertical 1
        org-modern-table-horizontal 0.2
        org-modern-list '((43 . "➤") (45 . "–") (42 . "•"))
        org-modern-todo-faces
        '(("TODO" :inverse-video t :inherit org-todo)
          ("PROJ" :inverse-video t :inherit +org-todo-project)
          ("STRT" :inverse-video t :inherit +org-todo-active)
          ("WAIT" :inverse-video t :inherit +org-todo-onhold)
          ("DONE" :inverse-video t :inherit org-done))
        org-modern-block-fringe nil))

(use-package! org-appear
  :hook (org-mode . org-appear-mode)
  :config
  (setq org-appear-autoemphasis t
        org-appear-autosubmarkers t))

(custom-set-faces!
  '(outline-1 :weight extra-bold :height 1.25)
  '(outline-2 :weight bold :height 1.15)
  '(outline-3 :weight bold :height 1.12)
  '(org-document-title :height 1.2))

(use-package! org-super-agenda
  :commands org-super-agenda-mode)

(after! org-agenda
  (org-super-agenda-mode)
  (setq org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-include-deadlines t
        org-agenda-block-separator nil
        org-agenda-tags-column 100
        org-agenda-compact-blocks t))

;; Custom Commands
(setq org-agenda-custom-commands
      '(("o" "Overview"
         ((agenda "" ((org-agenda-span 'day)
                      (org-super-agenda-groups
                       '((:name "Today" :time-grid t :date today :todo "TODAY" :scheduled today :order 1)))))
          (alltodo "" ((org-agenda-overriding-header "")
                       (org-super-agenda-groups
                        '((:name "Next to do" :todo "NEXT" :order 1)
                          (:name "Important" :tag "Important" :priority "A" :order 6)
                          (:name "Due Today" :deadline today :order 2)
                          (:name "Due Soon" :deadline future :order 8)
                          (:name "Overdue" :deadline past :face error :order 7)
                          (:name "Projects" :tag "Project" :order 14)
                          (:name "Waiting" :todo "WAITING" :order 20)
                          (:discard (:tag ("Chore" "Routine" "Daily")))))))))))

(use-package! doct :commands doct)

(after! org-capture
  (defvar +org-capture-todo-file (concat org-directory "todo.org"))
  (defvar +org-capture-notes-file (concat org-directory "notes.org"))

  (setq org-capture-templates
        (doct `(("Personal todo" :keys "t"
                 :icon ("nf-oct-checklist" :set "octicon" :color "green")
                 :file +org-capture-todo-file
                 :prepend t
                 :headline "Inbox"
                 :type entry
                 :template ("* TODO %?" "%i %a"))
                ("Personal note" :keys "n"
                 :icon ("nf-fa-sticky_note_o" :set "faicon" :color "green")
                 :file +org-capture-notes-file
                 :prepend t
                 :headline "Inbox"
                 :type entry
                 :template ("* %?" "%i %a"))
                ("Email" :keys "e"
                 :icon ("nf-fa-envelope" :set "faicon" :color "blue")
                 :file +org-capture-todo-file
                 :prepend t
                 :headline "Inbox"
                 :type entry
                 :template ("* TODO %^{type|reply to|contact} %\\3 %? :email:"
                            "Send an email to %^{recipiant}"
                            "%U %i %a"))))))

(setq org-roam-directory (concat (file-name-as-directory org-directory) "Notes/"))
(setq org-roam-db-location (concat doom-cache-dir "org-roam.db"))
(setq org-roam-db-update-method 'immediate)

(use-package org-roam-ui
  :after org-roam
  :config
  (setq org-roam-ui-sync-theme t
        org-roam-ui-follow t
        org-roam-ui-update-on-save t
        org-roam-ui-open-on-start nil))

(setq org-roam-dailies-capture-templates
      '(("d" "default" entry "* %?"
         :if-new (file+head
                  "%<%Y-%m-%d>.org"
                  "#+title: %<%Y-%m-%d>\n")
         :unnarrowed t
         :immediate-finish t
         :jump-to-captured t)))

(after! org-roam
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?"
           :target (file+head "%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags:\n\n")
           :unnarrowed t)
          ("r" "reference" plain "%?"
           :target (file+head "references/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :reference:\n\n* Source\n\n* Notes\n")
           :unnarrowed t)
          ("p" "project" plain "%?"
           :target (file+head "projects/%<%Y%m%d%H%M%S>-${slug}.org"
                              "#+title: ${title}\n#+date: %U\n#+filetags: :project:\n\n* Goals\n\n* Tasks\n\n* Notes\n")
           :unnarrowed t))))

(after! org
  (add-to-list 'org-modules 'org-habit t)
  (setq org-habit-show-habits t
        org-habit-show-habits-only-for-today t
        org-habit-graph-column 60
        org-habit-preceding-days 21
        org-habit-following-days 7))

(after! citar
  (setq citar-bibliography (list (concat org-directory "references.bib"))
        citar-notes-paths (list (concat org-roam-directory "references/"))
        citar-library-paths (list "~/Documents/papers/")
        org-cite-global-bibliography citar-bibliography
        org-cite-insert-processor 'citar
        org-cite-follow-processor 'citar
        org-cite-activate-processor 'citar))

(after! org
  (setq org-export-headline-levels 5
        org-export-with-toc t
        org-export-with-section-numbers nil
        org-export-with-smart-quotes t))

(after! ox-html
  (setq org-html-validation-link nil
        org-html-head-include-scripts nil
        org-html-head-include-default-style nil
        org-html-doctype "html5"
        org-html-html5-fancy t))

(after! org-journal
  (setq org-journal-dir (concat org-directory "journal/")
        org-journal-date-prefix "#+title: "
        org-journal-time-prefix "* "
        org-journal-date-format "%Y-%m-%d %A"
        org-journal-file-format "%Y-%m-%d.org"
        org-journal-enable-agenda-integration t))

(map! :leader
      :prefix ("j" . "journal")
      "j" #'org-journal-new-entry
      "s" #'org-journal-search)

(after! writeroom-mode
  (setq writeroom-width 100
        writeroom-mode-line t
        writeroom-global-effects '(writeroom-set-fullscreen
                                   writeroom-set-alpha
                                   writeroom-set-menu-bar-lines
                                   writeroom-set-tool-bar-lines
                                   writeroom-set-vertical-scroll-bars
                                   writeroom-set-bottom-divider-width)))

(after! dirvish
  (setq dirvish-quick-access-entries
        '(("h" "~/"                          "Home")
          ("d" "~/Downloads/"                "Downloads")
          ("c" "~/Code/"                     "Code")
          ("o" "~/cloud/org/"                "Org")
          ("p" "~/Pictures/"                 "Pictures")
          ("t" "/tmp/"                       "Temp")))
  (dirvish-override-dired-mode))

(after! dired
  (setq dired-dwim-target t
        dired-recursive-copies 'always
        dired-recursive-deletes 'always
        delete-by-moving-to-trash t))

(after! pdf-view
  (setq pdf-view-display-size 'fit-page
        pdf-view-resize-factor 1.1
        pdf-annot-activate-created-annotations t)
  (add-hook! 'pdf-view-mode-hook #'pdf-view-midnight-minor-mode))

(use-package! ebib
  :commands ebib
  :config
  (setq ebib-preload-bib-files (list (concat org-directory "references.bib"))
        ebib-notes-directory (concat org-roam-directory "references/")
        ebib-file-associations '(("pdf" . "xdg-open"))
        ebib-index-columns '(("Entry Key" 20 t)
                            ("Author/Editor" 40 t)
                            ("Year" 6 t)
                            ("Title" 60 t))
        ebib-reading-list-file (concat org-directory "reading-list.org")))

(after! consult
  (setq consult-narrow-key "<"
        consult-preview-key "M-."))

(map! :leader
      "s g" #'consult-ripgrep
      "s l" #'consult-line
      "s o" #'consult-outline
      "s i" #'consult-imenu)

(use-package! gptel
  :commands gptel gptel-send gptel-menu
  :config
  (setq gptel-model 'claude-sonnet-4-20250514
        gptel-backend (gptel-make-anthropic "Claude"
                        :stream t
                        :key #'gptel-api-key-from-auth-source))
  (setq gptel-default-mode 'org-mode))

(map! :leader
      :prefix ("l" . "LLM")
      "l" #'gptel
      "s" #'gptel-send
      "m" #'gptel-menu)

(use-package! org-pomodoro
  :commands org-pomodoro
  :config
  (setq org-pomodoro-length 25
        org-pomodoro-short-break-length 5
        org-pomodoro-long-break-length 20
        org-pomodoro-long-break-frequency 4
        org-pomodoro-play-sounds t
        org-pomodoro-keep-killed-pomodoro-time t))

(map! :after org-agenda
      :map org-agenda-mode-map
      "P" #'org-pomodoro)

(defun my-doom-dashboard-draw-ascii-banner-fn ()
  (let* ((banner '("███████╗███╗   ███╗ █████╗  ██████╗███████╗"
                   "██╔════╝████╗ ████║██╔══██╗██╔════╝██╔════╝"
                   "█████╗  ██╔████╔██║███████║██║     ███████╗"
                   "██╔══╝  ██║╚██╔╝██║██╔══██║██║     ╚════██║"
                   "███████╗██║ ╚═╝ ██║██║  ██║╚██████╗███████║"
                   "╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝ ╚═════╝╚══════╝"))
         (longest-line (apply #'max (mapcar #'length banner))))
    (put-text-property
     (point)
     (dolist (line banner (point))
       (insert (+doom-dashboard--center
                +doom-dashboard--width
                (concat line
                        (make-string (max 0 (- longest-line (length line))) ?\s)))
               "\n"))
     'face 'doom-dashboard-banner)))

(setq +doom-dashboard-ascii-banner-fn #'my-doom-dashboard-draw-ascii-banner-fn)

(map! :leader
      :desc "Elfeed" "o e" #'elfeed)

(setq +doom-dashboard-menu-sections
      '(("Open org-agenda"
         :icon (nerd-icons-octicon "nf-oct-calendar" :face 'doom-dashboard-menu-title)
         :when (fboundp 'org-agenda)
         :face (:inherit (doom-dashboard-menu-title bold))
         :key "SPC o A"
         :action org-agenda)
        ("Open elfeed"
         :icon (nerd-icons-faicon "nf-fa-rss" :face 'doom-dashboard-menu-title)
         :when (fboundp 'elfeed)
         :face (:inherit (doom-dashboard-menu-title bold))
         :key "SPC o e"
         :action elfeed)
        ("Open mu4e"
         :icon (nerd-icons-mdicon "nf-md-email" :face 'doom-dashboard-menu-title)
         :when (fboundp 'mu4e)
         :face (:inherit (doom-dashboard-menu-title bold))
         :key "SPC o m"
         :action mu4e)
        ("Recently opened files"
         :icon (nerd-icons-faicon "nf-fa-file_text" :face 'doom-dashboard-menu-title)
         :face (:inherit (doom-dashboard-menu-title bold))
         :key "SPC f r"
         :action recentf-open-files)
        ("Open project"
         :icon (nerd-icons-octicon "nf-oct-briefcase" :face 'doom-dashboard-menu-title)
         :face (:inherit (doom-dashboard-menu-title bold))
         :key "SPC p p"
         :action projectile-switch-project)
        ("Open private configuration"
         :icon (nerd-icons-octicon "nf-oct-gear" :face 'doom-dashboard-menu-title)
         :when (file-directory-p doom-private-dir)
         :face (:inherit (doom-dashboard-menu-title bold))
         :key "SPC f p"
         :action doom/open-private-config)))
