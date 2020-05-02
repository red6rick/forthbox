{ ----------------------------------------------------------------------
command management; what you can do with a buffer

Rick VanNorman  30Apr2020  rick@neverslow.com
---------------------------------------------------------------------- }

\ ========== gap stuff =================================================

: ptr ( offset -- buffer-addr )
   dup 0< if  drop  'buf exit  then
   'buf +  dup 'gap < ?exit   'egap 'gap - + ;
   
\ ======================================================================

   \ reverse scan for start of logical line containing offset
   : line-start ( offset -- point )
      begin
         1- dup ptr
         




: quit ( -- ) ;
: up ( -- ) ;
: down ( -- ) ;
: lnbegin ( -- ) ;
: version ( -- ) ;
: top ( -- ) ;
: bottom ( -- ) ;
: block ( -- ) ;
: copy ( -- ) ;
: cut ( -- ) ;
: resize_terminal ( -- ) ;

: redraw ( -- )   ;   \ redraw all windows...

: left ( -- ) using atom-buffer  curbuf left ;
: right ( -- ) using atom-buffer  curbuf right ;
: line-end ( -- ) using atom-buffer  curbuf line-end ;
: line-begin ( -- )   using atom-buffer  curbuf line-begin
: wleft ( -- ) using atom-buffer  curbuf wleft ;
: wright ( -- ) using atom-buffer  curbuf wright ;
: pgdown ( -- ) using atom-buffer  curbuf pgdown ;
: pgup ( -- ) using atom-buffer  curbuf pgup ;
: insert ( -- ) using atom-buffer  curbuf insert ;
: backsp ( -- ) using atom-buffer  curbuf backsp ;
: delete ( -- ) using atom-buffer  curbuf delete ;


: gotoline ( -- ) ;
: insertfile ( -- ) ;
: readfile ( -- ) ;
: savebuffer ( -- ) ;
: writefile ( -- ) ;
: killbuffer ( -- ) ;
: iblock ( -- ) ;
: toggle-overwrite ( -- ) ;
: killtoeol ( -- ) ;
: copycut ( -- ) ;
: paste ( -- ) ;
: showpos ( -- ) ;
