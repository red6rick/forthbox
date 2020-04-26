{ ----------------------------------------------------------------------
threadmon is a window which can accept "console" output from a
background thread which has set its personality vector to it. this
allows a normal console app in swiftforth to run in a thread but still
have somewhere to dump messages and such.

the window must be constructed in a thread which has a message
loop -- the thread to be monitored need not have one.
the invoke method checks for the existence of the window, and
spawns yet another thread which does have a message loop if
the window does not exist.

Rick VanNorman  26Apr2020  rick@neverslow.com
---------------------------------------------------------------------- }

requires fork

Function: IsWindow ( hwnd -- bool )

gui-framework subclass threadmon
   : MyAppName ( -- z )   z" ThreadMonitor" ;
   : MyWindow_Style ( -- style )
      WS_SYSMENU  WS_BORDER OR  WS_POPUP OR  WS_CAPTION OR
      WS_MINIMIZEBOX OR WS_THICKFRAME OR ;
   : MyWindow_Shape ( -- x y cx cy )   100 100 600 400 ;
   
   myrichbox builds richie
   defer: text-size ( -- x y )   80 24 ;
   : place-children ( x y -- X Y )
      2dup richie placed ;
   : create-children ( -- )
      mhwnd text-size 0 richie make ;   
   : init ( -- )
      create-children 
      5 5 place-children
      2dup to ysize  to xsize   resize-window ;
   WM_SETFOCUS message: richie mhwnd SetFocus drop ;

   : type ( addr len -- )   richie type ;
   : page ( -- )   richie page ;
   : emit ( char -- )   richie emit ;
end-class

threadmon builds tmon

\ ----------------------------------------------------------------------
\ define a personality to use the threadmon

: tmon-type     tmon type ;
: tmon-emit     tmon emit ;
: tmon-page     tmon page ;
: tmon-cr       s\" \n" tmon-type ;

: tmon-creator ( -- )
   forks>  tmon construct  dispatcher drop ;

: tmon-invoke
   phandle IsWindow not if
      tmon-creator to drop  tmon mhwnd personality-handle !
   then  phandle SW_SHOW ShowWindow drop ;

create tmon-personality
        16 ,        \ datasize                    \
        19 ,        \ maxvector                   \
         0 ,        \ personality-handle          \
         0 ,        \ previous                    \
   ' tmon-invoke ,  \ invoke    ( -- )            \ 
   ' noop ,         \ revoke    ( -- )            \
   ' noop ,         \ /input    ( -- )            \ do nothing
   ' tmon-emit ,    \ emit      ( char -- )       \ methods of class
   ' tmon-type ,    \ type      ( addr len -- )   \
   ' tmon-type ,    \ ?type     ( addr len -- )   \
   ' tmon-cr ,      \ cr        ( -- )            \
   ' tmon-page ,    \ page      ( -- )            \
   ' drop ,         \ attribute ( n -- )          \ 
   ' bl ,           \ key       ( -- char )       \ reasonable defaults
   ' true ,         \ key?      ( -- flag )       \
   ' bl ,           \ ekey      ( -- echar )      \
   ' true ,         \ ekey?     ( -- flag )       \
   ' bl ,           \ akey      ( -- char )       \
   ' 2drop ,        \ pushtext  ( addr len -- )   \
   ' 2drop ,        \ at-xy     ( x y -- )        \
   ' 2dup ,         \ at-xy?    ( -- x y )        \
   ' 2dup ,         \ get-size  ( -- x y )        \
   ' = ,            \ accept    ( addr u1 -- u2 ) \ returns zero!

: use-tmon ( -- )   'personality @ ?exit  
   tmon-personality 'personality !  invoke ;

\ ----------------------------------------------------------------------
\ an example of using the thread monitor

: testing ( -- )
   begin @time (time) tmon-type tmon-cr 1000 sleep  again ;

: tmon-test
   forks>   use-tmon     ['] testing catch ;




