(package! catppuccin-theme)

(package! ultra-scroll
  :recipe (:host github :repo "jdtsmith/ultra-scroll"))

(unpin! org)
(package! org-contrib
  ;; The `sr.ht' repo has been a bit flaky as of late.
  :recipe (:host github :repo "emacsmirror/org-contrib"
           :files ("lisp/*.el"))
  :pin "351c71397d893d896a47ad7e280607b4d59b84e4")

(package! org-roam-ui)
(package! org-modern)

(package! doct
  :recipe (:host github :repo "progfolio/doct")
  :pin "5cab660dab653ad88c07b0493360252f6ed1d898")

(package! org-super-agenda :pin "51c9da5ce7b791150758984bab469d2222516844")

(package! org-appear :recipe (:host github :repo "awth13/org-appear")
  :pin "81eba5d7a5b74cdb1bad091d85667e836f16b997")

(package! org-ol-tree :recipe (:host github :repo "Townk/org-ol-tree")
  :pin "207c748aa5fea8626be619e8c55bdb1c16118c25")

(package! ob-http :pin "b1428ea2a63bcb510e7382a1bf5fe82b19c104a7")

(package! go-eldoc :disable t)
