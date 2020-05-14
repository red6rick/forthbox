\ include winapp.f

$7ffe constant WM_GETBASEADDR

{ ----------------------------------------------------------------------
DISPATCHING performs message dispatch for a stand-alone windows
application. Note that is assumes the app is a dialog box and manages
messages accordingly.
---------------------------------------------------------------------- }

: DISPATCHING ( -- )
   BEGIN
      WINMSG 0 0 0 GetMessage ( status)
      1+ 1 U> WHILE ( -1 or 0 will terminate the loop )
      WINMSG TranslateMessage DROP
      WINMSG DispatchMessage DROP
   REPEAT WINMSG 2 CELLS + @ ( wparam) ;

{ ----------------------------------------------------------------------
Add common registry items for application position save and restore
to the genericwindow and genericdialog classes
---------------------------------------------------------------------- }

GUICOMMON REOPEN

   SINGLE DC                    \ this window's device context

   \ make sure the zbuf is at least 100 bytes long!

   DEFER: APPKEY ( z zbuf -- zbuf )
      >R   mHWND R@ 100 GetWindowText DROP
      0 R@ ZCOUNT 0 ARGV + C!
      S" _" R@ ZAPPEND  ( z) ZCOUNT R@ ZAPPEND  R> ;

   : WRITE-APPKEY ( addr len zkey -- )
      R-BUF R> APPKEY WRITE-REG-STRING ;

   : READ-APPKEY ( addr len zkey -- )
      R-BUF R> APPKEY READ-REG-STRING DROP ;

   : READ-APPZSTRING ( addr len zkey -- )
      2>R 0 OVER 2R>
      R-BUF R> APPKEY READ-REG-STRING ROT + C! ;


   \ ----------------------------------------------------------------------
   \ positions are a known and desirable case of application specific keys

   : SAVE-POSITION ( -- )
      mHWND HERE GetWindowRect DROP
      HERE 2 CELLS Z" xy" WRITE-APPKEY ;

   : SET-POSITION ( x y -- )
      mHWND HWND_TOP 2SWAP 0 0 SWP_NOSIZE SetWindowPos DROP ;

   : FORCE-ONSCREEN ( -- )
      mHWND 0 MonitorFromWindow ?EXIT  100 100 SET-POSITION ;

   : RESTORE-POSITION ( -- )
      HERE 2 CELLS Z" xy" READ-APPKEY
      HERE 2@ SWAP SET-POSITION  FORCE-ONSCREEN ;

   : set-title ( z -- )   mHWND swap SetWindowText drop ;

END-CLASS

GUICOMMON RELINK-CHILDREN

{ ----------------------------------------------------------------------
Tooltips for dialog and windows controls
---------------------------------------------------------------------- }

CLASS TOOLINFO
   VARIABLE SIZE
   VARIABLE FLAGS
   VARIABLE OWNER
   VARIABLE ID
   RECT BUILDS R
   VARIABLE HINST
   VARIABLE 'TEXT
END-CLASS

TOOLINFO SUBCLASS TOOLTIPS

   SINGLE mHWND

   : CONSTRUCT ( -- )
      THIS SIZEOF SIZE ! ;

   : CREATE-TIPCONTROL ( owner -- htip )
      >R  InitCommonControls DROP
      0 Z" tooltips_class32" 0 TTS_ALWAYSTIP
      CW_USEDEFAULT CW_USEDEFAULT CW_USEDEFAULT CW_USEDEFAULT
      R>  0 HINST 0 CreateWindowEx  TO mHWND ;

   : ATTACH ( hwnd -- )
      DUP CREATE-TIPCONTROL  OWNER !  THIS SIZEOF SIZE ! ;

   : ADD-TIP ( -- )
      mHWND TTM_ADDTOOLA 0 ADDR SendMessage DROP ;

END-CLASS

{ ----------------------------------------------------------------------
Manage menu items, making it easy to enable and disable groups of them
---------------------------------------------------------------------- }

CLASS MENU-MANAGER

   SINGLE OWNER
   SINGLE HMENU

   : ATTACH ( owner menu -- )   TO HMENU TO OWNER ;

   : SET-ITEM ( mi state -- )
      HMENU -ROT EnableMenuItem DROP ;

   : GET-MENU-STATE ( mi -- state )
      HMENU SWAP MF_BYCOMMAND GetMenuState ;

   : ITEM-OFF ( mi -- )   MF_GRAYED SET-ITEM ;
   : ITEM-ON  ( mi -- )   MF_ENABLED SET-ITEM ;

   : ITEM-FLIP  ( mi -- )
      DUP GET-MENU-STATE
      MF_GRAYED = IF  ITEM-ON  ELSE  ITEM-OFF  THEN ;

   : LIST-OFF  ( mi mi .. mi n -- )   0 ?DO  ITEM-OFF   LOOP ;
   : LIST-ON   ( mi mi .. mi n -- )   0 ?DO  ITEM-ON    LOOP ;
   : LIST-FLIP ( mi mi .. mi n -- )   0 ?DO  ITEM-FLIP  LOOP ;

   : GROUP-ON   ( first last -- )   1+ SWAP ?DO I ITEM-ON    LOOP ;
   : GROUP-OFF  ( first last -- )   1+ SWAP ?DO I ITEM-OFF   LOOP ;
   : GROUP-FLIP ( first last -- )   1+ SWAP ?DO I ITEM-FLIP  LOOP ;

END-CLASS

{ ----------------------------------------------------------------------
Create a font resource for a small font.
---------------------------------------------------------------------- }

: TINYFONT ( -- hfont )
   -8 0 0 0 400 0 0 0 255 1 2 1 49 z" Terminal" CreateFont ;

{ ----------------------------------------------------------------------
extend the genericdialog class
---------------------------------------------------------------------- }

genericdialog reopen

   : send-item-message ( id message wparam lparam -- res )
      2>r mhwnd -rot 2r> SendDlgItemMessage ;

   defer: save-dialog-position ( -- flag )   0 ;

   : MyDialogName ( -- z )
      template dup if  32 + pad u>z  pad   then ;

   : dialog-resizeable? ( -- flag )
      mhwnd GWL_STYLE GetWindowLong WS_THICKFRAME and ;

   : set-dialog-placement ( -- )
      here 4 cells z" xy" MyDialogName read-reg-data nip 0= if
         mhwnd here @rect 2drop
         mhwnd getwindowsize drop 2nip  1 MoveWindow drop
      then force-onscreen ;

   : restore-dialog-placement ( -- )
      save-dialog-position -exit  set-dialog-placement ;

   : save-dialog-placement ( -- )
      save-dialog-position -exit
      mHWND GetWindowSize drop  here !rect
      here 4 cells z" xy" MyDialogName write-reg-data drop ;

   WM_NCDESTROY DIALOG:
      save-dialog-placement
      mHWND SFTAG RemoveProp DROP  0 TO mHWND  0 ;

   WM_NCCREATE dialog:
      restore-dialog-placement -1 ;

end-class

genericdialog relink-children


{ ----------------------------------------------------------------------
a new dialog dispatcher to honor the sfdlg-active variable
---------------------------------------------------------------------- }

-? : dispatcher ( -- res )
   begin
      winmsg 0 0 0 GetMessage while
      dlgactive @ winmsg IsDialogMessage 0= if
         winmsg TranslateMessage drop
         winmsg DispatchMessage drop
      then
   repeat  winmsg 2 cells + @ ( wparam) ;


{ --------------------------------------------------------------------
A method to hook an existing window or control to supply new
default behaviors. Mostly useful for dialog controls.

HOOK    will insert a class-based callback for the indicated window.
UNHOOK  will remove the class-based callback.
DEFAULT will call the remembered callback from when the window was
        hooked.

An example follows.
-------------------------------------------------------------------- }

DERIVEDWINDOW SUBCLASS HOOKEDWINDOW

   : HOOK ( mhwnd -- )
      mHWND IF DROP EXIT THEN  TO mHWND
      WINDOW-OBJECT-TAG TO MYTAG  THIS TO MYCLASS
      mHWND SFTAG SELF SetProp DROP
      mHWND GWL_WNDPROC GetWindowLong TO OLDPROC
      mHWND GWL_WNDPROC DERIVED-CLASS-CALLBACK SetWindowLong DROP
      mHWND GetParent TO HPARENT ;

   : UNHOOK ( -- )
      mHWND -EXIT  OLDPROC -EXIT
      mHWND GWL_WNDPROC OLDPROC SetWindowLong DROP
      0 TO OLDPROC  0 TO mHWND  0 TO HPARENT ;

   : DEFAULT ( -- )
      OLDPROC -EXIT
      OLDPROC HWND MSG WPARAM LPARAM CallWindowProc ;

END-CLASS


{ ----------------------------------------------------------------------
examples

A template to demonstrate the hook-ability of a standard dialog control.

DIALOG (HOOKED-BUTTON)

   [MODELESS  " SBIRS Debug User Interface" 0 0 100 100
                                 (CLASS SFDLG) (FONT 9, FixedSys) ]

   [PUSHBUTTON " TEST"   ID: TEST     5  5 40 12 ]
   [PUSHBUTTON " HOOK"   ID: HOOK     5 25 40 12 ]
   [PUSHBUTTON " UNHOOK" ID: UNHOOK   5 45 40 12 ]
   [LTEXT                ID: UPS     50  5 20 12 ]
   [LTEXT                ID: DOWNS   50 25 20 12 ]
   [LTEXT                ID: PRESSES 50 45 20 12 ]

END-DIALOG

\ ----------------------------------------------------------------------
\ Subclass a button to count up and down events

HOOKEDWINDOW SUBCLASS COUNTING-BUTTON

   SINGLE UPS
   SINGLE DOWNS

   : NOTIFY ( -- )   HPARENT WM_USER 0 0 SendMessage DROP ;

   WM_LBUTTONDOWN MESSAGE:  1 +TO DOWNS  NOTIFY DEFAULT ;
   WM_LBUTTONUP   MESSAGE:  1 +TO UPS    NOTIFY DEFAULT ;
   WM_RBUTTONDOWN MESSAGE: -1 +TO DOWNS  NOTIFY DEFAULT ;

END-CLASS

test the control hook class. this dialog shows a button which increments
the PRESSES counter. When the HOOK button is pressed, the TEST button is
"hooked" to include the COUNTING-BUTTON defined callback behavior.  It
can be "unhooked" to return it to normal behavior. COUNTING-BUTTON will
notify the dialog when it executes and updates counters, so that the UPS
and DOWNS counters may be viewed independently of the PRESSES
counter. For instance, while TEST is hooked, press it and hold the mouse
button down. The DOWNS counter will increment, but PRESSES will not; the
button default behavior is to not generate a dialog event until
released. Right mouse clicks on dialog buttons are not normally
responded to. The COUNTING-BUTTON callback will use right clicks to
decrement the downs counter.

GENERICDIALOG SUBCLASS HOOKED-BUTTON-DIALOG

   : TEMPLATE ( -- z )   (HOOKED-BUTTON) ;

   SINGLE PRESSES
   COUNTING-BUTTON BUILDS MYBUTTON

   : SET-INT ( id n -- )
      mHWND -ROT 1 SetDlgItemInt DROP ;

   ID_HOOK COMMAND:   mHWND ID_TEST GetDlgItem  MYBUTTON HOOK ;
   ID_UNHOOK COMMAND:   MYBUTTON UNHOOK ;

   : UPDATE ( -- )
      ID_UPS      MYBUTTON UPS    SET-INT
      ID_DOWNS    MYBUTTON DOWNS  SET-INT
      ID_PRESSES  PRESSES         SET-INT ;

   WM_USER MESSAGE:   UPDATE ;

   ID_TEST COMMAND:   1 +TO PRESSES  UPDATE ;

   WM_INITDIALOG MESSAGE:   UPDATE 0 ;

END-CLASS

\ ----------------------------------------------------------------------
\ testing the hook

HOOKED-BUTTON-DIALOG BUILDS HBD

: TRY ( -- )
   0 HBD MODELESS DROP ;


---------------------------------------------------------------------- }

{ ----------------------------------------------------------------------
add to the menu compiler
---------------------------------------------------------------------- }

menucomp open-package

: ----   separator ;

end-package

{ ----------------------------------------------------------------------
query (and set) menu check state -- not a good implementation yet
---------------------------------------------------------------------- }

: IsMenuItemChecked ( hmenu item -- FLAG )
   r-buf
   11 cells r@ !  MIIM_STATE r@ cell+ !
   0 r@ GetMenuItemInfo drop
   r> 3 cells + @ 0<> ;

{ ----------------------------------------------------------------------
add the ip control to the dialog compiler
---------------------------------------------------------------------- }

PACKAGE DLGCOMP

s" SysIPAddress32"
   (OR WS_BORDER WS_VISIBLE WS_CHILD WS_TABSTOP WS_GROUP WS_CLIPSIBLINGS)
CONTROL [IPADDR

#BUTTON (OR BS_3STATE WS_TABSTOP)          CONTROL [3STATE

END-PACKAGE


{ --------------------------------------------------------------------
MainWindow_base is the main application window class. It is built from
the base class GENERICWINDOW with a few appropriate over-rides
specified. Note that MyClass_ClassName and MyWindow_WindowName _must_ be
specified in any user-defined class -- leaving these as defaults will
work in this simple example but will bite you hard in the butt later.
-------------------------------------------------------------------- }

GENERICWINDOW SUBCLASS gui-wrapper

   STATUSBAR BUILDS STAT        \ unused today, allowed for
   RECT BUILDS CLIENT           \ interior size of display

   SINGLE HMENU                 \ handle of the window's menu

   SINGLE LEFT                  \ pixel counts of margins of display
   SINGLE TOP
   SINGLE RIGHT
   SINGLE BOTTOM

   DEFER: MyAppName     ( -- zstr )   Z" MyAppName" ;
   DEFER: HasStatusbar ( -- flag )   FALSE ;
   DEFER: HasMenu      ( -- flag )   FALSE ;

   DEFER: INIT-MENU     ( -- )   ;
   DEFER: AFTER-CREATE  ( -- )   ;
   DEFER: BEFORE-CLOSE  ( -- )   ;
   DEFER: AFTER-SIZING  ( -- )   ;

   : MyClass_ClassName     MyAppName ;
   : MyWindow_WindowName   MyAppName ;

   : /BORDERS ( -- )
      0 TO LEFT  0 TO RIGHT  0 TO TOP   STAT HIGH TO BOTTOM ;

   : RESIZE-STATUS ( -- )
      0 CLIENT bottom @ BOTTOM -
      CLIENT right @ CLIENT bottom @ STAT RESIZE ;

   : RESIZED ( -- )
      mHWND CLIENT ADDR GetClientRect DROP    RESIZE-STATUS ;

   : SAVE-WINDOW-PLACEMENT ( -- )
      mHWND GetWindowSize DROP  HERE !RECT
      HERE 4 CELLS Z" xy" MyAppName WRITE-REG-DATA DROP ;

   : SET-POSITION ( x y -- )
      mHWND HWND_TOP 2SWAP 0 0 SWP_NOSIZE SetWindowPos DROP ;

   : FORCE-ONSCREEN ( -- )
      mHWND 0 MonitorFromWindow ?EXIT  0 0 SET-POSITION ;

   : HIDE ( -- )   mhwnd SW_HIDE ShowWindow drop ;
   : SHOW ( -- )   mhwnd SW_SHOW ShowWindow drop ;

   : visible? ( -- flag )   mhwnd iswindowvisible ;
   : hidden? ( -- flag )   mhwnd iswindowvisible 0= ;

   DEFER: DEFAULT-WINDOW-PLACEMENT ( -- xorg yorg xsize ysize )
      100 100 400 300 ;

   : RESTORE-WINDOW-PLACEMENT ( -- )
      HERE 4 CELLS Z" xy" MyAppName READ-REG-DATA NIP IF
         mHWND DEFAULT-WINDOW-PLACEMENT 1 MoveWindow DROP
      ELSE
         mHWND HERE @RECT 1 MoveWindow DROP
      THEN FORCE-ONSCREEN ;

   : /SHAPE ( -- )
      /BORDERS RESIZED  RESTORE-WINDOW-PLACEMENT ;

   : /STATUSBAR ( -- )
      HasStatusbar IF  mHWND STAT ATTACH  THEN ;

   : /MENU ( -- )
      HasMenu IF
         mHWND HasMenu LoadMenuIndirect SetMenu DROP
         mHWND GetMenu to hMenu
         INIT-MENU
      THEN ;

   : RESIZE-WINDOW ( cx cy -- )
      mHWND ROT ROT SetClientSize DROP ;

   : OnAppCreate ( -- res )
      /STATUSBAR  /MENU  /SHAPE  0 ;

   : OnAppClose ( -- )
      BEFORE-CLOSE ;

   : OnClose ( -- )
      mHWND DestroyWindow 0 ;

   WM_DESTROY MESSAGE:
      'main @ ['] development <> if
         0 PostQuitMessage drop
      then 0 ;

   : createtimer ( id ms -- )
      mhwnd -rot 0 SetTimer drop ;

   : close   mhwnd WM_CLOSE 0 0 SendMessage drop ;

   WM_CREATE   MESSAGE: ( -- res )   OnAppCreate OnCreate AFTER-CREATE ;
   WM_CLOSE    MESSAGE: ( -- res )   SAVE-WINDOW-PLACEMENT  OnAppClose OnClose ;
   WM_SIZE     MESSAGE: ( -- res )   RESIZED AFTER-SIZING 1 ;
   MI_ABOUT    COMMAND: ( -- res )   mHWND z" about" z" sample" MB_OK MessageBox ;
   MI_EXIT     COMMAND: ( -- res )   mHWND WM_CLOSE 0 0 SendMessage ;


   WM_GETBASEADDR message:   addr ;

END-CLASS

guicommon reopen

   : COMPLAIN ( z -- )   r-buf
      mhwnd r@ 100 GetWindowText drop
      mhwnd swap r> MB_OK MessageBox drop ;

   : ?complain ( ior z -- )
      swap if complain else drop then ;

end-class  guicommon relink-children

basedialog reopen

   : disables ( x x .. x n -- )   0 ?do  disable  loop ;
   : enables  ( x x .. x n -- )   0 ?do   enable  loop ;

   : set-item-font ( hfont id -- )
      mhwnd swap GetDlgItem  WM_SETFONT rot 1 SendMessage drop ;

end-class  basedialog relink-children

{ ----------------------------------------------------------------------
extend the dialog class for easier stand-alone dialogs
---------------------------------------------------------------------- }

GENERICDIALOG SUBCLASS dialog-application

   IDCANCEL COMMAND: ( -- res )   0 ;   \ inhibit <esc> and
   IDOK     COMMAND: ( -- res )   0 ;   \ <enter> keystrokes

{ ----------------------------------------------------------------------
new versions of the modeless activators to give us better
control over post-wm_initdialog behavior???
---------------------------------------------------------------------- }

   defer: MyAppName   0 ;

   : retitle ( -- )
      MyAppName ?dup if  set-title  then ;

   DEFER: RESTORE-DIALOG ;
   DEFER: SAVE-DIALOG ;

{ ----------------------------------------------------------------------
FILE-DROPPED logs drag-and-drop events and sets the filename fields
   in the GUI.

FILE-DROP-HANDLER manages drag-and-drop events. It limits the user
   to a one item at a time and makes sure it is a file.
---------------------------------------------------------------------- }

    defer: FILE-DROPPED ( zaddr -- )   drop ;

    : FILE-DROP-HANDLER ( -- )
       WPARAM -1 0 0 DragQueryFile 1 <> IF
          S" Drop one file at a time" CARP
       ELSE
          WPARAM 0 HERE 255 DragQueryFile DROP
          HERE IS-FILE IF
             HERE FILE-DROPPED
          ELSE  S" Only files may be dropped" CARP  THEN
       THEN
       WPARAM DragFinish ;

   WM_DESTROY MESSAGE: ( -- res )
      [ 'MAIN @ ] LITERAL 'MAIN @ <> IF   \ post quit only if stand-alone exe
         0 PostQuitMessage DROP
      THEN 0 ;

   WM_CLOSE MESSAGE: ( -- res )
      save-dialog  mHWND DestroyWindow DROP 0 ;

   WM_DROPFILES MESSAGE:
      FILE-DROP-HANDLER 0 ;

   : APPLICATION ( -- )
      0 TO IS-MODAL
      0 ATTACH drop
      retitle
      RESTORE-DIALOG ;

END-CLASS

{ ----------------------------------------------------------------------
To make the dialog completely standalone, the following code is used.
Note that the message dispatcher contained in SwiftForth services the
ide interactions, and also dispatches messages for dialog boxes. It
works, but isn't suitable for a dialog box that is a standalone
application. The following is a much better implementation.
---------------------------------------------------------------------- }

: DIALOG-DISPATCHER ( handle -- )
   >R BEGIN
      WINMSG 0 0 0 GetMessage ( status)
      1+ 1 U> WHILE ( -1 or 0 will terminate the loop )
      R@ WINMSG IsDialogMessage 0= IF
         WINMSG TranslateMessage DROP
         WINMSG DispatchMessage DROP
      THEN
   REPEAT  R> DROP ;

{ --------------------------------------------------------------------
Common control class names
-------------------------------------------------------------------- }

CREATE WC_HEADER           ,Z" SysHeader32"
CREATE WC_LISTVIEW         ,Z" SysListView32"
CREATE WC_TREEVIEW         ,Z" SysTreeView32"
CREATE WC_COMBOBOXEX       ,Z" ComboBoxEx32"
CREATE WC_TABCONTROL       ,Z" SysTabControl32"
CREATE WC_IPADDRESS        ,Z" SysIPAddress32"
CREATE WC_PAGESCROLLER     ,Z" SysPager"
CREATE WC_NATIVEFONTCTL    ,Z" NativeFontCtl"
CREATE WC_TOOLTIPS         ,Z" tooltips_class32"
CREATE WC_TRACKBAR         ,Z" msctls_trackbar32"
CREATE WC_UPDOWN           ,Z" msctls_updown32"
CREATE WC_PROGRESS         ,Z" msctls_progress32"
CREATE WC_HOTKEY           ,Z" msctls_hotkey32"
CREATE WC_ANIMATE          ,Z" SysAnimate32"
CREATE WC_MONTHCAL         ,Z" SysMonthCal32"
CREATE WC_DATETIMEPICK     ,Z" SysDateTimePick32"

: COMMON-CONTROL ( owner type x y cx cy -- handle )
   LOCALS| cy cx y x type owner |
   0 type 0  WS_BORDER WS_VISIBLE OR WS_CHILD OR WS_TABSTOP OR
   x y cx cy owner 0 HINST 0 CreateWindowEx ;

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

1 IMPORT: InitCommonControlsEx

$00000001 CONSTANT ICC_LISTVIEW_CLASSES \ listview, header
$00000002 CONSTANT ICC_TREEVIEW_CLASSES \ treeview, tooltips
$00000004 CONSTANT ICC_BAR_CLASSES      \ toolbar, statusbar, trackbar, toolti
$00000008 CONSTANT ICC_TAB_CLASSES      \ tab, tooltips
$00000010 CONSTANT ICC_UPDOWN_CLASS     \ updown
$00000020 CONSTANT ICC_PROGRESS_CLASS   \ progress
$00000040 CONSTANT ICC_HOTKEY_CLASS     \ hotkey
$00000080 CONSTANT ICC_ANIMATE_CLASS    \ animate
$000000FF CONSTANT ICC_WIN95_CLASSES
$00000100 CONSTANT ICC_DATE_CLASSES     \ month picker, date picker, time pick
$00000200 CONSTANT ICC_USEREX_CLASSES   \ comboex
$00000400 CONSTANT ICC_COOL_CLASSES     \ rebar (coolbar) control
$00000800 CONSTANT ICC_INTERNET_CLASSES
$00001000 CONSTANT ICC_PAGESCROLLER_CLASS  \ page scroller
$00002000 CONSTANT ICC_NATIVEFNTCTL_CLASS  \ native font control

: /COMMON-CONTROLS ( mask -- )
   2 CELLS DUP R-ALLOC >R  R@ 2!  R> InitCommonControlsEx 0= THROW ;

