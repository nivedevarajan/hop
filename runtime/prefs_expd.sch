;*=====================================================================*/
;*    serrano/prgm/project/hop/2.4.x/runtime/prefs_expd.sch            */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Tue Mar 28 07:04:20 2006                          */
;*    Last change :  Sun Dec  9 01:01:35 2012 (serrano)                */
;*    Copyright   :  2006-12 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    The definition of the DEFINE-PREFERENCES macro.                  */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    define-preferences ...                                           */
;*    -------------------------------------------------------------    */
;*    This generates three functions: id-load, id-save, and id-edit.   */
;*---------------------------------------------------------------------*/
(define (hop-define-prefs-expander x e)

   ;; make-load
   (define (make-load id)
      (let ((mod (eval-module)))
	 `(define (,id file)
	     (synchronize (preferences-mutex)
		,(if (evmodule? mod)
		     `(hop-load file
			 :env (eval-find-module ',(evmodule-name mod)))
		     `(hop-load file))))))

   ;; make-save
   (define (make-save id key clauses)

      (define sig ";; hop-sig: ")

      (define (make-save-clause c)
	 (match-case c
	    ((?- ?type (and (? symbol?) ?param))
	     `(begin
		 ,(match-case type
		     (expr
		      `(write (list ',(symbol-append param '-set!)
				    (,param))))
		     ((or quote (list . ?-) (alist . ?-))
		      `(write (list ',(symbol-append param '-set!)
				    (list 'quote (,param)))))
		     (else
		      `(write (list ',(symbol-append param '-set!) (,param)))))
		 (newline)))
	    (else
	     #unspecified)
	    (((? string?) ?-)
	     #unspecified)))

      (define (onload clauses)
	 (let ((k (memq :onload clauses)))
	    (if (and (pair? k) (pair? (cdr k)))
		`(begin
		    (write '(,(cadr k)))
		    (newline))
		#unspecified)))

      `(begin
	  ;; generate the save procedure
	  (define (,id file #!optional force-override)
	     
	     (define (save file)
		(let* ((str (with-output-to-string
			       (lambda ()
				  ,@(map make-save-clause clauses)
				  ,(onload clauses))))
		       (sum (md5sum str)))
		   (synchronize (preferences-mutex)
		      (with-output-to-file file
			 (lambda ()
			    (display ,sig)
			    (print sum)
			    (display str)))))
		file)
	     
	     (define (signed? file)
		(when (file-exists? file)
		   (with-input-from-file file
		      (lambda ()
			 (let ((l (read-line)))
			    (when (substring-at? l ,sig 0)
			       (let ((sum (substring l
						     ,(string-length sig)
						     (string-length l)))
				     (rest (read-string)))
				  (string=? sum (md5sum rest)))))))))

	     (cond
		((or (not (file-exists? file)) (signed? file))
		 (save file))
		(force-override
		 (rename-file file (string-append file ".hopsave"))
		 (save file))
		(else
		 #f)))
	  ;; register the save procedure
	  (preferences-register-save! ,key ,id)))

   ;; make-edit
   (define (make-edit id key clauses)

      (define (make-edit-clause c)
	 (match-case c
	    (((and (? string?) ?lbl) ?type (and (? symbol?) ?param))
	     (let ((get param)
		   (set (symbol-append param '-set!)))
		`(<PR> :param (list ',param ,get ,set) :type ',type ,lbl)))
	    ((? string?)
	     `(<PRLABEL> ,c))
	    (--
	     '(<PRSEP>))
	    (else
	     #f)))
      
      `(define (,id #!key id)
	  (<PREFS> :id (xml-make-id id 'preferences) :lang ,key
	     ,@(filter-map make-edit-clause clauses))))

   ;; check clauses
   (define (check-clauses clauses)
      (cond
	 ((null? clauses)
	  #t)
	 ((eq? (car clauses) :onload)
	  (if (null? (cdr clauses))
	      (error "define-preferences" "Illegal form" x)
	      (check-clauses (cddr clauses))))
	 ((or (string? (car clauses)) (eq? (car clauses) '--))
	  (check-clauses (cddr clauses)))
	 (else
	  (match-case (car clauses)
	     (((and (? string?) ?lbl) ?type (and (? symbol?) ?param))
	      (check-clauses (cdr clauses)))
	     (else
	      (error "define-preferences" "Illegal form" x))))))
   
   (match-case x
      ((?- (and (? symbol?) ?id) . ?clauses)
       (let* ((key (symbol->string (gensym id)))
	      (body `(begin
			,(make-load (symbol-append id '-load))
			,(make-save (symbol-append id '-save) key clauses)
			,(make-edit (symbol-append id '-edit) key clauses))))
	  (e (evepairify body x) e)))
      (else
       (error "define-preferences" "Illegal form" x))))

