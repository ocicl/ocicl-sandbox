(let ((ocicl-runtime:*download* t)
      (ocicl-runtime:*verbose* t))
  (asdf:load-system :completions)
  (asdf:load-system :tmpdir)
  (asdf:load-system :str))

(let ((system (str:trim (uiop:getenv "SYSTEM")))
      (v1 (str:trim (uiop:getenv "PREVIOUS")))
      (v2 (str:trim (uiop:getenv "CURRENT"))))
  (tmpdir:with-tmpdir (dir)
    (uiop:with-current-directory (dir)
      (format t "ocicl-oras pull ghcr.io/ocicl/~A:~A" system v1)
      (format t "ocicl-oras pull ghcr.io/ocicl/~A:~A" system v2)
      (uiop:run-program (format nil "ocicl-oras pull ghcr.io/ocicl/~A:~A" system v1) :output *standard-output*)
      (uiop:run-program (format nil "ocicl-oras pull ghcr.io/ocicl/~A:~A" system v2) :output *standard-output*)
      (let ((files (uiop:directory-files dir)))
        (print files)
        (dolist (file files)
          (uiop:run-program (format nil "tar xf ~A" file) :output *standard-output*)))1
      (let ((diff (uiop:run-program (format nil "diff -ur ~{~A ~}"
                                            (sort (uiop:subdirectories dir)
                                                  (lambda (a b)
                                                    (string< (namestring a)
                                                             (namestring b)))))
                                    :ignore-error-status t
                                    :output :string))
            (completer (make-instance 'completions:openai-completer
                                      :api-key (uiop:getenv "LLM_API_KEY"))))
        (print diff)
        (let ((text (completions:get-completion completer
                                                (format nil "You are my Lisp programming assistant.  What follows are diffs between two versions of the Common Lisp project containing the lisp system ~A.  Summarize the differences that would matter for users of this code, API changes in particular.  Use point form.  Ignore version changes.  Symbols in Common Lisp are case insensitive.  Produce output in github markdown format.  Here's an example of good output:

The updates in the Common Lisp system 'machine-state' primarily involve enhancing garbage handling and memory size calculation across various Lisp implementations. Here's a summary of these changes:

** Key Changes
* Using Proper Garbage Collector Function in ECL:
In ECL (Embeddable Common Lisp), the function to get garbage collection statistics has been updated to work with both #+boehm-gc and #-boehm-gc. When boehm-gc is not available, a zero is returned.
* Memory Size Calculation Modification in ABCL:
For ABCL (Armed Bear Common Lisp), a new block of code calculates the total memory and free memory using Java Runtime class methods. This explicitly specifies how memory is calculated in an ABCL environment.
* Allocated and Free Memory Calculation in CLISP:
A change has been made in how the total and used memory are calculated in CLISP. Rather than returning 0, as was previously done, the used memory and sum of used and room memory are returned.

** User Impact
* Enhanced Flexibility: These updates enhance the system's flexibility by catering to different Lisp implementations. This allows users of different implementations to use this system without having to adjust their code.
* Accurate Memory Statistics: The updates also result in more accurately reflecting memory usage statistics in different Lisp environments.

It's important to note that these changes mainly affect internal functionality and improve dump output accuracy across different Lisp implementation. Users will benefit from more accurate memory usage information but are not required to adjust any of their existing interaction with the system.
~%~%~%Here are the diffs: ~A"
                                                        system
                                                        diff))))
          (let ((full-text
                  (concatenate 'string
                               (with-input-from-string (stream text)
                                 (print (uiop:run-program "pandoc - -f gfm -t plain --columns=75" :input stream :output :string)))
                               (format nil "~&~%[This text was generated by AI and may not be fully accurate or complete.]~%"))))
            (with-open-file (str "/github/workspace/changes.txt"
                                 :direction :output
                                 :if-exists :supersede
                                 :if-does-not-exist :create)
              (format str "~A" full-text))))))))

(quit)
