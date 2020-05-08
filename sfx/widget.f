{ ========== widget.f ==================================================

Define the underpinnings of graphical widgets which can be used in a
windowed application. Each widget is a bitmap which can be drawn on,
and then rendered into its owner device context.

We need a colormap (8 bits for simplicity), an 8-bit dib manager,
and a surface to hang the widgets on. All are defined here.

The primary external use in this file is the class WIDGET which
is subclassed to define individual widgets.

(C) 2020 Rick VanNorman  -- rick@digital-sawdust.com
====================================================================== }

{ ----------------------------------------------------------------------
An array of 256 colors
---------------------------------------------------------------------- }

create default-colors   256 cells /allot

: 'default-color ( ndx -- addr )
   255 and cells default-colors + ;

{ ----------------------------------------------------------------------
fill an initial color table with sparse colors; these have the simple
characteristic that the lower-case letter represents the color. in the
128+ range, we have gradiants from red to yellow to green and back.

we assume that color 00 is background, and color 01 is foreground
for default text
---------------------------------------------------------------------- }

  ( backgnd)   $00000000        0      'DEFAULT-COLOR !
  ( foregnd)   $00ffffff        1      'DEFAULT-COLOR !

  ( blue   )   $000000FF   char b      'DEFAULT-COLOR !   \ fill in char=color
  ( cyan   )   $0000FFFF   char c      'DEFAULT-COLOR !
  ( green  )   $0000FF00   char g      'DEFAULT-COLOR !
  ( black  )   $00000000   char k      'DEFAULT-COLOR !
  ( magenta)   $00FF00FF   char m      'DEFAULT-COLOR !
  ( red    )   $00FF0000   char r      'DEFAULT-COLOR !
  ( white  )   $00FFFFFF   char w      'DEFAULT-COLOR !
  ( yellow )   $00FFFF00   char y      'DEFAULT-COLOR !
  ( grey   )   $007f7f7f   char e      'default-color !
  ( orange )   $00ffa500   char o      'default-color !
  ( purple )   $00a020f0   char p      'default-color !
  ( almond )   $00ffebcd   char a      'default-color !
  ( olive  )   $006B8E23   char v      'default-color !
  ( pink   )   $00FFC0C0   char n      'default-color !
  ( ltgrey )   $00F0F0F0   char l      'default-color !
  ( rose   )   $00ff80C0   char s      'default-color !

  ( red)       $00FF0000      128      'DEFAULT-COLOR !   \ gradiant
               $00FF1F00      129      'DEFAULT-COLOR !
               $00FF3F00      130      'DEFAULT-COLOR !
               $00FF5F00      131      'DEFAULT-COLOR !
               $00FF7F00      132      'DEFAULT-COLOR !
               $00FF9F00      133      'DEFAULT-COLOR !
               $00FFBF00      134      'DEFAULT-COLOR !
               $00FFDF00      135      'DEFAULT-COLOR !
   ( yellow)   $00FFFF00      136      'DEFAULT-COLOR !
               $00DFFF00      137      'DEFAULT-COLOR !
               $00BFFF00      138      'DEFAULT-COLOR !
               $009FFF00      139      'DEFAULT-COLOR !
               $007FFF00      140      'DEFAULT-COLOR !
               $005FFF00      141      'DEFAULT-COLOR !
               $003FFF00      142      'DEFAULT-COLOR !
               $001FFF00      143      'DEFAULT-COLOR !
   ( green)    $0000FF00      144      'DEFAULT-COLOR !
               $001FFF00      145      'DEFAULT-COLOR !
               $003FFF00      146      'DEFAULT-COLOR !
               $005FFF00      147      'DEFAULT-COLOR !
               $007FFF00      148      'DEFAULT-COLOR !
               $009FFF00      149      'DEFAULT-COLOR !
               $00BFFF00      150      'DEFAULT-COLOR !
               $00DFFF00      151      'DEFAULT-COLOR !
   ( yellow)   $00FFFF00      152      'DEFAULT-COLOR !
               $00FFDF00      153      'DEFAULT-COLOR !
               $00FFBF00      154      'DEFAULT-COLOR !
               $00FF9F00      155      'DEFAULT-COLOR !
               $00FF7F00      156      'DEFAULT-COLOR !
               $00FF5F00      157      'DEFAULT-COLOR !
               $00FF3F00      158      'DEFAULT-COLOR !
               $00FF1F00      159      'DEFAULT-COLOR !
   ( red)      $00FF0000      160      'DEFAULT-COLOR !

{ ----------------------------------------------------------------------
BITMAPINFOHEADER is a slightly different structure from the pre-existing
classes in SwiftForth. We add a few "set-" routines to protect the user
from the 16-bit variables and such.
---------------------------------------------------------------------- }

CLASS BITMAPINFOHEADER
   VARIABLE  Size
   VARIABLE  Width
   VARIABLE  Height
   HVARIABLE Planes
   HVARIABLE BitCount
   VARIABLE  Compression
   VARIABLE  SizeImage
   VARIABLE  XPelsPerMeter
   VARIABLE  YPelsPerMeter
   VARIABLE  ClrUsed
   VARIABLE  ClrImportant

   : SET-BITCOUNT ( n -- )   BitCount H! ;
   : SET-COMPRESSION ( n -- )   Compression ! ;
   : SET-PLANES ( n -- )   Planes H! ;
   : SET-SIZE ( -- )   BITMAPINFOHEADER SIZEOF Size ! ;
   : SET-HEIGHT ( n -- )   Height ! ;
   : SET-WIDTH ( n -- )   Width ! ;

END-CLASS

{ ----------------------------------------------------------------------
This is the container class for a simple bitmap info structure
---------------------------------------------------------------------- }

\ DEFER 'COLORMAP
\ ' COLORS IS 'COLORMAP

BITMAPINFOHEADER SUBCLASS 256COLOR-BITMAP

   256 CELLS BUFFER: COLORS

   : SET-COLORMAP ( '256-colormap -- )
      COLORS 256 CELLS CMOVE ;

   : SET-BMHEADER-DEFAULTS ( width height -- )
      ( w h) SET-HEIGHT   \ negative= top-down indexing
      ( w) SET-WIDTH
      BI_RGB SET-COMPRESSION
      8 SET-BITCOUNT
      SET-SIZE
      1 SET-PLANES
      DEFAULT-COLORS COLORS 256 CELLS CMOVE ;

   : @RGB ( index -- rrggbb )
      255 and  cells  colors +
      count 16 lshift swap count 8 lshift  swap c@  or or ;



END-CLASS

{ ----------------------------------------------------------------------
The 8bit-dib class gives us a canvas to draw on.  It is mapped into
system memory for quick direct access -- write a byte and it represents
a pixel.

The class manages x,y coordinates by knowing the xsize and ysize
dimensions of the instantiated DIB.  These are set by CREATE and may not
be changed afterwards.

Methods provided are DOT to plot points, RENDER to
draw it on a device context.

SET-ORIGIN sets TOP and LEFT, which control where in the destination
device context the DIB will be rendered.

This DIB can be DISPLAY-ed onto any window's device context (dc).

in use:
   8bit-dib builds foo
   x y foo create-dib
   dc foo connect
   foo render
---------------------------------------------------------------------- }

CLASS 8BIT-DIB

   SINGLE hDC           \ handle to this bitmap dc
   SINGLE SCREEN        \ pointer to dib memory, pixels you can write
   SINGLE hBITMAP       \ handle to the bitmap object where SCREEN lives
   SINGLE oBITMAP       \ handle to prev bitmap for restore at close

   SINGLE XSIZE         \ must be set; max size of bitmap x   REQUESTED
   SINGLE YSIZE         \ max size of bitmap y                SIZE

   SINGLE XREAL         \ DIB lines are quad-aligned,

   SINGLE OwnerDC       \ handle of dc to draw on
   SINGLE |SCREEN|
   SINGLE |BMP|

   SINGLE 'BMP          \ a memory pool for creating the snapshot

   SINGLE COLORMAP      \
   single bg
   single fg

   256COLOR-BITMAP BUILDS PINFO  \ this contains the bitmap header info

   \ attach with no parameters; be sure to detach

   : DESTROY-DIB ( -- )   hBITMAP IF
         hDC oBITMAP SelectObject DROP
         hBITMAP DeleteObject DROP
         hDC DeleteObject DROP
         'bmp free drop
      THEN  0 TO hBITMAP 0 TO OwnerDC ;

   : create-dib ( x y -- )   \ if y is negative, the bitmap is top-down addressing
      pinfo construct  destroy-dib  ( x y) to ysize  to xsize
      xsize 3 + -4 and to xreal  \ quad aligned
      0 CreateCompatibleDC to hdc
      xsize ysize pinfo set-bmheader-defaults
      colormap if  colormap pinfo set-colormap  then
      hdc pinfo addr DIB_RGB_COLORS  &of screen 0 0
         createdibsection to hbitmap  ( allocate the screen buffer)
      hdc hbitmap SelectObject to obitmap
      hdc black setTextColor drop
      hdc white SetBkColor drop
      hDC  ANSI_FIXED_FONT GetStockObject  SelectObject DROP
      0 TO OwnerDC
      XREAL YSIZE * TO |SCREEN|
      256color-bitmap sizeof |screen| + 14 + to |bmp|
      |bmp| cell+ allocate if drop exit then to 'bmp ;

   : CONNECT ( dc -- )   TO OwnerDC ;

   \ ----------------------------------------------------------------------
   \ manage the display resources of the bitmap. assumes we have been
   \ connected and allocated

   : render-dib ( dc x y wide high -- )   fifth if
         hdc 0 0 SRCCOPY BitBlt drop  exit
      then 5 discard ;

   : flood ( colorndx -- )   dup to bg   screen |screen| rot fill ;

   : blackness ( -- )   $ff flood ;
   : whiteness ( -- )     1 flood ;

   : render-at ( x y -- )   ownerdc rot rot xsize ysize RENDER-DIB ;
   : render ( -- )   0 0 render-at ;

   : @color ( index -- rgb )   pinfo @rgb ;

   : print-xy-color ( x y addr len color -- )
      hdc  swap pinfo @rgb  SetTextColor >R
      hdc  bg pinfo @rgb  SetBkColor >r
      2>r 2>r  hdc  2r> 2r>  TextOut drop
      hdc r> SetBkColor drop
      hdc r> SetTextColor drop ;

   : print-xy ( x y addr len -- )   fg print-xy-color ;

   : set-fg ( ndx -- )   to fg ;

{ ----------------------------------------------------------------------
drawing pixels on the dib, as xy coordinates
the natural quarterplane is intuitive; the native dib quarterplane isn't
(at least to me!)

      dib quarterplane        natural quarterplane
      +-----------------+     +-----------------+
      |0,99       199,99|     |0,0         199,0|
      |                 | <== |                 |
      |0,0         199,0|     |0,99       199,99|
      +-----------------+     +-----------------+

POINT ( x y color -- )   is native dib quarterplane mapping
DOT   ( x y color -- )   is natural quarterplane mapping
---------------------------------------------------------------------- }

   : screen-c! ( n offset -- )   0 max  |screen| 1- min  screen + c! ;

   : point ( x y color -- )
      rot xsize 1- umin  rot ysize 1- umin  xreal *  +  screen-c! ;

   : dot ( x y color -- )
      ysize 1- rot -  xreal *  rot  +   screen-c! ;

end-class

{ ======================================================================

define some standard fonts for easy use in the widget class

====================================================================== }

: terminal-5     -7 0 0 0 400 0 0 0 255 1 2 1 49 z" Terminal"  ;
: terminal-6     -8 0 0 0 400 0 0 0 255 1 2 1 49 z" Terminal"  ;
: terminal-9    -12 0 0 0 400 0 0 0 255 1 2 1 49 z" Terminal"  ;
: terminal-12   -16 0 0 0 400 0 0 0 255 1 2 1 49 z" Terminal"  ;
: terminal-12B  -16 0 0 0 800 0 0 0 255 1 2 1 49 z" Terminal"  ;
: terminal-14   -19 0 0 0 400 0 0 0 255 1 2 1 49 z" Terminal"  ;
: terminal-14B  -19 0 0 0 800 0 0 0 255 1 2 1 49 z" Terminal"  ;
: terminal-20B  -26 0 0 0 800 0 0 0 255 1 2 1 49 z" Terminal"  ;

: lucida-console-7    -8 0 0 0 400 0 0 0 0 3 2 1 49 z" Lucida Console" ;
: lucida-console-8   -11 0 0 0 400 0 0 0 0 3 2 1 49 z" Lucida Console" ;
: lucida-console-9   -12 0 0 0 400 0 0 0 0 3 2 1 49 z" Lucida Console" ;
: lucida-console-9b  -12 0 0 0 800 0 0 0 0 3 2 1 49 z" Lucida Console" ;
: lucida-console-10  -14 0 0 0 400 0 0 0 0 3 2 1 49 z" Lucida Console" ;
: lucida-console-10b -14 0 0 0 800 0 0 0 0 3 2 1 49 z" Lucida Console" ;
: lucida-console-12  -16 0 0 0 400 0 0 0 0 3 2 1 49 z" Lucida Console" ;
: lucida-console-14  -19 0 0 0 400 0 0 0 0 3 2 1 49 z" Lucida Console" ;
: lucida-console-24  -34 0 0 0 400 0 0 0 0 3 2 1 49 z" Lucida Console" ;

{ ======================================================================

A "drawing surface" using the 8BIT-DIB class.

====================================================================== }

class widget

   8bit-dib builds image
   textmetric builds tm         \ windows structure for getting charsize

   single hdc           \ handle of the device context to draw on
   single parent
   single hfont         \ hold a font handle

   single x             \ where in the device context to
   single y             \ actually draw the image
   single xsize         \ size to draw
   single ysize         \

   single charh                 \ size of a character in pixels
   single charw                 \ varies by which font chosen

   single hide-borders

   257 buffer: name

   2 constant margin            \ on any given side
   margin 2* constant border    \ non-image area

   : set-parent ( hwnd -- )   to parent ;
   : set-name ( addr len -- )   name place  0 name count + c! ;
   : named ( addr len -- )   set-name ;

   : measure ( hdc -- )         \ measure the chars in the dc
      tm addr GetTextMetrics drop
      tm height @ to charh
      tm avecharwidth @ to charw ;

   : fg ( -- colorndx )   image fg ;
   : bg ( -- colorndx )   image bg ;

   : set-fg ( colorndx -- )   image to fg ;
   : set-bg ( colorndx -- )   image to bg ;

{ ----------------------------------------------------------------------
print a string, in color if desired
---------------------------------------------------------------------- }

   : print-xy ( x y addr len -- )   image print-xy ;
   : cprint-xy  ( x y addr len color -- )   image print-xy-color ;

   : emit-xy ( x y char -- )   >r  rp@ 1 print-xy  r> drop ;
   : cemit-xy ( x y char color -- )   swap >r  rp@ 1 rot cprint-xy  r> drop ;

   : title ( z -- )   0 0 rot zcount print-xy ;

{ ----------------------------------------------------------------------
Draw lines and points, etc on the surface
---------------------------------------------------------------------- }

   : point ( x y colorndx -- )   image point ;     \ image references
   : dot   ( x y colorndx -- )   image dot ;       \ in local context
   : flood ( colorndx -- )   image flood ;

   : vertical-line ( x color -- )
      ysize 0 do  over i third point  loop  2drop ;

   : horizontal-line ( y color -- )
      xsize 0 do  i third third  point  loop  2drop ;

   : dashed-vertical-line ( x color -- )
      ysize 0 do  over i third point  4 +loop  2drop ;

   : dashed-horizontal-line ( y color -- )
      xsize 0 do  i third third  point  4 +loop  2drop ;

   : borders ( -- )
      hide-borders ?exit
      0 fg horizontal-line  ysize 1- fg horizontal-line
      0 fg vertical-line    xsize 1- fg vertical-line ;


{ ----------------------------------------------------------------------
signed 16 bit value; scale to unsigned range of 0 .. wide (or high)
32768 + $ffff and  65536 high */
---------------------------------------------------------------------- }

   : xscaled ( n -- n )   32768 + $ffff and xsize * hiword ;
   : yscaled ( n -- n )   32768 + $ffff and ysize * hiword ;

   : scaled-point ( x y color -- )
      rot xscaled  rot yscaled  rot point ;

{ ----------------------------------------------------------------------
decide if the x,y coordinate, in target dc, is contained by the surface
---------------------------------------------------------------------- }

   : clicked? ( x y -- x y bool )
      2dup  y dup ysize + rot within >r
            x dup xsize + rot within r> and ;

   : hover? ( x y -- x y bool )   clicked? ;

{ ----------------------------------------------------------------------
manage fonts for our image
---------------------------------------------------------------------- }

   : set-font ( hfont -- )   to hfont
      image hdc  hfont  selectobject   drop
      image hdc measure ;

   defer: font ( -- hfont )   lucida-console-12 CreateFont ;

{ ----------------------------------------------------------------------
create the drawing surface, select the default font
also dispose of the drawing surface
---------------------------------------------------------------------- }

   : create-surface ( x0 y0 cx cy hfont hdc -- )
      to hdc  to hfont  to ysize  to xsize  to y  to x
      xsize ysize image create-dib  hdc image connect
      image whiteness  hfont set-font ;

   : create ( x y dc -- )
      >r -1 -1 2swap   font    r> create-surface ;

   : destroy-dib ( -- )   image destroy-dib ;

   : resize ( x y -- )   destroy-dib
      x y 2swap hfont hdc create-surface ;

   : widen ( x-left-abs -- )   destroy-dib
      x y rot third - ysize  hfont hdc  create-surface ;

{ ----------------------------------------------------------------------
These deferred function allow subclasses to control drawing the borders
and such.
---------------------------------------------------------------------- }

   defer: draw-static-elements ( -- ) borders  ;
   defer: draw-data-elements   ( -- )   ;
   defer: reset-data-elements  ( -- )   ;

{ ----------------------------------------------------------------------
draw the image from its native memory bmp onto the target dc
---------------------------------------------------------------------- }

   : render ( -- )   x y  image render-at  ;
   : redraw ( -- )   draw-static-elements draw-data-elements  render  ;
   : update ( -- )   x 0< ?exit  redraw ;
   : clear ( -- )   image whiteness ;

   : no-border ( -- )   1 to hide-borders ;

{ ----------------------------------------------------------------------
control placement of surface objects
---------------------------------------------------------------------- }

   : ul ( -- x y )   x y ;
   : ur ( -- x y )   x xsize + border + y ;
   : lr ( -- x y )   x xsize + border +  y ysize + border + ;
   : ll ( -- x y )   x y ysize + border + ;

   : below ( -- x y )   ll ;
   : beside ( -- x y )   ur ;

   \ x and y are where you were told to be
   \ maxes are max of both values

   : placed ( xmax ymax x y -- xmax ymax )
      to y to x  lr rot max >r  max r>
      xsize ysize  resize ;

end-class
