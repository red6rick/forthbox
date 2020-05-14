
\ ========== test buffer ptr function re: gap ==========================

oop +order

: 'member-xt ( <name> -- xt )
   'member 0= abort" member undefined"
   class-member? 0= abort" not member of class"
   3 cells + @ ;
   
: ['member-xt] ( <name> -- )   
   'member-xt postpone literal ; immediate
   
previous


\ ======================================================================

include datamon

atom-buffer reopen

   datamon builds mon

   : neighbor ( -- addr len )
      link @ if
         link @  bname link -  +  count
      else s" <>" then ;
         
   \ ----------------------------------------------------------------------
   \ simple buffer gap display
   \ |xxxxxxyy|.................|yyyyyyyyyyy|
   
   : %gapage ( buf gap egap ebuf width -- )
      0 locals| step w ebuf egap gap buf |
      ebuf buf - w / to step
      buf  w 0 do
         dup  gap < if [char] x  else
         dup egap < if [char] .  else
                       [char] y  then then
         %emit step +
      loop drop ;
   
   : (gapage) ( buf gap egap ebuf width -- addr len )
      <% %gapage %> ;

   : info ( -- addr len )
      <% 
         %" bname  " bname count %type %cr
         %" fname  " fname count %type %cr
         %" next   " neighbor  %type %cr
         %" flags  " flags 8 %h.0 %bl reframe 8 %.r  %bl               %cr 
         %" buf    " buf   8 %h.0 %bl ebuf    8 %h.0 %bl  ebuf buf -  8 %.r       %cr 
         %" gap    " gap   8 %h.0 %bl egap    8 %h.0 %bl  egap gap -  8 %.r       %cr 
         %" ogap   " gap buf - 8 %.r  %bl egap buf - 8 %.r %cr
         %" point  " point 8 %.r %bl cpoint  8 %.r %bl mark  8 %.r  %cr 
         %" page   " page  8 %h.0 %bl epage   8 %h.0 %bl               %cr 
         %" rc     " row   8 %.r  %bl col     8 %.r  %bl               %cr 
         %" size   " size  8 %.r  %bl psize   8 %.r  %bl               %cr  
         %" gapage " buf gap egap ebuf 40 %gapage                      %cr
      %> ;      

   : bug ( -- )
      addr ['member-xt] info mon set-callback  mon init ;

   : set-bname ( addr len -- )
      2dup set-bname  pad zplace  pad mon set-title ;
      
   : init ( -- )   init bug ;

   : .info cr zcount type cr h.s  cr info types key 27 = if quit then ;

end-class






