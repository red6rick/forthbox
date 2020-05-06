{ ----------------------------------------------------------------------
build a printable buffer of formatted output. the biggest restriction
is that the tags are the minimum size for the output; this is also
a strength because it means you can create text output of guaranteed
text representation.

in the template, the patterns  indicate where
to insert an output. the only significant things are that each
pattern is unique, and that it reserves enough space in the template
for the desired output. the formatted text will be
written into the tempate from the beginning of the matched string,
and will OVERWRITE any text necessary following. 

The example following will show how to use these functions.

Rick VanNorman   6May2020  rick@neverslow.com
---------------------------------------------------------------------- }

{ ----------------------------------------------------------------------
a template builder. the item insertion and format indicators
MUST be unique. any string will do. 
---------------------------------------------------------------------- }

: add-string ( addr len -- )
   r-buf  r@ place  here  r@ c@ allot  r> count rot swap cmove ;

: +| ( <string> -- )
   [char] | parse add-string   s\" \n" add-string ;

{ ----------------------------------------------------------------------
build a display list; the template is carried on the stack
for the duration of the build and is dropped at the end. the list
is terminated by a zero (null). DISPLAY-ITEM is the list builder

N       is the index into the "%xx" strings in the template
ITEM    is any forth executable function
FORMAT  is any forth function to act on the result of the ITEM
        and produce a string (addr len) to be inserted into
        the output string
        
         display-item  <pattern>  <item>   <formatter>
In use:  display-item  %1         @time    (time)

---------------------------------------------------------------------- }

: display-item ( template  <parameters> -- template )
   dup zcount  tuck bl word count search if
      ' , ' ,  nip - ,  
   else 2drop drop  then ;

{ ----------------------------------------------------------------------
FORMAT-OUTPUT makes a copy of the desired output template in
a return-stack allocated buffer, formats the data into it, then
puts the result back at PAD in the current context
---------------------------------------------------------------------- }

: format-output ( ref -- addr len )
   zcount 2dup dup 2* r-alloc dup >r xplace r> locals| buf |
   + cell+ ( list) begin
      dup @
   while
      >r
      r@+ execute            \ get a value
      r@+ execute            \ format the data, leaving addr len
      r@+ buf cell+ +        \ where in buf to place string
      swap cmove             \ place it
      r>
   repeat drop  buf @+ pad xplace  pad @+ ;
   
\ ----------------------------------------------------------------------
1 [if]

    99 value aaa
112233 value bbb

: (8u.r)   ( n -- addr len )   8 (u.r) ;

create sample-template   

here
   +| the sample output template showing fomatted data
   +| note that the trailing vertical bar is only used
   +| to guarantee the length of the line if formatted
   +| data is the last item on the line. if normal text
   +| follows the formatted data it is optional, as
   +| it is on all other lines
   +| 
   +|   aaa =  %x_____  is the value of aaa
   +|   bbb =  %02xxxx  the bbb value
   +|  time =  %aa      date =  !!........|
   +| 
   +| the date field "reserved" more      
   +| horizontal space than needed with dots
   +| and note that the lines don't have to be of
   +| equal length; the trailing bar just allows
   +| you to guarantee enough room for your data
0 ,  

   display-item %x      aaa                 (8u.r)
   display-item %02     bbb                 (8u.r)
   display-item %aa     @time               (time)
   display-item !!      @date               (date)

drop 0 ,

: showme ( -- )
   sample-template format-output  cr cr types cr cr ;
   
[then]

