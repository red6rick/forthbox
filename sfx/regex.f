{ ----------------------------------------------------------------------
Very simple regular expression search
(c) 2014 rick vannorman

Modelled after Kernighan and Pike, in "The Practice of Programming"

Regular expressions require co-routine recursion. There isn't an easy
way in Forth, so a pair of DEFER definitions will do.
---------------------------------------------------------------------- }

DEFER MATCHSTAR
DEFER MATCHHERE

\ matchstar: search for c*regexp at beginning of text

: (MATCHSTAR) ( char zreg ztext -- flag )
   ROT >R BEGIN
      2DUP MATCHHERE IF  2DROP  R> DROP   -1 EXIT  THEN
      DUP C@ WHILE
      COUNT R@ =  R@ [CHAR] . = or 0=
   UNTIL THEN  2DROP R> DROP  0 ;
   


\ matchhere: search for regexp at beginning of text

: (MATCHHERE) ( zreg ztext -- flag )
   OVER C@ 0= IF  2DROP -1  EXIT THEN           \ regex[0] is null
   OVER 1+ C@ [CHAR] * = IF                     \ regex[1] == "*"
      OVER C@  ROT 2+  ROT  MATCHSTAR           \ ch 'reg[2] 'text
      EXIT  THEN                                \
   OVER C@ [CHAR] $ =  THIRD 1+ C@ 0=  AND IF   \ reg = "$\0"
      NIP C@ 0=  EXIT THEN                      \ matches if text = "\0"
   DUP C@ IF                                    \ text <> "0"  --and--
      OVER C@ [CHAR] . =                        \   ( reg[0] = "." --or--
      THIRD C@ THIRD C@ = OR IF                 \     reg[0] = text[0]    )
         1+ SWAP 1+ SWAP MATCHHERE EXIT
      THEN
   THEN
   2DROP 0 ;

' (MATCHSTAR) IS MATCHSTAR
' (MATCHHERE) IS MATCHHERE

: MATCHRX ( zreg ztext -- zmatch )
   OVER C@ [CHAR] ^ = IF                        \ special case for ^
      SWAP 1+ OVER MATCHHERE  0<> AND           \ only match beginning
      EXIT THEN                                 \
   BEGIN                                        \ normally, walk through
      2DUP MATCHHERE IF  NIP EXIT  THEN         \ the text looking for a match
      COUNT 0=                                  \ one char at a time until
   UNTIL 2DROP 0 ;                              \ the text string is exhausted


{ ======================================================================
pattern matching on file images
====================================================================== }

\ ----------------------------------------------------------------------
\ hunt for a line containing the needle.
\ returns addr:len of haystack after the line that matched
\ and the line:len of line that matched
\ searches one line at a time, so matchrx can work magic
\ the haystack does not need null termination, since we pick
\ out a line at a time
\
\ NOTE THAT BECAUSE GET-NEXT-LINE TRIMS LEADING AND TRAILING
\ BLANKS, THE RX FOR HUNT AND FINDRX CANNOT SEARCH FOR LINES
\ THAT BEGIN OR END WITH SPACES. NOT IMPORTANT FOR THIS
\ APPLICATION, BUT GENERALLY SHOULD NOT BE USED

: hunt ( haystack len needle len -- HAYSTACK LEN matchline len )
   r-buf  r@ zplace  begin
      dup 0> while
      get-next-line 2dup pad zplace
      r@ pad matchrx if
         r> drop exit
      then 2drop
   repeat r> drop 2dup ;

: -hunt ( haystack len needle len -- HAYSTACK LEN matchline len )
   r-buf  r@ zplace  begin
      dup 0> while
      get-next-line 2dup pad zplace
      r@ pad matchrx 0= if
         r> drop exit
      then 2drop
   repeat r> drop 2dup ;

\ findrx looks for a needle in a haystack, returning the
\ location of the match found...

: findrx ( haystack len needle len -- HAYSTACK LEN )
   2over 2swap hunt drop nip nip third - /string ;

: -findrx ( haystack len needle len -- HAYSTACK LEN )
   2over 2swap -hunt drop nip nip third - /string ;

: find-line ( haystack len pattern len -- line len )
   findrx this-line ;

: find-tag ( haystack len pattern len -- line len )
   find-line  get-next-word 2drop  trim ;

: split-string ( haystack len pattern len -- HAYSTACK LEN haystack LEN2 )
   fourth >r  findrx  get-next-line  2drop  r> third over - ;

{ ======================================================================
given a line of text with arbitrary spacing, repack into a string
at the destination with single spaces between the words. return
the number of words on the line
====================================================================== }

: pack ( addr len dest -- n )
   0 over c!  0 >r begin
      >r get-next-word dup 0> while
      r@ c@ if s"  " r@ append then  r@ append  r>
   r++  repeat 2drop 2drop  r> drop r> ;

{ ======================================================================
in a text buffer, skip any blank lines and return the remainder of
the buffer
====================================================================== }

: skip-blank-lines ( addr len -- addr len )
   begin
      dup 0> while
      2dup get-next-line trim nip if 2drop exit  then
      2nip
   repeat ;

{ ======================================================================
count the lines in a buffer
====================================================================== }

: #lines ( addr len -- n )
   0 >r begin dup 0> while r++ get-next-line 2drop repeat 2drop r> ;


\ ----------------------------------------------------------------------
\\ \\\\ a little testing never hurt!
\\\ \\\ 
\\\\ \\ 
\\\\\ \ 


: z= ( z z -- flag )   zcount rot zcount compare 0= ;

: x? .s #tib 2@ type space ;

x? z" a*bc"         z" aaaaabcdef" matchrx z" aaaaabcdef" z= .
x? z" abc"          z" aaaaabcdef" matchrx z" abcdef"     z= .
x? z" .bc"          z" aaaaabcdef" matchrx z" abcdef"     z= .
x? z" a.c"          z" aaaaabcdef" matchrx z" abcdef"     z= .
x? z" ab."          z" aaaaabcdef" matchrx z" abcdef"     z= .
x? z" .*bc"         z" aaaaabcdef" matchrx z" aaaaabcdef" z= .
x? z" ^a*bc"        z" aaaaabcdef" matchrx z" aaaaabcdef" z= .
x? z" ^.*bc"        z" aaaaabcdef" matchrx z" aaaaabcdef" z= .
x? z" ^aaaa*bc"     z" aaaaabcdef" matchrx z" aaaaabcdef" z= .
x? z" ^aaaaa*bc"    z" aaaaabcdef" matchrx z" aaaaabcdef" z= .
x? z" ^aaaaaa*bc"   z" aaaaabcdef" matchrx z" aaaaabcdef" z= .
x? z" ^aaaaaaa*bc"  z" aaaaabcdef" matchrx                0= .
x? z" abc"          z" aaaaabcdef" matchrx z" abcdef"     z= .
x? z" abc$"         z" aaaaabcdef" matchrx                0= .
x? z" abcd$"        z" aaaaabcdef" matchrx                0= .
x? z" abcde$"       z" aaaaabcdef" matchrx                0= .
x? z" abcdef$"      z" aaaaabcdef" matchrx z" abcdef"     z= .
x? z" abcde.$"      z" aaaaabcdef" matchrx z" abcdef"     z= .
x? z" ^.*abcde.$"   z" aaaaabcdef" matchrx z" aaaaabcdef" z= .
x? z" ^a*abcde.$"   z" aaaaabcdef" matchrx z" aaaaabcdef" z= .


