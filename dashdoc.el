;;; dashdoc.el --- Search DashDoc                    -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Xu Chunyang

;; Author: Xu Chunyang <mail@xuchunyang.me>
;; Homepage: https://github.com/xuchunyang/DashDoc
;; Package-Requires: ((emacs "25.1"))
;; Version: 0.1

;; This program is free software; you can redistribute it and/or modify
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

;; Search DashDoc within Emacs by taking advantage of Dash Alfred Workflow.

;;; Code:

(require 'dom)                          ; Emacs 25.1
(eval-when-compile (require 'cl-lib))   ; `cl-loop'

(declare-function libxml-parse-xml-region "xml.c"
		  (start end &optional base-url discard-comments))

(defvar dashdoc-dashAlfredWorkflow-executable
  (let ((workflow-dir
         "~/Library/Application Support/Alfred 3/Alfred.alfredpreferences/workflows/"))
    (and (file-exists-p workflow-dir)
         (locate-file "dashAlfredWorkflow" (directory-files workflow-dir t))))
  "The dashAlfredWorkflow executable.")


;;; Ivy

(declare-function ivy-more-chars "ivy" ())
(declare-function ivy-read "ivy")

(defvar dashdoc-subtitle-face 'font-lock-comment-face
  "Face name to use for substitute.")

(defun dashdoc-ivy-function (str)
  (or
   (ivy-more-chars)
   (with-temp-buffer
     (when (zerop (call-process dashdoc-dashAlfredWorkflow-executable nil t nil str))
       (let* ((dom (libxml-parse-xml-region (point-min) (point-max)))
              (items (dom-by-tag dom 'item)))
         (cl-loop for item in items
                  collect (let ((arg (dom-attr item 'arg))
                                title
                                subtitle
                                quicklookurl)
                            (dolist (x (dom-children item))
                              (pcase x
                                (`(title ,_ ,s) (setq title s))
                                (`(subtitle nil ,s) (setq subtitle s))
                                (`(quicklookurl ,_ ,s) (setq quicklookurl s))))
                            (propertize (concat title " "
                                                (propertize
                                                 subtitle
                                                 'face dashdoc-subtitle-face))
                                        'arg arg
                                        'quicklookurl quicklookurl))))))))

(defun dashdoc-ivy ()
  (ivy-read "Search Dash: " #'dashdoc-ivy-function
            :dynamic-collection t
            :action (lambda (x)
                      (call-process "open" nil nil nil
                                    "-g" (format "dash-workflow-callback://%s"
                                                 (get-text-property 0 'arg x))))
            :caller 'dashdoc-ivy))


;;; User Commands

;;;###autoload
(defun dashdoc ()
  "Search Dash."
  (interactive)
  (dashdoc-ivy))

(provide 'dashdoc)
;;; dashdoc.el ends here
