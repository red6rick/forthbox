\ include winapi.f

{ ----------------------------------------------------------------------
more api calls, and pseudo-api calls
---------------------------------------------------------------------- }


Function: MonitorFromPoint ( x y flag -- monitor )
Function: AllowSetForegroundWindow      ( process -- bool )
Function: TerminateThread ( hthread n -- ior )
Function: ModifyMenu ( hmenu pos flags item data -- bool )
Function: CreatePen ( style width color -- handle )
Function: DrawFrameControl ( hdc rect type state -- bool )
Function: SetBkMode ( hdc mode -- prevmode )
Function: GetSysColor ( index -- color )
Function: CreateDIBSection ( hdc 'bminfo colortype 'mapdata section offset -- hbitmap )
Function: SetWindowPos ( hwnd hwnd x y x y f -- bool )
Function: StretchBlt ( dcdest x y cx cy dcdib x y cx cy rop -- bool )
Function: SetTextAlign ( dc mode -- oldmode )
Function: CreateFont ( x y e o w i u s c o c q p zname -- hfont )
Function: AdjustWindowRectEx ( rect style menu exstyle -- bool )
Function: GetMenuItemInfo ( hmenu item flag 'info -- bool )
Function: CreateMutex ( x y zname -- handle )
Function: SetLastError ( n -- )

\ ======================================================================

522 CONSTANT WM_MOUSEWHEEL

LIBRARY hhctrl.ocx
FUNCTION: HtmlHelp ( hwnd zfile cmd data -- hwnd )

: SetMenuString ( hmenu item z -- bool )
   >R MF_BYCOMMAND MF_STRING OR OVER R> ModifyMenu ;

: GetWindowWidth ( hwnd -- width )
   GetWindowSize nip 0<> and nip nip ;

: GetWindowHeight ( hwnd -- height )
   GetWindowSize 0<> and nip nip nip ;

{ ----------------------------------------------------------------------
FillSolidRect ported from MFC

http://www.microsoft.com/msj/0898/c0898.aspx says:

   FillSolidRect calls TextOut with an empty string, using your color as
   the background color. That's strange because the "normal" way to fill
   a rectangle is to create a solid brush, select it, call PatBlt, then
   deselect the brush. I guess the Redmondtonians know some secret I
   don't -- namely, that SetBkColor/ExtTextOut is faster. It certainly
   requires fewer API calls.
---------------------------------------------------------------------- }

: FillSolidRect ( hdc 'rect coloref -- )
   THIRD SWAP  SetBkColor >R
   >R  DUP  0 0 ETO_OPAQUE R> 0 0 0 ExtTextOut DROP
   R> SetBkColor DROP ;

{ ----------------------------------------------------------------------
Adjust the client size of a window. Normal functions adjust the overall
window size; SetClientSize accounts for borders and menu bars.
---------------------------------------------------------------------- }

: GetClientSize ( hwnd -- width height bool )
   16 R-ALLOC  TUCK GetClientRect SWAP 2 CELLS + 2@ SWAP  ROT ;

: SetClientSize ( hwnd width height -- bool )
   LOCALS| h w handle |  handle
   handle GetWindowSize DROP ( current location, width, and height of windows)
   handle GetClientSize DROP ( current width and height of client )
   ( handle x y wx wy cx cy)  ROT SWAP - H + >R  - W + R>  1 MoveWindow ;

{ ----------------------------------------------------------------------
HTMLHELP is easy to interface to, and makes linkage for chm files

\ simply open the help file
hwnd z" \path\to\my.chm" 0 0 HtmlHelp drop

\ open the help file at a particular topic
hwnd z" \path\to\my.chm::/tutorial.htm" 0 0 htmlhelp drop

---------------------------------------------------------------------- }

: SYSTEM-OPEN ( z -- )
   HWND 0 ROT 0 0 SW_NORMAL ShellExecute DROP ;

{ ----------------------------------------------------------------------
extend the logical-font class
---------------------------------------------------------------------- }

logical-font reopen

   : dot
      height ? width ? escapement ? orientation ? weight ? italic c@ .
      underline c@ . strikeout c@ . charset c@ . outprecision c@ .
      clipprecision c@ . quality c@ . pitchandfamily c@ .
      s\" z\" " type facename zcount type  s\" \"" type ;


END-CLASS

{ ----------------------------------------------------------------------
single instance of an application, by mutex name
---------------------------------------------------------------------- }

single SFXMUTEX

: only-one-instance ( z -- )   >r
   NO_ERROR SetLastError
   0 0 r@ CreateMutex to SFXMUTEX
   GetLastError ERROR_ALREADY_EXISTS = if
      s" An instance of " pad zplace
      r@ zcount pad zappend
      s"  is already running" pad zappend
      0 pad z" sorry!" MB_OK MessageBox drop
      'onsysexit calls  0 ExitProcess
      bye
   then
   r> drop ;

