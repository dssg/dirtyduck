(require 'ox-publish)
(setq org-publish-project-alist
      '(

        ("dirtyduck-notes"
         :base-directory "~/projects/dsapp/dirtyduck/src/"
         :base-extension "org"
         :exclude "\d\d_.*\.org"
         :publishing-directory "~/projects/dsapp/dirtyduck/docs2/"
         :recursive t
         :publishing-function org-html-publish-to-html
         :headline-levels 4             ; Just the default for this project.
         :auto-preamble t
         :sitemap-title "Dirtyduck"
         )

        ("dirtyduck-static"
         :base-directory "~/projects/dsapp/dirtyduck/src/"
         :base-extension "css\\|js\\|png\\|jpg\\|gif\\|pdf\\|mp3\\|ogg\\|swf\\|sql"
         :publishing-directory "~/projects/dsapp/dirtyduck/docs2/"
         :recursive t
         :publishing-function org-publish-attachment
         )

        ("dirtyduck" :components ("dirtyduck-static" "dirtyduck-notes"))

        ))
