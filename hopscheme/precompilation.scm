(module __hopscheme_precompilation
   (library scheme2js)
   (import __hopscheme_config)
   (export (precompile-module m::symbol resolver::procedure)
	   (precompile-headers headers::pair-nil)))

(define (precompile-module m resolver)
   (let* ((files (resolver m '*))
	  (compiled (any (lambda (f)
			    (precompile-imported-module-file
			     m
			     f
			     *hop-reader*
			     (hopscheme-config #f)
			     :bigloo-modules? #t
			     :store-exports-in-ht? #t
			     :store-exported-macros-in-ht? #t))
			 files)))
      (if compiled
	  compiled
	  (error 'hopscheme
		 "Could not find module"
		 m))))
   
(define (precompile-headers headers)
   (let loop ((headers headers)
	      (rev-imports '())
	      (rev-others '()))
      (if (null? headers)
	  `(merge-first ,@(reverse! rev-others)
			(import ,@(reverse! rev-imports)))
	  (let ((header (car headers)))
	     (match-case header
		((import ?i1 . ?Lis)
		 (let liip ((import-names (cdr header))
			    (rev-imports rev-imports))
		    (if (null? import-names)
			(loop (cdr headers)
			      rev-imports
			      rev-others)
			(liip (cdr import-names)
			      (cons (precompile-module (car import-names)
						       (bigloo-module-resolver))
				    rev-imports)))))
		(else
		 (loop (cdr headers)
		       rev-imports
		       (cons header rev-others))))))))