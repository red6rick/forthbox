{ ----------------------------------------------------------------------
A data display window for arbitrary text, running in the background.
The window will automatically resize to the text generated and update
at the programmed interval.

This can be improved and made more general, but serves my purposes now.

rick vannorman  01may2020  rick@neverslow.com
---------------------------------------------------------------------- }

requires rnd
include example-output
include gui

datamon builds gui

: go  gui construct ;

.(

DATAMON -- gui display for live data monitoring

type GO to run the sample

) 
