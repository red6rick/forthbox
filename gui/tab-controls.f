{ ----------------------------------------------------------------------
build a window with tabs

Rick VanNorman  13May2020  rick@neverslow.com
---------------------------------------------------------------------- }

class TCITEM
   single mask
   single state
   single statemask
   single ztext
   single textmax
   single image
   single lparam
end-class   




{ ----------------------------------------------------------------------
Finally, we can define a framework and create a tab control in it.
---------------------------------------------------------------------- }

gui-framework subclass myapp
   : MyAppName ( -- z )   z" MyTabDemo" ;

   single htabctl
   tcitem builds ti
   
   : new-tab ( ztext index -- )   >r  to ti ztext  
      htabctl TCM_INSERTITEMA r> ti addr sendmessage drop ;

   : make-tabs ( -- )
      TCIF_TEXT to ti mask  
      z" zero" 0 new-tab
      z" one"  1 new-tab
      z" two"  2 new-tab ;

   : init
      mhwnd pad GetClientRect drop  
      mhwnd WC_TABCONTROL pad @rect common-control to htabctl
      make-tabs ;

   WM_NOTIFY message:
      operator's cr wparam h. lparam h. lparam 12 hdump ;

end-class

myapp builds app
: go   app construct ;



\ ----------------------------------------------------------------------
\ ----------------------------------------------------------------------
\\ \\\\ working notes, built the tab control on the fly
\\\ \\\ 
\\\\ \\ 
\\\\\ \ 

app mhwnd constant z
z WC_TABCONTROL 20 20 300 200 common-control value y
tcitem builds ti
TCIF_TEXT TCIF_IMAGE or to ti mask
-1 to ti image
z" blah" to ti ztext  y TCM_INSERTITEMA 0 ti addr sendmessage
z" asdf" to ti ztext  y TCM_INSERTITEMA 1 ti addr sendmessage
z" rick" to ti ztext  y TCM_INSERTITEMA 2 ti addr sendmessage








\ ----------------------------------------------------------------------
\\ \\\\ from microsoft
\\\ \\\ https://docs.microsoft.com/en-us/windows/win32/controls/create-a-tab-control-in-the-main-window
\\\\ \\ 
\\\\\ \ 

#define DAYS_IN_WEEK 7

// Creates a tab control, sized to fit the specified parent window's client
//   area, and adds some tabs. 
// Returns the handle to the tab control. 
// hwndParent - parent window (the application's main window). 
// 
HWND DoCreateTabControl(HWND hwndParent) 
{ 
    RECT rcClient; 
    INITCOMMONCONTROLSEX icex;
    HWND hwndTab; 
    TCITEM tie; 
    int i; 
    TCHAR achTemp[256];  // Temporary buffer for strings.
 
    // Initialize common controls.
    icex.dwSize = sizeof(INITCOMMONCONTROLSEX);
    icex.dwICC = ICC_TAB_CLASSES;
    InitCommonControlsEx(&icex);
    
    // Get the dimensions of the parent window's client area, and 
    // create a tab control child window of that size. Note that g_hInst
    // is the global instance handle.
    GetClientRect(hwndParent, &rcClient); 
    hwndTab = CreateWindow(WC_TABCONTROL, L"", 
        WS_CHILD | WS_CLIPSIBLINGS | WS_VISIBLE, 
        0, 0, rcClient.right, rcClient.bottom, 
        hwndParent, NULL, g_hInst, NULL); 
    if (hwndTab == NULL)
    { 
        return NULL; 
    }
 
    // Add tabs for each day of the week. 
    tie.mask = TCIF_TEXT | TCIF_IMAGE; 
    tie.iImage = -1; 
    tie.pszText = achTemp; 
 
    for (i = 0; i < DAYS_IN_WEEK; i++) 
    { 
        // Load the day string from the string resources. Note that
        // g_hInst is the global instance handle.
        LoadString(g_hInst, IDS_SUNDAY + i, 
                achTemp, sizeof(achTemp) / sizeof(achTemp[0])); 
        if (TabCtrl_InsertItem(hwndTab, i, &tie) == -1) 
        { 
            DestroyWindow(hwndTab); 
            return NULL; 
        } 
    } 
    return hwndTab; 
}

\ ----------------------------------------------------------------------

// Creates a child window (a static control) to occupy the tab control's 
//   display area. 
// Returns the handle to the static control. 
// hwndTab - handle of the tab control. 
// 
HWND DoCreateDisplayWindow(HWND hwndTab) 
{ 
    HWND hwndStatic = CreateWindow(WC_STATIC, L"", 
        WS_CHILD | WS_VISIBLE | WS_BORDER, 
        100, 100, 100, 100,        // Position and dimensions; example only.
        hwndTab, NULL, g_hInst,    // g_hInst is the global instance handle
        NULL); 
    return hwndStatic; 
}

\ ----------------------------------------------------------------------

// Handles the WM_SIZE message for the main window by resizing the 
//   tab control. 
// hwndTab - handle of the tab control.
// lParam - the lParam parameter of the WM_SIZE message.
//
HRESULT OnSize(HWND hwndTab, LPARAM lParam)
{
    RECT rc; 

    if (hwndTab == NULL)
        return E_INVALIDARG;

    // Resize the tab control to fit the client are of main window.
     if (!SetWindowPos(hwndTab, HWND_TOP, 0, 0, GET_X_LPARAM(lParam), GET_Y_LPARAM(lParam), SWP_SHOWWINDOW))
        return E_FAIL;

    return S_OK;
}

// Handles notifications from the tab control, as follows: 
//   TCN_SELCHANGING - always returns FALSE to allow the user to select a 
//     different tab.  
//   TCN_SELCHANGE - loads a string resource and displays it in a static 
//     control on the selected tab.
// hwndTab - handle of the tab control.
// hwndDisplay - handle of the static control. 
// lParam - the lParam parameter of the WM_NOTIFY message.
//
BOOL OnNotify(HWND hwndTab, HWND hwndDisplay, LPARAM lParam)
{
    TCHAR achTemp[256]; // temporary buffer for strings

    switch (((LPNMHDR)lParam)->code)
        {
            case TCN_SELCHANGING:
                {
                    // Return FALSE to allow the selection to change.
                    return FALSE;
                }

            case TCN_SELCHANGE:
                { 
                    int iPage = TabCtrl_GetCurSel(hwndTab); 

                    // Note that g_hInst is the global instance handle.
                    LoadString(g_hInst, IDS_SUNDAY + iPage, achTemp,
                        sizeof(achTemp) / sizeof(achTemp[0])); 
                    LRESULT result = SendMessage(hwndDisplay, WM_SETTEXT, 0,
                        (LPARAM) achTemp); 
                    break;
                } 
        }
        return TRUE;
}

\ ----------------------------------------------------------------------



