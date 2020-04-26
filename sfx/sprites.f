{ ========== sprites.f =================================================
  (C) 2020 Stratolaunch LLC ---- 24Feb2020 rcw/rcvn

  Many old-fashioned arcade games used sprites for animation. Think of
  PACMAN running around a maze. The concept is useful for composing
  graphic elements for a display in Windows. The Windows operating
  system provides many tools for dealing with graphics, but they are
  low-level. Our extension `swiftforth\sfx\sprites.f` puts a wrapper
  around some of these to allow simpler use of graphics in the
  RocSimBravo application.

  This class uses the simplest graphics model for the sprite images,
  a 24-bit-color uncompressed BMP file. The image in the file can be
  thought of as a comic strip, composed of panes from left to right.
  Each pane is square, as wide as tall. The strip will consist of
  some number of sprites, numbered from 0 through n-1.

  A sprite object is instantiated by `bmp-sprites builds test`

  `set-bmp` connects the object to an in-memory bitmap image, 
  measures its size, and determines how many sprites are in it. Do
  this before attaching a device context.

  `attach` connects an existing device context (think: canvas) to the
  created object on which the sprites will be drawn. This is required
  so the drawing code can render the images correctly. Do this after
  set-bmp.

   `draw-sprite` will render the indicated sprite on the indicated
   device context at the indicated x,y coordinate.

   `and-sprite` is just like `draw-sprite` but the raster operation
   performed is `AND` -- which means that anything black in the sprite
   will be black in the final image. This lets the user mask part of
   the display image for a later operation.

   `or-sprite` is just like `and-sprite` but uses `OR` which means
   that anything white in the sprite will not alter the display image.

====================================================================== }

class bmp-sprites       \ define a class container for sprites

   single 'bmp          \ the address in memory of the bitmap image
   single height        \ actual height 
   single width         \ and width of the full bitmap
   single sx            \ sprite x and
   single sy            \ y size
   single #sprites      \ how many
   single sxerr         \ if width isn't a multiple of height
   single hdc           \ device context for sprites
   single hbitmap       \ handle of the 
   single target-dc     \ destination device context
   
   : measure ( 'bmp -- )   ?dup -exit
      [objects bitmapheader names bm objects]
      bm height @  dup to height  dup to sy  to sx
      bm width @  dup to width  sy /mod  to #sprites  to sxerr ;

   \ init the resources for drawing
   
   : emplace-bitmap-data ( -- )      
      [objects bitmap makes bm objects]
      'bmp hdc 0 0 bm draw ( copy into hbitmap) ;

   : attach ( dc -- )   
      ( dc) to target-dc  
      target-dc CreateCompatibleDC  to hdc       
      target-dc width height CreateCompatibleBitmap  to hbitmap
      hdc hbitmap SelectObject drop
      emplace-bitmap-data ;

   : dot ( -- )
      #sprites . ." sprites of " sx . sy . ." at " 'bmp h.  height . width . sxerr . ;

   : 'sprite ( n -- cx cy )   0 max  #sprites 1- min  sx * 0 ;

   : blt-sprite ( dc x y sprite rop -- )
      >r  >r  sx sy  hdc  r> 'sprite  r> BitBlt drop ;

   : draw-sprite ( dc x y sprite -- )   SRCCOPY  blt-sprite ;
   : and-sprite  ( dc x y sprite -- )   SRCAND   blt-sprite ;
   : or-sprite   ( dc x y sprite -- )   SRCPAINT blt-sprite ;

   : set-bmp ( addr -- )   dup to 'bmp  measure ;

end-class

\ ======================================================================
\\ \\\\ a simple example using the bmp-sprites class
\\\ \\\ it depends on a "strip" of 5 images, each 512x512 pixels
\\\\ \\ named "horizon.bmp"
\\\\\ \ 


\ first, read the image into memory and name it "test" 

s" horizon.bmp" bmp test-image

\ create a sprite object named my-sprites

bmp-sprites builds my-sprites

\ set my-sprites image pointer to test-image

test-image my-sprites set-bmp

\ get the device context of the swiftforth console window

phandle getdc constant dc

\ inform my-sprites about it

dc my-sprites attach

\ define a function to show composition with sprites

: test
   dc 0 0 3 my-sprites draw-sprite key drop  \ show the ground grid
   dc 0 0 2 my-sprites and-sprite  key drop  \ mask, leave only center
   dc 0 0 4 my-sprites or-sprite   key drop  \ overlay the outer ring
   dc 0 0 0 my-sprites and-sprite  key drop  \ mask, leave center and ring
   dc 0 0 1 my-sprites or-sprite   key drop  \ overlay the "airplane"
   ;
   
