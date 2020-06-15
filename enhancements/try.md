this is a comment block about the backtick loader




: asdfasdf` ( -- )
   begin
      s" ` " /source drop over compare 0= 
      refill 0= or
   until ; immediate

```

.(
nominal forth to compile
)


```
more comments

```

.(
more forth
)
