;;; org-indicator.el --- Show org deadlines via appindicator -*- mode: emacs-lisp; lexical-binding: t -*-

;; Copyright (C) 2015 Stephen Pegoraro
;; Copyright (C) 2024 gudzpoz

;; Author: gudzpoz <gudzpoz@live.com>
;; Version: 0.1.0
;; Package-Requires: ((org "9.0") (appindicator "0.1.0"))
;; Keywords: org, org-mode
;; URL: https://github.com/gudzpoz/org-indicator

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides functions to display an app indicator icon in your
;; desktop task bar to indicate any deadlines that are due in your agenda.
;;
;; Most of the code in this package is modified from org-alert.el, which is
;; licensed under GNU General Public License.


;;; Code:

(require 'cl-lib)
(require 'appindicator)
(require 'org-agenda)

(defgroup org-indicator nil
  "Org deadline task bar indicator."
  :group 'org-agenda)

(defcustom org-indicator-interval 300
  "Interval in seconds to recheck and display deadlines."
  :group 'org-indicator
  :type 'integer)

(defcustom org-indicator-match-string
  "SCHEDULED<\"<tomorrow>\"|DEADLINE<\"<tomorrow>\""
  "property/todo/tags match string to be passed to `org-map-entries'."
  :group 'org-indicator
  :type 'regexp)

(defconst org-indicator--icon-svg-template
  "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\" [
  <!ENTITY ns_flows \"http://ns.adobe.com/Flows/1.0/\">
]>
<svg version=\"1.1\"
   xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns:a=\"http://ns.adobe.com/AdobeSVGViewerExtensions/3.0/\"
   x=\"0px\" y=\"0px\" width=\"162px\" height=\"176px\" viewBox=\"-7.65 -13.389 162 176\" enable-background=\"new -7.65 -13.389 162 176\"
   xml:space=\"preserve\">
<path fill=\"#A04D32\" stroke=\"#000000\" stroke-width=\"3\" d=\"M141.044,59.449c-0.205-3.15-2.842-4.366-5.993-2.125
  c-7.219-1.297-14.305-0.687-17.8-0.981c-7.662-1.073-14.041-5.128-14.041-5.128c0.932-1.239,0.486-3.917-5.498-4.101
  c-1.646-0.542-3.336-1.327-4.933-1.979c0.544-1.145-0.133-2.836-0.133-2.836c2.435-0.672,2.808-3.842,1.848-5.709
  c3.106,0.084,2.612-4.718,2.183-6.381c2.435-0.923,2.771-3.831,1.763-6.129c2.938-0.671,3.022-4.114,2.771-6.548
  c3.022-0.168,2.603-5.457,2.603-6.549c2.604-1.679,2.016-3.946,2.425-6.573c1.605-3.25-0.577-4.173-2.116-0.71
  c-1.651,3.001-3.769,4.311-3.75,6.528c0.755,1.259-5.625,3.106-3.61,7.052c-1.428,1.763-4.785,4.03-3.592,6.733
  c-0.606,1.326-4.888,4.433-3.041,7.371c-4.029,2.687-3.789,3.335-2.938,5.793c-1.147,0.736-2.318,1.862-2.995,3.094
  c-1.319-1.568-2.603-4.429-2.584-8.294c0-3.275-6.099,0.318-6.099,6.784c0,0.556-0.057,1.061-0.135,1.542
  c-2.11,0.243-4.751,0.707-8.08,1.494c-0.106,0.073-0.157,0.186-0.182,0.316c-0.131-0.485-0.231-1.001-0.277-1.553
  c-0.582-3.79-4.934-9.56-7.057-2.434c-1.096,2.611-1.74,4.392-2.115,5.789v0c0,0-0.336,0.226-0.957,0.61
  c-2.619,1.622-3.562,6.686-13.075,9.883c-3.211,1.079-7.4,1.945-12.959,2.395C21.107,57.576,2.789,74.117,1.562,89.9
  c-0.283,3.964,0.31,13.737,3.596,22.31c0.002,0.006,0.003,0.014,0.005,0.02c0.015,0.042,0.032,0.081,0.048,0.122
  c0.052,0.134,0.103,0.267,0.156,0.398c0.28,0.718,0.579,1.405,0.895,2.062c1.885,4.028,4.46,7.59,7.934,9.882
  c1.764,1.376,3.342,2.258,4.372,2.762c5.907,9.749,18.442,22.252,42.075,14.859c36.255-10.284,56.263,13.809,58.568,15.5
  c3.399,3.433-8.786-29.835-34.587-44.788c-15.253-8.322-5.678-22.656-4.585-27.718c0,0,12.227,8.557,21.087-4.52
  c8.004,2.062,13.367-1.462,20.251,1.03c4.183,1.833,21.77,0.726,15.234-9.104c4.11-2.683,4.544-1.815,6.6-5.9
  C144.315,61.863,141.808,60.803,141.044,59.449z M70.751,46.15c-0.041,0.018-0.086,0.04-0.125,0.056
  c0.039-0.034,0.075-0.062,0.115-0.102C70.744,46.118,70.748,46.136,70.751,46.15z M57.338,50.673
  c-0.073,0.429-0.143,0.829-0.212,1.216c0.037-0.832,0.085-1.714,0.143-2.646C57.293,49.678,57.319,50.147,57.338,50.673z
   M68.031,44.34c0.746,1.124,1.662,2.179,1.662,2.179S68.818,45.729,68.031,44.34z\"/>
<path fill=\"#77AA99\" stroke=\"#000000\" stroke-width=\"0.5\" d=\"M14.093,117.635c0,0,10.021,36.105,46.549,24.68
  c36.255-10.284,56.263,13.809,58.568,15.5c3.399,3.433-8.786-29.835-34.587-44.788c-15.253-8.322-5.678-22.656-4.585-27.718
  c0,0,12.227,8.557,21.087-4.52c8.004,2.062,13.367-1.462,20.251,1.03c4.183,1.833,21.77,0.726,15.234-9.104
  c4.11-2.683,4.544-1.815,6.6-5.9c1.105-4.952-1.402-6.011-2.166-7.366c-0.205-3.15-2.842-4.366-5.993-2.125
  c-7.219-1.297-14.305-0.687-17.8-0.981c-7.662-1.073-14.041-5.128-14.041-5.128c0.932-1.239,0.486-3.917-5.498-4.101
  c-3.287-1.082-6.752-3.136-9.288-3.162c-2.567,0-2.914-2.537-2.914-2.537c-1.606-0.87-3.924-4.252-3.899-9.438
  c0-3.275-6.099,0.318-6.099,6.784s-5.818,7.758-5.818,7.758s-2.549-2.281-2.855-5.958c-0.582-3.79-4.934-9.56-7.057-2.434
  c-3.226,7.646-3.485,9.43-4.115,13.154c-1.31,7.711-0.345,8.012-0.345,8.012L22.498,82.723L14.093,117.635z\"/>
<path fill=\"#314B49\" stroke=\"#314B49\" stroke-width=\"0.75\" stroke-linecap=\"round\" stroke-linejoin=\"round\" d=\"M91.756,56.215
  c1.548-0.562,0.896-0.415,1.152-0.581c-2.959,0.575-9.635,0.614-14.317-1.133c0.392,0.23,2.568,0.962,2.845,1.128
  c0.218,0.715,0.1,1.438,2.932,2.709c2.559,0.793,5.845,0.461,6.835-0.529C91.312,56.125,91.329,56.744,91.756,56.215z\"/>
<path fill=\"#314B49\" stroke=\"#314B49\" stroke-width=\"0.5\" d=\"M124.124,75.361c-2.829-2.085-4.881-0.264-6.469-0.413
  c0.99-0.645,3.762-2.062,8.245-2.062c2.532,0,3.879,2.196,5.57,2.207c1.141,0.007,4.472-1.71,5.14-2.378
  c-0.969,0.838,0.454,1.755-0.489,3.003c-0.282,0.359-0.837,1.511-2.663,2.051C131.408,78.74,128.047,79.531,124.124,75.361z\"/>
<path fill=\"#314B49\" d=\"M62.577,37.415c0,0-3.355,7.996,0.312,15.329s0.522-6.829,4.688-4.162c3.397,0.385-2.387-3.215-2.033-7.819
  C65.368,37.871,63.774,35.569,62.577,37.415z\"/>
<path fill=\"#314B49\" d=\"M126.981,63.799c0,1.121-1.363,2.03-3.045,2.03c3.573-1.121-0.201-4.653-3.045-2.03
  c0-1.121,1.363-2.03,3.045-2.03S126.981,62.678,126.981,63.799z\"/>
<path fill=\"#314B49\" d=\"M121.814,61.215c3.772-0.231,6.336,0.323,5.536,3.138c0.548-1.126,1.292-2.83-1.046-3.507
  C124.558,60.458,123.005,60.468,121.814,61.215z\"/>
<path fill=\"#A04D32\" stroke=\"#000000\" stroke-width=\"0.5\" d=\"M67.574,82.616c0-3.521-1.509-7.166-7.04-14.583
  c-1.635-2.192-2.62-4.336-3.211-6.275c-1.401-3.295-3.426-8.019-0.613-17.233c0,0,0.621-0.384,0,0
  c-2.619,1.622-3.562,6.686-13.075,9.883c-3.211,1.079-7.4,1.945-12.959,2.395C21.107,57.576,2.789,74.117,1.562,89.9
  c-0.283,3.964,0.31,13.737,3.596,22.31c0.002,0.006,0.003,0.014,0.005,0.02c0.015,0.042,0.032,0.081,0.048,0.122
  c0.052,0.134,0.103,0.267,0.156,0.398c0.28,0.718,0.579,1.405,0.895,2.062c1.885,4.028,4.46,7.59,7.934,9.882
  c3.084,2.404,5.606,3.306,5.606,3.306c-2.588-3.578-3.77-7.562-2.263-12.32c0.651,2.637,1.903,4.162,3.646,4.777
  c-0.615-1.884-0.827-3.549,0-4.651c2.567,6.734,5.353,9.031,8.171,10.686c-2.631-4.914-4.032-10.005-3.771-15.337
  c2.569,6.028,6.596,9.945,10.56,13.954c-3.78-5.966-6.911-12.104-6.977-19.046c1.693,2.778,3.935,4.932,6.6,6.601
  c-1.683-2.709-2.505-5.51-2.263-8.423c4.424,4.945,9.361,6.607,14.332,8.046c-5.197-3.625-9.843-7.537-12.32-12.572
  c2.972,1.464,5.948,1.693,8.926,1.383c-3.706-1.872-5.069-5.252-5.783-9.052c5.177,5.279,10.587,8.827,16.091,11.692
  c-5.456-5.26-9.479-10.65-11.566-16.218c2.1,1.18,4.157,1.736,6.16,1.509c-2.766-3.124-3.465-6.182-4.211-9.241
  c2.637,3.916,4.959,6.022,7.103,7.103c-2.189-4.482-2.034-8.432-0.503-12.068c2.524,1.675,4.902,4.295,6.915,9.303
  c0.731-2.386-0.447-6.364-1.886-10.56c2.175,0.622,4.779,3.351,8.171,9.932c-0.33-3.865-2.139-7.775-4.148-11.692
  C63.813,75.316,68.343,84.519,67.574,82.616z\"/>
<path fill=\"#796958\" stroke=\"#000000\" stroke-width=\"0.5\" d=\"M83.915,43.558c0,0-0.252,7.472,6.717,2.603
  c3.61,0.084,2.015-3.862,2.015-3.862c2.435-0.672,2.808-3.842,1.848-5.709c3.106,0.084,2.612-4.718,2.183-6.381
  c2.435-0.923,2.771-3.831,1.763-6.129c2.938-0.671,3.022-4.114,2.771-6.548c3.022-0.168,2.603-5.457,2.603-6.549
  c2.604-1.679,2.016-3.946,2.425-6.573c1.605-3.25-0.577-4.173-2.116-0.71c-1.651,3.001-3.769,4.311-3.75,6.528
  c0.755,1.259-5.625,3.106-3.61,7.052c-1.428,1.763-4.785,4.03-3.592,6.733c-0.606,1.326-4.888,4.433-3.041,7.371
  c-4.029,2.687-3.789,3.335-2.938,5.793C85.038,38.557,82.784,41.308,83.915,43.558z\"/>
<path fill=\"#FFFFFF\" d=\"M101.739,8.295c0,0-0.735,1.324-0.735,2.133s2.185,0.568,2.927-0.227
  C102.306,10.225,100.966,10.49,101.739,8.295z\"/>
<path fill=\"#FFFFFF\" d=\"M97.478,14.565c0,0-0.812,1.068-0.183,2.316c0.392,0.98,2.807,0.962,3.549,0.167
  C99.219,17.072,96.704,16.761,97.478,14.565z\"/>
<path fill=\"#FFFFFF\" d=\"M94.343,21.02c0,0-0.998,1.346-0.492,2.602c0,0.809,2.838,0.956,3.58,0.161
  C95.806,23.805,93.786,23.294,94.343,21.02z\"/>
<path fill=\"#FFFFFF\" d=\"M91.266,28.182c0,0-1.403,1.542-0.149,2.945c1.438,0.809,3.744,0.049,4.486-0.746
  C93.978,30.403,90.709,30.457,91.266,28.182z\"/>
<path fill=\"#FFFFFF\" d=\"M88.261,33.903c0,0-1.575,1.414-0.02,3.312c1.438,0.809,4.57,0.198,5.312-0.597
  C91.929,36.642,87.564,35.272,88.261,33.903z\"/>
<path fill=\"#FFFFFF\" d=\"M85.114,40.644c0,0-1.403,1.542-0.149,2.945c1.438,0.809,6.036-0.186,6.778-0.981
  C90.118,42.631,84.558,42.919,85.114,40.644z\"/>
<path fill=\"#A04D32\" stroke=\"#000000\" stroke-width=\"0.5\" d=\"M83.997,43.672c-0.45-0.45-0.534-0.896-0.367-1.718
  c0,0,0.369-4.107-16.333-0.158c-1.072,0.74,2.396,4.722,2.396,4.722s0.418,0.215,1.047-0.415c0.253,1.123,0.852,4.081,0.233,4.579
  c1.245-0.771,1.868-1.946,1.676-4.125c2.122,0.461,3.742,1.64,4.692,3.779c0.304-1.4,0.603-2.799-0.384-4.126
  c2.182,0.285,3.88,1.496,5.362,3.124c0.221-0.933,0.354-1.883,0-2.931c1.391,0.473,2.587,1.607,3.71,2.988
  C86.03,49.391,86.24,45.529,83.997,43.672z\"/>
<path opacity=\"0.26\" d=\"M67.975,71.318c0,0,6.761,13.59,17.595,13.991s10.834-2.73,10.834-2.73S80.877,85.627,67.975,71.318z\"/>
<path opacity=\"0.26\" d=\"M71.13,79.012c2.279,3.104,4.856,5.221,7.722,6.382c0,0-7.365,11.108-3.611,20.023
  s13.125,11.053,23.321,21.249c7.942,7.942,17.158,24.961,17.158,24.961s-17.834-14.176-29.42-13.479c0,0-2.687-9.668-10.585-17.566
  C64.471,109.337,59.547,94.707,71.13,79.012z\"/>
<path opacity=\"0.18\" fill=\"#FFFFFF\" d=\"M52.362,51.627c-3.874,2.501-8.419,7.096-24.415,8.083
  C10.898,66.494,0.514,86.395,4.17,100.174c1.348,7.317,3.891,14.18,3.891,14.18c-0.887-5.919-1.383-11.397,1.033-13.599
  c1.435,2.384,2.969,2.468,4.507,2.479c-1.59-2.404-1.788-4.808,0-7.212c1.489,1.525,2.992,1.881,4.507,1.353
  c-2.128-2.449-1.867-4.848,0-7.211c1.388,5.022,4.462,7.453,7.662,9.689c-2.208-4.333-4.166-8.672-2.93-13.07
  c1.323,0.729,2.595,0.644,3.831,0c-1.257-1.576-0.925-3.153,0-4.732c2.947,3.04,6.213,3.724,9.465,4.507
  c-2.661-2.454-5.543-4.527-6.761-9.465c1.501-1.811,3.269-2.685,5.408-2.253c-1.901-1.167-1.65-2.543,0-4.057
  c2.089,1.104,4.195,1.352,6.31,1.127C38.286,70.23,32.669,66.916,52.362,51.627z\"/>
<path opacity=\"0.27\" fill=\"#FFFFFF\" d=\"M78.923,32.771c0.996-0.963,1.146-0.65,0.854,0.285c-0.982,2.36,0.353,4.647,0.797,6.206
  l-3.871,0.114C76.811,37.105,76.95,34.582,78.923,32.771z\"/>
%s
</svg>"
  "The Org-Mode unicorn icon. This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. You should have received a copy of the GNU General Public License along with this program. If not, see <https://www.gnu.org/licenses/>.")

(defun org-indicator--make-icon (count)
  "Put red dots on the svg template.

It is hard to center text over the red dots. So instead, we show
a red cylinder and indicate the number of deadlines with the
height of the cylinder."
  (format
   org-indicator--icon-svg-template
   (if (= count 0)
       "<circle r=\"40\" cx=\"40\" cy=\"118\" fill=\"lightgreen\" />"
     (apply #'concat
            (cl-loop for i from 0 to (min count 12) collect
                     (format "<circle r=\"40\" cx=\"40\" cy=\"%d\" fill=\"%s\" />"
                             (- 118 (* 10 i)) (if (= (% i 2) 0) "#900" "#F00")))))))

(defun org-indicator--callback (heading buffer file line)
  #'(lambda ()
      (let ((frame (make-frame-on-display (car (x-display-list)))))
        (make-frame-visible frame)
        (select-frame-set-input-focus frame)
        (if (buffer-live-p buffer)
            (pop-to-buffer buffer)
          (find-file file))
        (goto-line line)
        (unless (equal (org-get-heading) heading)
          (search-forward heading)))))

(defun org-indicator--update (entries)
  (let* ((todo-count (length entries))
         (icon-path (format "%s%sorg-indicator%sorg-indicator-%d.svg" (temporary-file-directory)
                            (path-separator) (path-separator) todo-count)))
    (unless (file-exists-p icon-path)
      (make-directory (file-name-parent-directory icon-path) t)
      (with-temp-buffer
        (insert (org-indicator--make-icon (min todo-count 9)))
        (write-file icon-path)))
    (appindicator-org-indicator-set-icon icon-path))
  (appindicator-org-indicator-set-menu
   (mapcar #'(lambda (entry)
               (cl-destructuring-bind (heading buffer file line) entry
                 (cons
                  heading
                  (org-indicator--callback heading buffer file line))))
           entries)))

(defun org-indicator-check ()
  "Check for deadlines and update the appindicator icon."
  (interactive)

  (org-indicator--update
   (org-map-entries #'(lambda ()
                        (list
                         (org-get-heading)
                         (buffer-name)
                         (buffer-file-name)
                         (line-number-at-pos)))
                    org-indicator-match-string 'agenda
                    #'(lambda () (or (org-agenda-skip-entry-if 'todo org-done-keywords-for-agenda)
                                     (org-agenda-skip-entry-if 'nottodo org-todo-keywords-for-agenda)))))
  t)

(defun org-indicator-enable ()
  "Enable the task bar indicator."
  (interactive)
  (unless (symbol-function 'appindicator-org-indicator-init)
    (appindicator-create "org-indicator" t))
  (org-indicator-disable)
  (appindicator-org-indicator-init)
  (appindicator-org-indicator-set-active t)
  (run-at-time 0 org-indicator-interval #'org-indicator-check))

(defun org-indicator-disable ()
  "Cancel the running appindicator process and the timer."
  (interactive)
  (dolist (timer timer-list)
    (if (eq (elt timer 5) #'org-indicator-check)
        (cancel-timer timer)))
  (appindicator-org-indicator-kill))

(provide 'org-indicator)
