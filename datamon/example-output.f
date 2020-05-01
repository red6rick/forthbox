{ ----------------------------------------------------------------------
example output in columns and blocks for datamon

rick vannorman  26apr2020  rick@neverslow.com
---------------------------------------------------------------------- }

: test1 ( -- addr len )
   <%
      %" first   " 1000 rnd 4 %.0 %cr
      %" second  " 1000 rnd 4 %.0 %cr
      %" third   " 1000 rnd 4 %.0 %cr
      %" fourth  " 1000 rnd 4 %.0 %cr
      %" fifth   " 1000 rnd 4 %.0 %cr
      %" sixth   " 1000 rnd 4 %.0 %cr
      %" seventh " 1000 rnd 4 %.0 %cr
      %" eighth  " 1000 rnd 4 %.0 %cr
      %" ninth   " 1000 rnd 4 %.0 %cr
      %> ;

: test2 ( -- addr len )
   <%
      %" time " @time (time) %type %cr
      %" date " @date (date) %type %cr
   %> ;


: (b.*) ( n width -- addr len )
   <#  0 do   dup 1 and if [char] * else bl then hold u2/  loop 0 #> ;

: test3 ( -- addr len )
   <%
      %" +--------------------+" %cr
      10 0 do
         [char] | %emit
         1024 dup * rnd  20 (b.*) %type
         [char] | %emit  %cr
      loop
      %" +--------------------+" %cr
   %> ;

   