;;; company-roslaunch.el --- path autocompletion for $(find pkg-name)/... in roslaunch file.  -*- lexical-binding: t; -*-

;; Path autocompletion for $(find pkg-name)/...
(require 'company)

(defun company-roslaunch--prepare-candidates (prefix file-list)
  (let (new-list)
    (dolist (element file-list new-list)
      (setq new-list (cons (concat prefix element) new-list)))))

(defun company-roslaunch--replace-in-string (pattern replacement original-text)
  (replace-regexp-in-string pattern replacement original-text nil 'literal))

(defun company-roslaunch--get-rospack-absolute-path (rospack-find-str)
  (let* ((pkg-path (company-roslaunch--replace-in-string "find" "rospack find" rospack-find-str))
         (absolute-path (shell-command-to-string (concat "/bin/echo -n " pkg-path)))
         (no-package (string-match "\\[rospack\\] Error: package .* not found" absolute-path)))
    (unless no-package
      absolute-path)))

(defun company-roslaunch--get-candidates (rospack-find-str)
  (let (absolute-path)
    (setq absolute-path (company-roslaunch--get-rospack-absolute-path rospack-find-str))
    (if (file-directory-p absolute-path)
        (setq rospack-find-str (company-roslaunch--replace-in-string "/*\\'" "/" rospack-find-str))
      (setq rospack-find-str (company-roslaunch--replace-in-string "/[^/ \"]+\\'" "/" rospack-find-str)))
    (company-roslaunch--prepare-candidates rospack-find-str (cdr (cdr (directory-files (company-roslaunch--get-rospack-absolute-path rospack-find-str)))))))

(defun company-roslaunch-company-rospack-find-backend (command &optional arg &rest ignored)
  (interactive (list 'interactive))
  (case command
    (interactive (company-begin-backend 'company-roslaunch-company-rospack-find-backend))
    ; TODO: replace looking-back with more efficient methods
    (prefix (and (eq major-mode 'nxml-mode)
                 (when (looking-back "\\$(find [^\"\/ )]+)/[^\" ]*")
                   (match-string 0))))
    (candidates
     (remove-if-not
      (lambda (c) (string-prefix-p arg c))
      (company-roslaunch--get-candidates arg)))))

(add-hook 'nxml-mode-hook
          (lambda ()
            (set (make-local-variable 'company-backends) '(company-nxml company-roslaunch-company-rospack-find-backend))
            (company-mode)))

(defun company-roslaunch--recursively-up-find-file (search-path target-file-name)
  (let ((parent-dir (expand-file-name (directory-file-name (file-name-directory search-path)))))
    (if (file-exists-p (expand-file-name target-file-name parent-dir)) parent-dir
      (if (string= parent-dir "/") nil
        (company-roslaunch--recursively-up-find-file parent-dir target-file-name)))))

(defun company-roslaunch-find-current-catkin-workspace ()
  (interactive)
  (message (company-roslaunch--recursively-up-find-file (spacemacs--file-path) ".catkin_workspace")))

(provide 'company-roslaunch)
