{ ======================================================================
test template for a rich edit control in a window; intended as use
for a "real time" data display, but ultimately unsuitable.

the code can force a rich control to overstrike, then force to have
an arbitrary number of lines so goto-xy can work (at least the
y part is worked out). however, the only character output mechanism
would be WM_CHAR because "insert" will insert whether overstrike
mode or not. could measure, select, then replace but SLOWER!

aarrgghh, sigh, i give up

rick vannorman 26apr2020 rick@neverslow.com
====================================================================== }

{ ======================================================================
suck in text for testing massive updates at speed
done here as a debug when using pad in the callback failed. callback
pad space isn't that large...
====================================================================== }

s" sample.txt" slurp value len value addr

4000 buffer: fooz

single nn

: abit   1 +to nn 
   addr nn 15 and  100 * +   3000 fooz zplace ;

{ ======================================================================
the derived-control makes putting a predefined window class in a
visible user window. the subclassing is automatic, and you
can take over whatever messages, etc. you want.

here is RICHEDIT50W subclassed...
====================================================================== }

Function: GetWindowTextLength ( hwnd -- len )

derived-control subclass mytextpane
   : mywindow_classname
      z" Msftedit.dll" loadlibrary drop
      z" RICHEDIT50W" ;
   : mywindow_style ( -- n )
      0 WS_TABSTOP OR
        WS_CHILD OR
        WS_VISIBLE OR
        WS_BORDER OR
        WS_VSCROLL or
        WS_HSCROLL or
        ES_MULTILINE or
        ES_AUTOVSCROLL or
        ES_AUTOHSCROLL or
        ;

   : font ( -- hfont )   lucida-console-12 CreateFont ;

   : sized-as-chars ( cols rows  -- )   
      >r charw  * dup to xsize  SM_CXVSCROLL GetSystemMetrics +  charw 2/ +
      r> charh  * dup to ysize  SM_CXHSCROLL GetSystemMetrics +  charh 2/ +
      sized ;

   single inserting

   : post-make ( -- )   xsize ysize sized-as-chars 1 to inserting
      mhwnd WM_KEYDOWN $2D $1520001 SendMessage drop 
   ;

   : resize-as-chars ( cols rows -- )
      sized-as-chars  x y xsize ysize resize ;

   : resize-from-pixels ( x y -- )   2drop ;

   : send ( msg wparam lparam -- res )   >r mhwnd -rot r> sendmessage ;

   : home ( -- )      EM_SETSEL 0 0 send drop ;
   : lines ( -- n )   EM_GETLINECOUNT 0 0 send 1- 0 max ;

   : length ( -- n )   mhwnd GetWindowTextLength ;

   WM_KEYDOWN message:
      wparam $2d = if
         inserting if  defproc  0 to inserting  then
      else defproc then ;

   : replace ( z -- )
      >r mhwnd EM_REPLACESEL 0 r> SendMessage drop ;

   : selall ( -- )
      mhwnd EM_SETSEL 0 -1 sendmessage drop ;

   : insert ( z -- )
      selall replace ;

end-class

{ ======================================================================
create a window to hold the richedit; always vector focus to richedit.
====================================================================== }

gui-framework subclass logwindow

   : MyClass_hbrBackground   COLOR_BTNFACE 1+ ;
   : MyAppName ( -- z )   z" Bravo Client" ;
   : MyWindow_Style        WS_OVERLAPPEDWINDOW WS_THICKFRAME or ;   

   mytextpane builds:id pane

   : place-children ( x y -- x y )
      2dup                pane        placed
      ;

   : init-widgets ( --  )
      mhwnd  80 24 z" localhost"    pane          make
      ;

   : init ( -- )   init-widgets   
      5 5 place-children  2dup to ysize  to xsize   resize-window
      mhwnd 99 100 0 settimer drop
      ;

   WM_SETFOCUS message: pane mhwnd SetFocus drop ;

   single nn
   WM_TIMER message:
      abit 
      fooz pane insert ;

end-class

{ ======================================================================
instantiate, construct, and test
====================================================================== }

single zz
single xdc
single xh

logwindow builds foo
: go foo construct   foo mhwnd to zz
   foo pane mhwnd to xh  foo pane hdc to xdc ;

: ndx-of ( n -- n )   xh EM_LINEINDEX rot 0 sendmessage ;
: goto-end ( -- )   xh EM_SETSEL -1 -1 SendMessage drop ;
: insert ( z -- )  >r xh EM_REPLACESEL 0  r> sendmessage drop ;
: set-caret ( ndx -- )   xh EM_SETSEL rot dup sendmessage drop ;
: selall     xh EM_SETSEL 0 -1 sendmessage drop ;
: killsel    xh EM_REPLACESEL 0 0 sendmessage drop ;
: page selall killsel ;
  
: lines foo pane lines ;

: goto-line ( n -- )
   lines 2dup >= if
      goto-end  2dup - 1+ 0 do z\" \n" insert  loop
   then  drop ndx-of set-caret ;

: sample
   0 set-caret  10 0 do  i z(.) insert z\" \n" insert loop ;

\ ======================================================================
\\ \\\\ 
\\\ \\\ 
\\\\ \\ 
\\\\\ \ 

xh EM_GETLINECOUNT . . sendmessage .  186 4589266 Stack underflow
xh EM_GETLINECOUNT 0 0 sendmessage .  1  ok
xh EM_GETLINECOUNT 0 0 sendmessage .  9  ok
xh EM_LINEFROMCHAR 4 0 sendmessage .  0  ok
xh EM_LINEFROMCHAR 14 0 sendmessage .  0  ok
xh EM_LINEFROMCHAR 24 0 sendmessage .  1  ok
xh EM_LINEFROMCHAR 14 0 sendmessage .  1  ok
xh EM_LINEFROMCHAR 24 0 sendmessage .  2  ok
xh EM_LINEFROMCHAR 10 0 sendmessage .  0  ok
xh EM_LINEFROMCHAR 11 0 sendmessage .  1  ok
xh EM_LINEFROMCHAR 50 0 sendmessage .  3  ok
xh EM_LINEFROMCHAR 5000 0 sendmessage .  9  ok
xh EM_SETSEL 0 0 sendmessage .  1  ok
xm EM_SCROLLCARET 0 0 sendmessage .  xm ?
xh EM_SCROLLCARET 0 0 sendmessage .  1  ok
xh EM_REPLACESEL 0 z" this" sendmessage .  1  ok
xh EM_REPLACESEL 0 z" that" sendmessage .  1  ok
xh EM_REPLACESEL 0 z\" \n" sendmessage .  1  ok
xh EM_REPLACESEL 0 z\" \n" sendmessage .  1  ok
xh EM_REPLACESEL 0 z\" \n" sendmessage .  1  ok
