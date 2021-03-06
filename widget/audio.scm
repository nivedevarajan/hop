;*=====================================================================*/
;*    serrano/prgm/project/hop/2.4.x/widget/audio.scm                  */
;*    -------------------------------------------------------------    */
;*    Author      :  Manuel Serrano                                    */
;*    Creation    :  Wed Aug 29 08:37:12 2007                          */
;*    Last change :  Fri Nov 16 14:17:53 2012 (serrano)                */
;*    Copyright   :  2007-12 Manuel Serrano                            */
;*    -------------------------------------------------------------    */
;*    Hop Audio support.                                               */
;*=====================================================================*/

;*---------------------------------------------------------------------*/
;*    The module                                                       */
;*---------------------------------------------------------------------*/
(module __hopwidget-audio
   
   (library multimedia web hop)
   
   (import  __hopwidget-slider)

   (cond-expand
      (enable-threads
       (library pthread)))

   (export  (class audio-server
	       (audio-server-init)
	       (music (get (lambda (o)
			      (with-access::audio-server o (%music)
				 %music)))
		      (set %audio-server-music-set!)
		      (default #f))
	       (%music (default #f))
	       (%hmutex read-only (default (make-mutex)))
	       (%path (default #unspecified))
	       (%service (default #unspecified))
	       (%event (default #unspecified))
	       (%errcount::int (default 0))
	       (%state::symbol (default 'init))
	       (%log::pair-nil (default '()))
	       (%meta (default #f)))

	    (%audio-server-music-set! ::audio-server ::obj)
	    
	    (class webmusic::music
	       (audioserver::obj (default #unspecified))
	       (playlist::pair-nil (default '()))
	       (playtime::elong (default #e0)))
	    
	    (generic audio-server-init ::audio-server)
	    
	    (<AUDIO> . args)
	    (audio-server-close ::obj)))

;*---------------------------------------------------------------------*/
;*    %audio-server-music-set! ...                                     */
;*---------------------------------------------------------------------*/
(define (%audio-server-music-set! o::audio-server v)
   (with-access::audio-server o (%hmutex %music %state)
      (synchronize %hmutex
	 (when (isa? %music music)
	    (music-close %music))
	 (set! %music v)
	 (when (isa? v webmusic)
	    ;; register the mapping audioserver/webserver
	    (set! %state 'ready)
	    (with-access::webmusic v (audioserver)
	       (set! audioserver o))))))

;*---------------------------------------------------------------------*/
;*    music-init ::webmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-init o::webmusic)
   (with-access::webmusic o (onstate onevent onplaylist onerror onvolume
			       audioserver)
      (with-access::audio-server audioserver (%event)
	 (let ((old onstate))
	    (set! onstate
	       (lambda (m s)
		  ((audio-onstate %event o audioserver) s)
		  (old m s))))
	 (let ((old onevent))
	    (set! onevent
	       (lambda (m id v)
		  ((audio-onmeta %event o audioserver) v)
		  (old m id v))))
	 (let ((old onvolume))
	    (set! onvolume
	       (lambda (m v)
		  ((audio-onvolume %event o) v)
		  (old m v))))
	 (let ((old onerror))
	    (set! onerror
	       (lambda (m e)
		  ((audio-onerror %event o) e)
		  (old m e)))))))
	 
;*---------------------------------------------------------------------*/
;*    *audio-mutex* ...                                                */
;*---------------------------------------------------------------------*/
(define *audio-mutex* (make-mutex))
(define *audio-service* #f)

;*---------------------------------------------------------------------*/
;*    <AUDIO> ...                                                      */
;*    -------------------------------------------------------------    */
;*    See __hop_css for HSS types.                                     */
;*---------------------------------------------------------------------*/
(define-tag <AUDIO> ((id #unspecified string)
		     (src #f)
		     (autoplay #f boolean)
		     (start 0)
		     (loopstart 0)
		     (loopend 0)
		     (end -1)
		     (loopcount 0)
		     (controls #f)
		     (onload #f)
		     (onprogress #f)
		     (onerror (secure-javascript-attr "hop_report_audio_exception( event )"))
		     (onended #f)
		     (onloadedmetadata #f)
		     (onplay #f)
		     (onstop #f)
		     (onpause #f)
		     (onnext #f)
		     (onprev #f)
		     (onclose #f)
		     (onbackend #f)
		     (onprevclick #unspecified)
		     (onplayclick #unspecified)
		     (onpauseclick #unspecified)
		     (onnextclick #unspecified)
		     (onstopclick #unspecified)
		     (onloadclick (secure-javascript-attr "alert('load: not implemented')"))
		     (onpodcastclick (secure-javascript-attr "alert('podcast: not implemented')"))
		     (onprefsclick (secure-javascript-attr "alert('prefs: not implemented')"))
		     (onmuteclick #unspecified)
		     (onvolumechange #unspecified)
		     (onpanchange #unspecified)
		     (browser 'auto)
		     (server #f)
		     (native #t)
		     (attr)
		     body)
   
   (set! id (xml-make-id id 'hopaudio))
   (define hid (xml-make-id 'html5))
   (define fid (xml-make-id 'flash))
   (define cid (xml-make-id 'hopaudio))
   
   (define (<controls>)
      (<AUDIO:CONTROLS>
	 :id cid :audioid id
	 :onprevclick onprevclick
	 :onpauseclick onpauseclick
	 :onplayclick onplayclick
	 :onstopclick onstopclick
	 :onnextclick onnextclick
	 :onloadclick onloadclick
	 :onprefsclick onprefsclick
	 :onpodcastclick onpodcastclick
	 :onmuteclick onmuteclick))
   
   (define (<audio:init> #!key backendid backend)
      (<AUDIO:INIT> :id id :backendid backendid
	 :backend backend
	 :server server
	 :src src :playlist (playlist body)
	 :autoplay autoplay :start start
	 :onplay (hop->js-callback onplay)
	 :onstop (hop->js-callback onstop)
	 :onpause (hop->js-callback onpause)
	 :onload (hop->js-callback onload)
	 :onerror (hop->js-callback onerror)
	 :onended (hop->js-callback onended)
	 :onprogress (hop->js-callback onprogress)
	 :onloadedmetadata (hop->js-callback onloadedmetadata)
	 :onclose (hop->js-callback onclose)
	 :onbackend (hop->js-callback onbackend)))
   
   (define (playlist suffixes)
      (filter-map (lambda (x)
		     (when (xml-markup-is? x 'source)
			(let ((src (dom-get-attribute x "src")))
			   (when (string? src)
			      (let ((type (dom-get-attribute x "type")))
				 (if type
				     (list type src)
				     src))))))
		  body))

   (if native
       (instantiate::xml-element
	  (id id)
	  (tag 'audio)
	  (attributes `(:controls ,controls :autoplay ,autoplay :src ,src))
	  (body body))
       (<DIV> :id id :class "hop-audio"
	  (when controls (<controls>))
	  (case browser
	     ((flash)
	      (list (<audio:init> :backendid fid
		       :backend (format "document.getElementById( ~s )" fid))
		    (<AUDIO:FLASH> :id fid)))
	     ((html5)
	      (list (<audio:init> :backendid hid
		       :backend (format "document.getElementById( ~s )" hid))
		    (<AUDIO:HTML5> :id hid :autoplay autoplay)))
	     ((none)
	      (list (<audio:init> :backendid id :backend "false")
		    (<AUDIO:SERVER> :id id)))
	     ((auto)
	      (list (<audio:init> :backendid hid
		       :backend
		       (format "document.getElementById( ~s )" hid))
		    (<audio:init> :backendid fid
		       :backend
		       (format "document.getElementById( ~s )" fid))
		    (<AUDIO:HTML5> :id hid :autoplay autoplay)
		    (<AUDIO:FLASH> :id fid :guard "!hop_config.html5_audio")))
	     (else
	      (error "<AUDIO>" "Illegal backend" browser))))))

;*---------------------------------------------------------------------*/
;*    <AUDIO:SERVER> ...                                               */
;*---------------------------------------------------------------------*/
(define (<AUDIO:SERVER> #!key id)
   (<SCRIPT>
      (format "hop_add_event_listener( window, 'ready', function (e) {" id)
      (format "hop_audio_init[ '~a' ]( document.getElementById( '~a' ) );} )" id id)))

;*---------------------------------------------------------------------*/
;*    <AUDIO:HTML5> ...                                                */
;*    -------------------------------------------------------------    */
;*    The native attribute is a hack to let AUDIO nodes be comparable  */
;*    by the tree comparison security manager.                         */
;*---------------------------------------------------------------------*/
(define (<AUDIO:HTML5> #!key id controls src src guard autoplay #!rest body)
   (list (instantiate::xml-element
	    (id id)
	    (tag 'audio)
	    (attributes `(:controls ,controls :autoplay ,autoplay :native #t :src ,src))
	    (body body))
	 (<SCRIPT>
	    (format "if( ~a && hop_config.html5_audio ) {" (or guard "true"))
	    "hop_add_event_listener( window, 'ready', function(e) { "
	    (format "var backend = document.getElementById( ~s );" id)
	    (format "hop_audio_html5_init( backend ); hop_audio_init[ '~a' ]( backend ); }, false );};" id))))
   
;*---------------------------------------------------------------------*/
;*    <AUDIO:FLASH> ...                                                */
;*---------------------------------------------------------------------*/
(define (<AUDIO:FLASH> #!key id guard)
   (let* ((swf (make-file-path (hop-share-directory) "flash" "HopAudio.swf"))
	  (init (string-append "hop_audio_flash_init_" id))
	  (fvar (string-append "arg=" init)))
      (<DIV> :id id :hssclass "hop-audio-flash-container"
	 (<SCRIPT>
	    (format "function ~a() {" init)
	    (if guard (format "if( ~a ) {" guard) "{")
	    (format "var backend = document.getElementById( ~s );" id)
	    (format "hop_audio_flash_init( backend ); hop_audio_init[ '~a' ]( backend );}}" id id))
	 (<OBJECT> :id (string-append id "-object") :class "hop-audio"
	    :width "1px" :height "1px"
	    :title "hop-audio" :classId "HopAudio.swf"
	    :type "application/x-shockwave-flash"
	    :codebase "http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=8,0,22,0"
	    :data swf
	    (<PARAM> :name "movie" :value swf)
	    (<PARAM> :name "src" :value swf)
	    (<PARAM> :name "wmode" :value "transparent")
	    (<PARAM> :name "play" :value "1")
	    (<PARAM> :name "allowScriptAccess" :value "sameDomain")
	    (<PARAM> :name "FlashVars" :value fvar)
	    (<EMBED> :id (string-append id "-embed") :class "hop-audio"
	       :width "1px" :height "1px"
	       :src swf
	       :type "application/x-shockwave-flash"
	       :name id
	       :swliveconnect #t
	       :allowScriptAccess "sameDomain"
	       :FlashVars fvar)))))

;*---------------------------------------------------------------------*/
;*    <AUDIO:INIT> ...                                                 */
;*---------------------------------------------------------------------*/
(define (<AUDIO:INIT> #!key id backendid
		      backend
		      server
		      src playlist
		      autoplay start
		      onplay onstop onpause onload onerror onended onprogress
		      onloaded onloadedmetadata onclose onbackend)
   (<SCRIPT>
      (format "hop_audio_init[ '~a' ] = function ( backend ) {" backendid)
      (format "var audio = document.getElementById( '~a' );" id)
      "if( 'browserbackend' in audio ) return;"
      (format "audio.browserbackend = ~a;" backend)
      "if( audio.browserbackend ) audio.browserbackend.audio = audio;"
      (if server
	  (call-with-output-string
	   (lambda (op)
	      (display "audio.serverbackend = new HopAudioServerBackend( audio, " op)
	      (obj->javascript-attr server op)
	      (display "); hop_audio_server_init( audio.serverbackend );" op)
	      (display "audio.backend = audio.serverbackend;" op)))
	  "audio.serverbackend = false; audio.backend = audio.browserbackend;")
      "audio.paused = false;"
      "audio.state = false;"
      (call-with-output-string
       (lambda (op)
	  (display "audio.src = " op)
	  (obj->javascript-attr src op)
	  (display ";" op)))
      "audio.initialized = true;"
      (format "audio.start = ~a;" start)
      (format "audio.onplay = ~a;" onplay)
      (format "audio.onstop = ~a;" onstop)
      (format "audio.onpause = ~a;" onpause)
      (format "audio.onload = ~a;" onload)
      (format "audio.onerror = ~a;" onerror)
      (format "audio.onended = ~a;" onended)
      (format "audio.onprogress = ~a;" onprogress)
      (format "audio.onloadedmetadata = ~a;" onloadedmetadata)
      (format "audio.onclose = ~a;" onclose)
      (format "audio.onbackend = ~a;" onbackend)
      "audio.hop_add_event_listener = hop_audio_add_event_listener;"
      "audio.toString = function() { return '[object HopAudio]' };"
      (when (pair? playlist)
	 (call-with-output-string
	  (lambda (op)
	     (display "hop_audio_playlist_set( audio, " op)
	     (obj->javascript-attr (list playlist) op)
	     (display " );" op))))
      (when autoplay
	 "hop_audio_playlist_play( audio, 0 );")
      "};\n"))

;*---------------------------------------------------------------------*/
;*    <AUDIO:CONTROLS> ...                                             */
;*---------------------------------------------------------------------*/
(define (<AUDIO:CONTROLS> #!key id audioid
			  onprevclick onplayclick onpauseclick
			  onstopclick onnextclick
			  onloadclick onpodcastclick onmuteclick onprefsclick
			  onvolumechange onpanchange)
   
   (define (on action builtin)
      (if builtin
	  (format "var el = document.getElementById( '~a' );
                   if( el.on~aclick ) el.on~aclick( event );
	           if( !event.stopped ) hop_audio_~a( el );"
		  id action action action)
	  (format "var el = document.getElementById( '~a' );
                  if( el.on~a ) el.on~a( event );"
		  id action action)))
   
   (define (<BUT> #!key (class "") title id src onclick)
      (<DIV> :hssclass "hop-audio-button" :class class
	 (<DIV> :hssclass "hop-audio-button-background"
	    :id (or id (xml-make-id "hopaudio-but"))
	    :title title :alt title :inline #t
	    :onclick onclick)))

   (<DIV> :id id :hssclass "hop-audio-controls"
      ;; the controls callbacks
      (<SCRIPT>
	 "hop_add_event_listener( window, 'load', function(_) {"
	 (format "var audio = document.getElementById(~s);" audioid)
	 (format "var controls = document.getElementById(~s);" id)
	 "audio.controls = controls; controls.audio = audio;"
	 (format "hop_audio_controls_listeners_init( ~s );" id)
	 "})")
      ;; the info line
      (<TABLE> :class "hop-audio-panel"
	 (<TR>
	    (<TD> :class "hop-audio-panel"
	       (<AUDIO:CONTROLS-STATUS> id))
	    (<TD> :class "hop-audio-panel"
	       (<DIV> :class "hop-audio-panel2"
		  (<AUDIO:CONTROLS-METADATA> id)
		  (<AUDIO:CONTROLS-SOUND> id)))))
      ;; seek
      (<SLIDER> :class "hop-audio-seek"
	 :id (string-append id "-controls-seek")
	 :max 1000
	 :caption #f
	 :onchange (format "hop_audio_seek(document.getElementById('~a'), Math.round(60*this.value/1000))"
			   audioid))
      ;; the button line
      (<DIV> :class "hop-audio-buttons"
	 (<BUT> :title "Previous"
	    :class "hop-audio-button-prev"
	    :onclick (if (eq? onprevclick #unspecified)
			 (secure-javascript-attr
			  (format "hop_audio_playlist_prev(document.getElementById('~a'))" audioid))
			 onprevclick))
	 (<BUT> :title "Play"
	    :id (string-append id "-hop-audio-button-play")
	    :class "hop-audio-button-play"
	    :onclick (if (eq? onplayclick #unspecified)
			 (secure-javascript-attr
			  (format "hop_audio_playlist_play(document.getElementById('~a'), 0)" audioid))
			 onplayclick))
	 (<BUT> :title "Pause"
	    :id (string-append id "-hop-audio-button-pause")
	    :class "hop-audio-button-pause"
	    :onclick (if (eq? onpauseclick #unspecified)
			 (secure-javascript-attr
			  (format "hop_audio_pause(document.getElementById('~a'))" audioid))
			 onpauseclick))
	 (<BUT> :title "Stop"
	    :id (string-append id "-hop-audio-button-stop")
	    :class "hop-audio-button-stop"
	    :onclick (if (eq? onstopclick #unspecified)
			 (secure-javascript-attr
			  (format "hop_audio_stop(document.getElementById('~a'))" audioid))
			 onstopclick))
	 (<BUT> :title "Next"
	    :class "hop-audio-button-next"
	    :onclick (if (eq? onnextclick #unspecified)
			 (secure-javascript-attr
			  (format "hop_audio_playlist_next(document.getElementById('~a'))" audioid))
			 onnextclick))
	 (<BUT> :title "Playlist"
	    :class "hop-audio-button-playlist"
	    :onclick onloadclick)
	 (<BUT> :title "Podcast" :src "podcast.png"
	    :class "hop-audio-button-podcast"
	    :onclick onpodcastclick)
	 (<BUT> :title "Mute"
	    :id (string-append id "-hop-audio-button-mute")
	    :class "hop-audio-button-mute"
	    :onclick (if (eq? onmuteclick #unspecified)
			 (secure-javascript-attr
			  (format "hop_audio_mute(document.getElementById('~a'))" audioid))
			 onmuteclick))
	 (<BUT> :title "Preferences"
	    :id (string-append id "-hop-audio-button-prefs")
	    :class "hop-audio-button-prefs"
	    :onclick onprefsclick))))

;*---------------------------------------------------------------------*/
;*    <AUDIO:CONTROLS-STATUS> ...                                      */
;*---------------------------------------------------------------------*/
(define (<AUDIO:CONTROLS-STATUS> id)
   (<DIV> :class "hop-audio-info-status"
      :id (string-append id "-controls-status")
      (<DIV>
	 (<DIV> :class "hop-audio-info-status-img hop-audio-info-status-stop"
	    :id (string-append id "-controls-status-img")
	    " ")
	 (<SPAN> :class "hop-audio-info-status-position"
	    :id (string-append id "-controls-status-position")
	    "88:88"))
      (<DIV> :class "hop-audio-info-status-length"
	 (<SPAN> :class "hop-audio-info-status-length"
	    :id (string-append id "-controls-status-length-min")
	    "  ")
	 (<SPAN> :class "hop-audio-info-status-length-label" "min")
	 (<SPAN> :class "hop-audio-info-status-length"
	    :id (string-append id "-controls-status-length-sec")
	    "  ")
	 (<SPAN> :class "hop-audio-info-status-length-label" "sec"))
      (<DIV> :class "hop-audio-info-status-track"
	 (<SPAN> :class "hop-audio-info-status-track-label" "track")
	 (<SPAN> :class "hop-audio-info-status-track"
	    :id (string-append id "-controls-status-track")
	    "88888"))))

;*---------------------------------------------------------------------*/
;*    <AUDIO:CONTROLS-METADATA> ...                                    */
;*---------------------------------------------------------------------*/
(define (<AUDIO:CONTROLS-METADATA> id)
   (<DIV> :class "hop-audio-panel-metadata"
      :id (string-append id "-controls-metadata")
      (<DIV> :class "hop-audio-panel-metadata-song"
	 :id (string-append id "-controls-metadata-song")
	 "")
      (<TABLE> :class "hop-audio-panel-metadata"
	 (<TR>
	    (<TD> :class "hop-audio-panel-metadata-artist"
	       (<DIV>
		  :id (string-append id "-controls-metadata-artist")
		  ""))
	    (<TD> :class "hop-audio-panel-metadata-album"
	       (<DIV>
		  :id (string-append id "-controls-metadata-album")
		  ""))
	    (<TD> :class "hop-audio-panel-metadata-year"
	       (<DIV>
		  :id (string-append id "-controls-metadata-year")
		  ""))))))

;*---------------------------------------------------------------------*/
;*    <AUDIO:CONTROLS-SOUND> ...                                       */
;*---------------------------------------------------------------------*/
(define (<AUDIO:CONTROLS-SOUND> id)
   
   (define (on action)
      (format "var el = document.getElementById( '~a' );
               var evt = new HopAudioEvent();

               evt.value = this.value;
               if( el.on~aclick ) el.on~aclick( evt );
	       if( !evt.stopped ) hop_audio_~a( el.audio, this.value );"
	       id action action action))

   (<DIV> :class "hop-audio-panel-sound"
      (<TABLE>
	 (<TR>
	    (<TH> "VOL")
	    (<TD>
	       (<SLIDER> :id (string-append id "-controls-volume")
		  :class "hop-audio-panel-volume"
		  :min 0 :max 100 :step 1 :value 100 :caption #f
		  :onchange (on "volume_set")))
	    (<TH> :class "hop-audio-panel-left" "L")
	    (<TD> (<SLIDER> :id (string-append id "-controls-pan")
		     :class "hop-audio-panel-pan"
		     :min -100 :max 100 :step 1 :value 0 :caption #f
		     :onchange (on "pan_set")))
	    (<TH> :class "hop-audio-panel-right" "R")))))

;*---------------------------------------------------------------------*/
;*    audio-server-init ...                                            */
;*---------------------------------------------------------------------*/
(define-generic (audio-server-init as::audio-server)
   (let* ((p (gen-service-url :prefix "audio"))
	  (s (service :name p (a0 a1)
		(with-handler
		   (lambda (e)
		      (exception-notify e)
		      #f)
		   (with-access::audio-server as (%music %hmutex %state)
		      (synchronize %hmutex
			 (when (eq? %state 'ready)
			    (case a0
			       ((volume)
				(music-volume-set! %music a1)
				#t)
			       ((load)
				(music-playlist-set! %music (list a1))
				#t)
			       ((pause)
				(music-pause %music)
				#t)
			       ((play)
				(music-play %music a1)
				#t)
			       ((stop)
				(music-stop %music)
				#t)
			       ((position)
				(music-seek %music a1)
				#t)
			       ((playlist)
				(music-playlist-set! %music a1)
				#t)
			       ((status)
				(audio-status-event-value
				   (music-status %music)
				   (music-playlist-get %music)))
			       ((metadata)
				(audio-update-metadata as)
				#t)
			       ((ackplaylistset)
				(when (isa? %music webmusic)
				   (with-access::webmusic %music (playlist)
				      (set! playlist a1))))
			       ((ackpause)
				(when (isa? %music webmusic)
				   (webmusic-ackstate! %music 'pause)))
			       ((ackstop)
				(when (isa? %music webmusic)
				   (webmusic-ackstate! %music 'stop)))
			       ((ackplay)
				(when (isa? %music webmusic)
				   (webmusic-ackplay! %music a1)))
			       ((ackvolume)
				(when (isa? %music webmusic)
				   (webmusic-ackvolume! %music a1)))
			       ((close)
				(audio-server-close-sans-lock as))
			       ((poll)
				(audio-event-poll a1))
			       (else
				(tprint "unknown msg..." a0)
				#f)))))))))
      (with-access::audio-server as (%service %path %event)
	 (set! %path p)
	 (set! %event (string-append (hop-service-base) "/" %path))
	 (set! %service s))))

;*---------------------------------------------------------------------*/
;*    audio-server-close-sans-lock ...                                 */
;*---------------------------------------------------------------------*/
(define (audio-server-close-sans-lock as)
   (with-access::audio-server as (%hmutex %state %music)
      (set! %state 'close)
      (when (isa? %music music) (music-close %music))
      #f))
   
;*---------------------------------------------------------------------*/
;*    audio-server-close ...                                           */
;*---------------------------------------------------------------------*/
(define (audio-server-close as)
   (with-access::audio-server as (%hmutex)
      (synchronize %hmutex
	 (audio-server-close-sans-lock as))))

;*---------------------------------------------------------------------*/
;*    music-playlist-set! ...                                          */
;*---------------------------------------------------------------------*/
(define-generic (music-playlist-set! music::music a1)
   
   (define (can-play o)
      (cond
	 ((string? o)
	  o)
	 ((not (pair? o))
	  #f)
	 (else 
	  (let loop ((o o))
	     (when (pair? o)
		(cond
		   ((string? (car o)) (car o))
		   ((music-can-play-type? music (caar o)) (cadr (car o)))
		   (else (loop (cdr o)))))))))
   
   (music-playlist-clear! music)
   (for-each (lambda (e)
		(let ((s (can-play e)))
		   (when (string? s)
		      (let ((f (charset-convert s (hop-charset) 'UTF-8)))
			 (music-playlist-add! music f)))))
	     a1))

;*---------------------------------------------------------------------*/
;*    audio-status-event-value ...                                     */
;*---------------------------------------------------------------------*/
(define (audio-status-event-value status plist)
   (with-access::musicstatus status (state song songpos songlength volume)
      (list state songlength songpos volume song plist)))

;*---------------------------------------------------------------------*/
;*    *playlist* ...                                                   */
;*---------------------------------------------------------------------*/
(define *playlist* #f)
(define *playlist-tag* #f)
(define *playlist-mutex* (make-mutex "playlist"))

;*---------------------------------------------------------------------*/
;*    tag-playlist ...                                                 */
;*---------------------------------------------------------------------*/
(define (tag-playlist plist)
   
   (define (make-tag-playlist plist)
      (map (lambda (url)
	      (let ((durl (charset-convert url (hop-charset) (hop-locale))))
		 (if (file-exists? durl)
		     (let ((tag (file-musictag durl)))
			(if (isa? tag musictag)
			    (with-access::musictag tag (title)
			       (charset-convert title 'UTF-8 (hop-charset)))
			    url))
		     url)))
	 plist))

   (if (null? plist)
       plist
       (synchronize *playlist-mutex*
	  (cond
	     ((eq? *playlist* plist)
	      *playlist-tag*)
	     (else
	      (set! *playlist* plist)
	      (set! *playlist-tag* (make-tag-playlist plist))
	      *playlist-tag*)))))

;*---------------------------------------------------------------------*/
;*    audio-onstate ...                                                */
;*---------------------------------------------------------------------*/
(define (audio-onstate event music as)
   (lambda (status)
      (tprint "ONSTATE status=" status)
      (with-trace 3 "audio-onstate"
	 (trace-item "music=" (typeof music))
	 (trace-item "as=" (typeof as))
	 (let ((e (audio-status-event-value status (music-playlist-get music))))
	    (with-access::audio-server as (%errcount)
	       (set! %errcount 0))
	    (audio-event-broadcast! event e)))))

;*---------------------------------------------------------------------*/
;*    audio-update-metadata ...                                        */
;*    -------------------------------------------------------------    */
;*    This function is used by clients to update metadata.             */
;*---------------------------------------------------------------------*/
(define (audio-update-metadata as)
   (with-access::audio-server as (%music %event %meta)
      ((audio-onmeta %event %music as) %meta)))

;*---------------------------------------------------------------------*/
;*    audio-onmeta ...                                                 */
;*---------------------------------------------------------------------*/
(define (audio-onmeta event music as)

   (define conv (charset-converter 'UTF-8 (hop-charset)))
   
   (define (convert-file file)
      (if (or (substring-at? file "http://" 0)
	      (substring-at? file "https://" 0))
	  ;; MS, note 2 Jan 09: This assumes that URL are encoded using
	  ;; the hop-locale value and not hop-charset, nor UTF-8. Of
	  ;; course this works iff all Hop uses the same locale encoding.
	  ;; the only fully correct solution would be to encode the encoding
	  ;; in the URL and Hop should detect that encoding.
	  ((hop-locale->charset) (url-decode file))
	  (conv file)))

   (define (alist->id3 l)
      
      (define (get k l d)
	 (let ((c (assq k l)))
	    (if (pair? c) (cdr c) d)))

      (instantiate::id3
	 (title (get 'title l "???"))
	 (artist (get 'artist l "???"))
	 (album (get 'album l "???"))
	 (genre (get 'genre l "???"))
	 (year (get 'year l 0))
	 (comment (get 'comment l ""))
	 (version (get 'version l "v1"))))

   (define (signal-meta s)
      (let ((tag (cond
		    ((isa? s id3)
		     (with-access::id3 s (title artist album comment)
			(duplicate::id3 s
			   (title (conv title))
			   (artist (conv artist))
			   (album (conv album))
			   (orchestra #f)
			   (conductor #f)
			   (interpret #f)
			   (comment (conv comment)))))
		    ((isa? s vorbis)
		     (with-access::vorbis s (title artist album comment)
			(duplicate::vorbis s
			   (title (conv title))
			   (artist (conv artist))
			   (album (conv album))
			   (comment (conv comment)))))
		    ((string? s)
		     (convert-file s))
		    ((list? s)
		     (alist->id3 s))
		    (else
		     s))))
	 (trace-item "s=" (if (string? s) s (typeof s)))
	 (tprint "<<< signal meta: " (list 'meta (typeof tag)))
	 (audio-event-broadcast! event (list 'meta tag))))
   
   (define (audio-onfile-name meta)
      (let ((url (url-decode meta)))
	 (signal-meta url)))
   
   (lambda (meta)
      ;; store the meta data for audio-update-metadata
      (with-access::audio-server as (%meta)
	 (set! %meta meta))
      ;; send the event
      (with-trace 3 "audio-onmeta"
	 (trace-item "music=" (typeof music))
	 (trace-item "as=" (typeof as))
	 (with-access::audio-server as (%errcount)
	    (set! %errcount 0))
	 (cond
	    ((string? meta)
	     ;; this is a file name (a url)
	     (let ((file (charset-convert meta 'UTF-8 (hop-locale))))
		(if (not (file-exists? file))
		    (audio-onfile-name file)
		    (let ((tag (file-musictag file)))
		       (if (not tag)
			   (audio-onfile-name file)
			   (signal-meta tag))))))
	    ((list? meta)
	     (signal-meta meta))
	    ((isa? meta musictag)
	     (signal-meta meta))))))

;*---------------------------------------------------------------------*/
;*    audio-onerror ...                                                */
;*---------------------------------------------------------------------*/
(define (audio-onerror event music)
   (lambda (error)
      (with-trace 3 "audio-onerror"
	 (trace-item "music=" (typeof music))
	 (audio-event-broadcast! event (list 'error error)))))

;*---------------------------------------------------------------------*/
;*    audio-onvolume ...                                               */
;*---------------------------------------------------------------------*/
(define (audio-onvolume event music)
   (lambda (vol)
      (with-trace 3 "audio-onvolume"
	 (trace-item "music=" (typeof music))
	 (audio-event-broadcast! event (list 'volume vol)))))

;*---------------------------------------------------------------------*/
;*    hop->javascript ::%audio-server ...                              */
;*---------------------------------------------------------------------*/
(define-method (hop->javascript as::audio-server op compile isrep)
   (with-access::audio-server as (%path)
      (fprintf op "\"~a/~a\"" (hop-service-base) %path))
   #t)

;*---------------------------------------------------------------------*/
;*    music-init ::webmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-init o::webmusic)
   (with-access::webmusic o (%status)
      (with-access::musicstatus %status (volume)
	 (set! volume 100))))

;*---------------------------------------------------------------------*/
;*    music-close ...                                                  */
;*---------------------------------------------------------------------*/
(define-method (music-close o::webmusic)
   (tprint "MUSIC-CLOSE ::webmusic")
   #f)

;*---------------------------------------------------------------------*/
;*    music-closed? ::webmusic ...                                     */
;*---------------------------------------------------------------------*/
(define-method (music-closed? o::webmusic)
   #f)

;*---------------------------------------------------------------------*/
;*    music-play ::webmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-play o::webmusic . song)
   'todo)

;*---------------------------------------------------------------------*/
;*    music-playlist-set! ::webmusic ...                               */
;*---------------------------------------------------------------------*/
(define-method (music-playlist-set! o::webmusic a1)
   (with-access::webmusic o (audioserver playlist %mutex %status)
      (synchronize %mutex
	 (with-access::musicstatus %status (playlistid playlistlength)
	    (set! playlistid (+fx playlistid 1))
	    (set! playlistlength (length a1)))
	 (with-access::audio-server audioserver (%event)
	    (audio-event-broadcast! %event (list 'cmdplaylistset a1))))))

;*---------------------------------------------------------------------*/
;*    music-playlist-clear! ::webmusic ...                             */
;*---------------------------------------------------------------------*/
(define-method (music-playlist-clear! o::webmusic)
   (with-access::webmusic o (audioserver playlist %mutex %status)
      (synchronize %mutex
	 (with-access::musicstatus %status (playlistlength)
	    (set! playlistlength 0))
	 (with-access::audio-server audioserver (%event)
	    (set! playlist '())
	    (audio-event-broadcast! %event (list 'cmdplaylistclear))))))

;*---------------------------------------------------------------------*/
;*    music-playlist-add! ::webmusic ...                               */
;*---------------------------------------------------------------------*/
(define-method (music-playlist-add! o::webmusic s::bstring)
   (with-access::webmusic o (audioserver playlist %mutex %status)
      (synchronize %mutex
	 (with-access::musicstatus %status (playlistid playlistlength)
	    (set! playlistid (+fx playlistid 1))
	    (set! playlistlength (+fx playlistlength 1)))
	 (with-access::audio-server audioserver (%event)
	    (set! playlist (append playlist (list s)))
	    (audio-event-broadcast! %event (list 'cmdplaylistadd s))))))

;*---------------------------------------------------------------------*/
;*    music-playlist-get ::webmusic ...                                */
;*---------------------------------------------------------------------*/
(define-method (music-playlist-get o::webmusic)
   (with-access::webmusic o (playlist)
      playlist))

;*---------------------------------------------------------------------*/
;*    music-play ::webmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-play o::webmusic . song)
   (with-access::webmusic o (audioserver)
      (with-access::audio-server audioserver (%event)
	 (audio-event-broadcast! %event (list 'cmdplay (if (pair? song) (car song) 0))))))

;*---------------------------------------------------------------------*/
;*    music-seek ::webmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-seek o::webmusic p . song)
   (with-access::webmusic o (audioserver)
      (with-access::audio-server audioserver (%event)
	 (audio-event-broadcast! %event (list 'cmdseek (cons p (if (pair? song) (car song) #f)))))))
   
;*---------------------------------------------------------------------*/
;*    music-stop ::webmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-stop o::webmusic)
   (with-access::webmusic o (audioserver)
      (with-access::audio-server audioserver (%event)
	 (audio-event-broadcast! %event (list 'cmdstop)))))

;*---------------------------------------------------------------------*/
;*    music-pause ::webmusic ...                                       */
;*---------------------------------------------------------------------*/
(define-method (music-pause o::webmusic)
   (with-access::webmusic o (audioserver)
      (with-access::audio-server audioserver (%event)
	 (audio-event-broadcast! %event (list 'cmdpause)))))

;*---------------------------------------------------------------------*/
;*    music-song ::webmusic ...                                        */
;*---------------------------------------------------------------------*/
(define-method (music-song o::webmusic)
   (with-access::webmusic o (%mutex %status)
      (synchronize %mutex
	 (with-access::musicstatus %status (song)
	    song))))

;*---------------------------------------------------------------------*/
;*    music-songpos ::webmusic ...                                     */
;*---------------------------------------------------------------------*/
(define-method (music-songpos o::webmusic)
   (with-access::webmusic o (%mutex playtime)
      (synchronize %mutex
	 (elong->fixnum (-elong (current-seconds) playtime)))))

;*---------------------------------------------------------------------*/
;*    music-volume-get ::webmusic ...                                  */
;*---------------------------------------------------------------------*/
(define-method (music-volume-get o::webmusic)
   (with-access::webmusic o (%mutex %status)
      (synchronize %mutex
	 (with-access::musicstatus %status (volume)
	    volume))))
   
;*---------------------------------------------------------------------*/
;*    music-volume-set! ::webmusic ...                                 */
;*---------------------------------------------------------------------*/
(define-method (music-volume-set! o::webmusic volume)
   (with-access::webmusic o (audioserver)
      (with-access::audio-server audioserver (%event)
	 (audio-event-broadcast! %event (list 'cmdvolume volume)))))
   
;*---------------------------------------------------------------------*/
;*    webmusic-ackstate! ...                                           */
;*---------------------------------------------------------------------*/
(define (webmusic-ackstate! o::webmusic s)
   (with-access::webmusic o (%mutex %status)
      (synchronize %mutex
	 (with-access::musicstatus %status (state)
	    (set! state s)))))

;*---------------------------------------------------------------------*/
;*    webmusic-ackplay! ...                                            */
;*---------------------------------------------------------------------*/
(define (webmusic-ackplay! o::webmusic s)
   (with-access::webmusic o (%mutex %status playlist playtime)
      (synchronize %mutex
	 (with-access::musicstatus %status (state song)
	    (set! playtime (current-seconds))
	    (set! state 'play)
	    (set! song s)))))

;*---------------------------------------------------------------------*/
;*    webmusic-ackvolume! ...                                          */
;*---------------------------------------------------------------------*/
(define (webmusic-ackvolume! o::webmusic vol)
   (with-access::webmusic o (%mutex %status)
      (synchronize %mutex
	 (with-access::musicstatus %status (volume)
	    (set! volume vol)))))

;*---------------------------------------------------------------------*/
;*    event caching ...                                                */
;*---------------------------------------------------------------------*/
(define event-mutex (make-mutex))

(define old-event #f)
(define old-value #f)

(define old-stamp 0)

(define old-events
   (let ((l (map (lambda (x)
		    (cons '(volume 0) 0))
		 (iota 5))))
      (set-cdr! (last-pair l) l)
      l))

;*---------------------------------------------------------------------*/
;*    audio-event-broadcast! ...                                       */
;*---------------------------------------------------------------------*/
(define (audio-event-broadcast! event value)
   (synchronize event-mutex
      (unless (and (eq? event old-event) (equal? value old-value))
	 (set! old-event event)
	 (set! old-value value)
	 (set! old-stamp (+fx 1 old-stamp))
	 (set-car! (car old-events) value)
	 (set-cdr! (car old-events) old-stamp)
	 (set! old-events (cdr old-events))
	 (hop-event-broadcast! event value))))

;*---------------------------------------------------------------------*/
;*    audio-event-poll ...                                             */
;*---------------------------------------------------------------------*/
(define (audio-event-poll stamp)
   (synchronize event-mutex
      (let ((l (filter (lambda (o) (> (cdr o) stamp)) (take old-events 5))))
	 (tprint "<<< audio-poll: " (map (lambda (e) (cons (caar e) (cdr e))) l))
	 l)))
   
