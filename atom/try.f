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
   


fifth 



   0 locals| len wide ebuf egap gap buf |
   len wide / to 

   ebuf buf - to len
   <%  gap buf - wide len */