(module encapsulation
   (import symbol
	   nodes
	   config
	   verbose)
   (export (encapsulation! tree::Module)))

;; if we are encapsulating the modules (ie putting it into an anonymous
;; function), then we need/want a 'return' in the anonymous function.
;; don't forget to transmit the 'this' either.
;; js-call is not inlined in later passes (otherwise we would need to flag this
;; node)
(define (encapsulation! tree)
   (when (or (config 'encapsulate-modules)
	     (config 'suspend/resume))
      (verbose " encapsulation")
      (with-access::Module tree (body)
	 (let* ((encapsulated-body (instantiate::Return (val body)))
		(encapsulation-lambda (instantiate::Lambda
					 (scope-vars '())
					 (formals '())
					 (vaarg? #f)
					 (body encapsulated-body)))
		(call (instantiate::SCall
			 (operator (runtime-reference 'js-call))
			 (operands (list (var-reference (instantiate::This-Var
							   (id 'this)
							   (js-id "this")))
					 encapsulation-lambda)))))
	 (set! body call)))))