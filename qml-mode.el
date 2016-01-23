;;; qml-mode.el --- Major mode for editing QT Declarative (QML) code.
;;
;; Copyright (C) 2013 Gregor Klinke
;;
;; Author: Gregor Klinke <gck@eyestep.org>
;; URL: https://github.com/coldnew/qml-mode
;;
;; Original author:
;; Author: William Xu <william.xwl@gmail.com>
;; Version: 0.1
;;
;; Taken further ideas from qml-mode by Yen-Chin Lee
;; <coldnew.tw@gmail.com>, original based on a qml-mode by Wen-Chun Lin.
;; Copyright (C) 2012 Yen-Chin Lee
;;
;; Version: 0.1
;; Keywords: qml, qt, qt declarative
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 3, or (at your option) any
;; later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program; see the file COPYING.  If not, write to the Free
;; Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
;; 02110-1301, USA.
;;
;;; Commentary:
;;
;; This is a simple major mode for editing Qt QML/JS files.
;;
;;; USAGE
;;
;; Type `M-x package-install qml-mode`, and add this to your init file:
;;
;;     (autoload 'qml-mode "qml-mode" "Editing Qt Declarative." t)
;;     (add-to-list 'auto-mode-alist '("\\.qml$" . qml-mode))
;;


(require 'js)
(require 'cc-langs)

;; ---------------------------------------------------------------------------
;; VARIABLES
;; Set a number of global variable for customization, global constants, etc.
;; ---------------------------------------------------------------------------
(defgroup qml nil
  "Customizations for QML Mode."
  :prefix "qml-"
  :group 'languages)


;; ---------------------------------------------------------------------------
;; KEYWORDS
;; ---------------------------------------------------------------------------

(defvar qml-keywords
  '(
    "AnchorAnimation" "AnchorChanges" "Audio" "Behavior" "Binding" "BorderImage"
    "ColorAnimation" "Column" "Component" "Connections" "Flickable" "Flipable"
    "Flow" "FocusScope" "GestureArea" "Grid" "GridView" "Image" "Item" "LayoutItem"
    "ListElement" "ListModel" "ListView" "Loader" "MouseArea" "NumberAnimation"
    "Package" "ParallelAnimation" "ParentAnimation" "ParentChange"
    "ParticleMotionGravity" "ParticleMotionLinear" "ParticleMotionWander"
    "Particles" "Path" "PathAttribute" "PathCubic" "PathLine" "PathPercent"
    "PathQuad" "PathView" "PauseAnimation" "PropertyAction" "PropertyAnimation"
    "PropertyChanges" "Qt" "QtObject" "Rectangle" "Repeater" "Rotation"
    "RotationAnimation" "Row" "Scale" "ScriptAction" "SequentialAnimation"
    "SmoothedAnimation" "SoundEffect" "SpringFollow" "State" "StateChangeScript"
    "StateGroup" "SystemPalette" "Text" "TextEdit" "TextInput" "Timer"
    "Transition" "Translate" "Video" "ViewsPositionersMediaEffects"
    "VisualDataModel" "VisualItemModel" "WebView" "WorkerScript" "XmlListModel"
    "XmlRole" "import" "property" "readonly"
    ;; javascript keywords
    "break" "case" "catch" "const" "continue" "debugger" "default" "delete" "do"
    "else" "enum" "false" "false" "finally" "for" "function" "if" "import"
    "in" "instanceof" "let" "new" "null" "return" "switch" "this" "throw"
    "true" "try" "typeof" "undefined" "var" "void" "while" "with" "yield"
    ))

(defvar qml-types
  '("alias" "as" "bool" "color" "date" "double" "int" "on" "parent" "readonly"
    "real" "signal" "string" "url" "var" "variant" ))

(defvar qml-constants
  '("AlignBottom" "AlignCenter" "AlignHCenter" "AlignLeft" "AlignRight" "AlignTop"
    "AlignVCenter" "AutoFlickDirection" "DragAndOvershootBounds" "DragOverBounds"
    "Easing" "Horizontal" "HorizontalAndVerticalFlick" "HorizontalFlick" "InBack"
    "InBounce" "InCirc" "InCubic" "InElastic" "InExpo" "InOutBack" "InOutBounce"
    "InOutCirc" "InOutCubic" "InOutElastic" "InOutExpo" "InOutQuad" "InOutQuart"
    "InOutQuint" "InQuad" "InQuart" "InQuint" "InQuint" "InSine" "LeftButton"
    "Linear" "MidButton" "MiddleButton" "NoButton" "OutBack" "OutBounce" "OutCirc"
    "OutCubic" "OutElastic" "OutExpo" "OutInBack" "OutInBounce" "OutInCirc"
    "OutInCubic" "OutInElastic" "OutInExpo" "OutInQuad" "OutInQuart" "OutInQuint"
    "OutQuad" "OutQuart" "OutQuint" "OutSine" "RightButton" "StopAtBounds"
    "Vertical" "VerticalFlick"
    ))

(defvar qml-builtin-properties
  '("width" "height" "x" "y" "z" "left" "right" "implicitHeight" "implicitWidth"
    "preferredWidth" "preferredHeight" "maximumHeight" "minimumHeight"
    "maximumWidth" "minimumWidth"
    ))



(defvar qml-keywords-pattern
  (concat "\\<" (regexp-opt qml-keywords) "\\>\\|" js--keyword-re))

(defun qml-types-pattern ()
  ""
  (concat "\\("
          (mapconcat 'identity qml-types "\\|")
          "\\|[a-zA-Z0-9_]+\\(<[a-zA-Z0-9_]+>\\)?"
          "\\)"))

(defun qml-builtin-properties-pattern ()
  ""
  (concat "[a-zA-Z0-9_]+\\.\\("
          (mapconcat 'identity qml-builtin-properties "\\|")
          "\\)"))

(defvar qml-font-lock-keywords
  `(("/\\*.*\\*/\\|//.*"                ; comment
     (0 font-lock-comment-face t t))
    ("\\<\\(true\\|false\\)\\>" ; constants
     (0 font-lock-constant-face))
    ,(eval-when-compile
       (generic-make-keywords-list qml-types 'font-lock-type-face))
    ,(eval-when-compile
       (generic-make-keywords-list qml-constants 'font-lock-constant-face))
    ("\\<id[ \t]*:[ \t]*\\([a-zA-Z0-9_]+\\)" (1 font-lock-constant-face))
    (,(concat "property[ \t]+" (qml-types-pattern) "+[ \t]+\\([a-zA-Z_]+[a-zA-Z0-9_]*\\)")
     (1 font-lock-type-face)
     (3 font-lock-variable-name-face))

    (,(qml-builtin-properties-pattern) (1 font-lock-builtin-face))
    (,(concat qml-keywords-pattern "\\|\\<parent\\>") ; keywords
     (0 font-lock-keyword-face nil t))
    ("\\(function\\|signal\\)\\{1\\}[ \t]+\\([a-zA-Z_]+[a-zA-Z0-9_]*\\)" (2 font-lock-function-name-face))
    ("\\([a-zA-Z_\\.]+[a-zA-Z0-9_]*\\)[ \t]*:" (1 font-lock-type-face))
    ("\\([+-]?\\<[0-9]*\\.?[0-9]+[xX]?[0-9a-fA-F]*\\)" (1 font-lock-constant-face))
;    ("\\<\\([A-Z][a-zA-Z0-9]*\\)\\>"    ; Elements
;     (1 font-lock-function-name-face nil t)
;     (2 font-lock-function-name-face nil t))
    ("\\([a-zA-Z0-9]+\\)[ \t]*{" (1 font-lock-builtin-face))
    ("\\('[[:alpha:]]*'\\)" (1 font-lock-string-face))
    )
  "Keywords to highlight in `qml-mode'.")


(defvar qml-mode-syntax-table
  (let ((table (make-syntax-table)))
    (c-populate-syntax-table table)
    ;; Comment styles are same as C++
    (modify-syntax-entry ?/ ". 124b" table)
    (modify-syntax-entry ?* ". 23" table)
    (modify-syntax-entry ?\n "> b" table)
    (modify-syntax-entry ?' "\"" table)
    table))

;;;###autoload
(define-derived-mode qml-mode js-mode "QML"
  "Major mode for editing Qt QML files.

Usage:
------

- WORD/COMMAND COMPLETION:  Typing `\\[qml-expand-abbrev]' after a (not completed) word looks
  for a word in the buffer or a QML/JS keyword that starts alike, inserts it
  and adjusts case.  Re-typing `\\[qml-expand-abbrev]' toggles through alternative word
  completions.


Key bindings:
-------------

\\{qml-mode-map}"

  :syntax-table qml-mode-syntax-table
  (setq font-lock-defaults '(qml-font-lock-keywords))
  (set (make-local-variable 'comment-start-skip) "\\(//[!]?\\) *")
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'indent-tabs-mode) nil)
  (set (make-local-variable 'require-final-newline) t)
  (set (make-local-variable 'comment-column) 40)
  (set (make-local-variable 'end-comment-column) 79)
  (run-hooks 'qml-mode-hook))

(define-key qml-mode-map "\M-\C-a" 'qml-beginning-of-defun)
(define-key qml-mode-map "\M-\C-e" 'qml-end-of-defun)
(define-key qml-mode-map "\M-\C-h" 'qml-mark-defun)
(define-key qml-mode-map "\C-c." 'qml-expand-abbrev)
(define-key qml-mode-map "\C-c\C-r" 'run-qmlscene)

(defconst qml-defun-start-regexp "\{")

(defconst qml-defun-end-regexp "\}")

(defun qml-beginning-of-defun ()
  "Set the pointer at the beginning of the element within which the pointer is located."
  (interactive)
  (re-search-backward qml-defun-start-regexp))

(defun qml-end-of-defun ()
  "Set the pointer at the beginning of the element within which the pointer is located."
  (interactive)
  (re-search-forward qml-defun-end-regexp))

(defun qml-mark-defun ()
  "Set the region pointer around element within which the pointer is located."
  (interactive)
  (beginning-of-line)
  (qml-end-of-defun)
  (set-mark (point))
  (qml-beginning-of-defun))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Hippie expand customization (for expansion of qml commands)

(defvar qml-abbrev-list
  (append
   (list nil) qml-keywords
	  (list nil) qml-types
	  (list nil) qml-builtin-properties
	  (list nil) qml-constants)
  "Predefined abbreviations for Qml.")

(defvar qml-expand-upper-case nil)

(eval-when-compile (require 'hippie-exp))

(defun qml-try-expand-abbrev (old)
  "Try expanding abbreviations from `qml-abbrev-list'."
  (unless old
    (he-init-string (he-dabbrev-beg) (point))
    (setq he-expand-list
          (let ((abbrev-list qml-abbrev-list)
                (sel-abbrev-list '()))
            (while abbrev-list
              (when (or (not (stringp (car abbrev-list)))
                        (string-match
                         (concat "^" he-search-string) (car abbrev-list)))
                (setq sel-abbrev-list
                      (cons (car abbrev-list) sel-abbrev-list)))
              (setq abbrev-list (cdr abbrev-list)))
            (nreverse sel-abbrev-list))))
  (while (and he-expand-list
              (or (not (stringp (car he-expand-list)))
                  (he-string-member (car he-expand-list) he-tried-table t)))
                                        ;		  (equal (car he-expand-list) he-search-string)))
    (unless (stringp (car he-expand-list))
      (setq qml-expand-upper-case (car he-expand-list)))
    (setq he-expand-list (cdr he-expand-list)))
  (if (null he-expand-list)
      (progn (when old (he-reset-string))
             nil)
    (he-substitute-string
     (if qml-expand-upper-case
         (upcase (car he-expand-list))
       (car he-expand-list))
     t)
    (setq he-expand-list (cdr he-expand-list))
    t))


(defun qml-expand-abbrev (arg))
(fset 'qml-expand-abbrev (make-hippie-expand-function
                          '(try-expand-dabbrev
                            try-expand-dabbrev-all-buffers
                            qml-try-expand-abbrev)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Run qmlscene

(require 'comint)
(require 'compile)

(defcustom qml-qmlscene-command "qmlscene"
  "*Command to run qmlscene"
  :type 'string
  :group 'qml)

(defcustom qml-qmlscene-ask-about-save t
  "Non-nil means \\[run-qmlscene] asks which buffers to save before starting qmlscene.
Otherwise, it saves all modified buffers without asking."
  :type 'boolean
  :group 'qml)

;; History of compile commands.
(defvar qml-qmlscene-history nil)

(defun qml-qmlscene-read-command (command)
  (read-shell-command "Compile qmlscene: " command
                      (if (equal (car qml-qmlscene-history) command)
                          '(qml-qmlscene-history . 1)
                        'qml-qmlscene-history)))

(defun run-qmlscene (command &optional comint)
  "Run QmlScene.  Default: run `qml-qmlscene-command'.
Runs COMMAND, a shell command, in a separate process asynchronously with
output going to the buffer `*compilation*'.

You can then use the command \\[next-error] to find the next error message
and move to the source code that caused it.

If optional second arg COMINT is t the buffer will be in Comint mode with
`compilation-shell-minor-mode'.

Interactively prompts for the command; otherwise uses
`qml-qmlscene-command'.  With prefix arg, always prompts.
Additionally, with universal prefix arg, compilation buffer will
be in comint mode, i.e. interactive.

To run more than one qmlscene instance at once, start one then rename
the \`*compilation*' buffer to some other name with
\\[rename-buffer].  Then _switch buffers_ and start the new compilation.
It will create a new \`*compilation*' buffer.

On most systems, termination of the main qmlscene process kills
its subprocesses.

The name used for the buffer is actually whatever is returned by the function
in `compilation-buffer-name-function', so you can set that
to a function that generates a unique name."
  (interactive
   (list (let ((command (eval qml-qmlscene-command)))
           (qml-qmlscene-read-command command))
         (consp current-prefix-arg)))
  (unless (equal command (eval qml-qmlscene-command))
    (setq qml-qmlscene-command command))
  (save-some-buffers (not qml-qmlscene-ask-about-save) nil)
  ;;  (setq-default compilation-directory default-directory)
  (compilation-start command comint))

(provide 'qml-mode)

;;; qml-mode.el ends here
