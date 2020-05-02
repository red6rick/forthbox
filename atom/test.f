
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
         
         

   : dot ( -- addr len )
      <% 
         %" bname " bname count %type %cr
         %" fname " fname count %type %cr
         %" next  " neighbor  %type %cr
         %" flags " flags 8 %h.0 %bl reframe 8 %.r  %bl               %cr 
         %" point " point 8 %h.0 %bl cpoint  8 %h.0 %bl mark  8 %h.0  %cr 
         %" buf   " 'buf  8 %h.0 %bl 'ebuf   8 %h.0 %bl               %cr 
         %" gap   " 'gap  8 %h.0 %bl 'egap   8 %h.0 %bl               %cr 
         %" page  " page  8 %h.0 %bl epage   8 %h.0 %bl               %cr 
         %" rc    " row   8 %.r  %bl col     8 %.r  %bl               %cr 
         %" size  " size  8 %.r  %bl psize   8 %.r  %bl               %cr  
      %> ;      

   : bug ( -- )
      addr ['member-xt] dot mon set-callback  mon init ;

   : set-bname ( addr len -- )
      2dup set-bname  pad zplace  pad mon set-title ;
      
   : init ( -- )   init bug ;


end-class





