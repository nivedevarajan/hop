;*=====================================================================*/
;*    serrano/prgm/project/hop/2.5.x/widget/slider.scm                 */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Thu Aug 18 10:01:02 2005                          */
;*    Last change :  Fri Jul 19 16:03:33 2013 (serrano)                */
;*    Copyright   :  2005-13 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    The HOP implementation of sliders.                               */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hopwidget-slider

   (library web hop)

   (static  (class html-slider::xml-element
	       (klass read-only)
	       (value read-only)
	       (min read-only)
	       (max read-only)
	       (step read-only)
	       (onchange read-only)
	       (caption read-only)))

   (export  (<SLIDER> . ::obj)))

;*---------------------------------------------------------------------*/
;*    <SLIDER> ...                                                     */
;*---------------------------------------------------------------------*/
(define-tag <SLIDER> ((id #unspecified string)
		      (class #unspecified string)
		      (value 0)
		      (min 0)
		      (max 100)
		      (step 1)
		      (onchange #f)
		      (caption "top")
		      (attrs))
   (instantiate::html-slider
      (tag 'slider)
      (klass (if (string? class) class "hop-slider"))
      (id (xml-make-id id 'SLIDER))
      (value value)
      (min min)
      (max max)
      (step step)
      (onchange onchange)
      (caption caption)
      (attributes attrs)
      (body '())))

;*---------------------------------------------------------------------*/
;*    valueof ...                                                      */
;*---------------------------------------------------------------------*/
(define (valueof attr obj)
   (cond
      ((integer? obj)
       obj)
      ((isa? obj xml-tilde)
       (xml-tilde->expression obj))
      (else
       (error "<SLIDER>" (format "Illegal ~a" attr) obj))))
       
;*---------------------------------------------------------------------*/
;*    xml-write ::html-slider ...                                      */
;*---------------------------------------------------------------------*/
(define-method (xml-write obj::html-slider p backend)
   (with-access::html-slider obj (id klass value min max step onchange caption)
      (let ((gid (gensym))
	    (oc (cond
		   ((isa? onchange xml-tilde)
		    (xml-tilde->return onchange))
		   ((string? onchange)
		    onchange)
		   (else
		    ""))))
	 (fprintf p "<script id='~a' type='~a'>" gid (hop-mime-type))
	 (fprint p
		 "hop_add_event_listener( '" gid "', 'ready', function( e ) { hop_slider_onchange_set( "
		 "hop_make_slider( "
		 "document.getElementById( '" gid "' ), "
		 "'" klass "', "
		 "'" id "', ")
 	 (xml-write-expression min p)
	 (display ", " p)
	 (xml-write-expression max p)
	 (display ", " p)
	 (xml-write-expression step p)
	 (display ", " p)
	 (xml-write-expression value p)
	 (display ", " p)
	 (xml-write-expression caption p)
	 (fprint p "), function(event) { " oc " } ) }, false )"))
      (display "</script>" p)))

