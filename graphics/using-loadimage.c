#define WIN32_LEAN_AND_MEAN
#define WIN32_EXTRA_LEAN
#include <windows.h>

HWND g_hWnd;
HINSTANCE g_hInstance;
static const int g_nWindowWidth = 600;
static const int g_nWindowHeight = 400;

// Used to double buffer the window
HDC hdcDisplay;
HDC hdcMemory;
HBITMAP hbmBackBuffer;
HBITMAP hbmOld;
RECT rClient;

// Image to display on screen
HDC hdcBitmap;
HBITMAP hbmBitmap;
HBITMAP hbmBitmapOld;
BITMAP bmBitmapInfo;

LRESULT CALLBACK WndProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam);
void CreateBackBuffer();
void DestroyBackBuffer();
void mLoadBitmap();
void UnloadBitmap();
void ClearScene();
void RenderScene();
void PresentScene();

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)  {
  g_hInstance = hInstance;

	WNDCLASS wndclass;
	wndclass.style         = CS_HREDRAW | CS_VREDRAW;
	wndclass.lpfnWndProc   = WndProc;
	wndclass.cbClsExtra    = 0;
	wndclass.cbWndExtra    = 0;
	wndclass.hInstance     = hInstance;
	wndclass.hIcon         = LoadIcon(NULL, IDI_APPLICATION);
	wndclass.hCursor       = LoadCursor(NULL, IDC_ARROW);
	wndclass.hbrBackground = (HBRUSH)(COLOR_BTNFACE + 1);
	wndclass.lpszMenuName  = 0;
	wndclass.lpszClassName = "AwesomeGDI";

	RegisterClass(&wndclass);
	
	SetRect(&rClient, 0, 0, g_nWindowWidth, g_nWindowHeight);
	AdjustWindowRect(&rClient, WS_OVERLAPPEDWINDOW | WS_VISIBLE, FALSE);
	
	g_hWnd = CreateWindow("AwesomeGDI", "Awesomium GDI Test", WS_OVERLAPPEDWINDOW | WS_VISIBLE, 
		(GetSystemMetrics(SM_CXSCREEN) / 2) - ((rClient.right - rClient.left) / 2), 
		(GetSystemMetrics(SM_CYSCREEN) / 2) - ((rClient.right - rClient.left) / 2),
		(rClient.right - rClient.left), (rClient.bottom - rClient.top), NULL, NULL, hInstance, szCmdLine);


	CreateBackBuffer();
	mLoadBitmap();

	MSG msg;
	while (GetMessage(&msg, NULL, 0, 0)) {
		TranslateMessage(&msg);
		DispatchMessage(&msg);
	}

	

	return (int)msg.wParam;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT iMsg, WPARAM wParam, LPARAM lParam) {
	switch (iMsg)  {
		case WM_CREATE:
			break;
		case WM_CLOSE:
			UnloadBitmap();
			DestroyBackBuffer();
			DestroyWindow(hwnd);
			break;
		case WM_DESTROY:
			PostQuitMessage(0);
			break;
		case WM_ERASEBKGND: return TRUE;
		case WM_PAINT:
			//BeginPaint(hwnd, &ps);
			ClearScene();
			RenderScene();
			PresentScene();
			
			ValidateRect(hwnd, NULL);
			//EndPaint(hwnd, &ps);
			break;
	}
	return DefWindowProc(hwnd, iMsg, wParam, lParam);
}

void CreateBackBuffer() {
	hdcDisplay = GetDC(g_hWnd);
	hdcMemory = CreateCompatibleDC(hdcDisplay);
	hbmBackBuffer = CreateCompatibleBitmap(hdcDisplay, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN));
	hbmOld = (HBITMAP)SelectObject(hdcMemory, hbmBackBuffer);
}

void DestroyBackBuffer() {
	SelectObject(hdcMemory, hbmOld);
	DeleteObject(hbmBackBuffer);
	DeleteDC(hdcMemory);
	ReleaseDC(g_hWnd, hdcDisplay);
}

void mLoadBitmap() {
	hbmBitmap = (HBITMAP)LoadImage(g_hInstance, "test_image.bmp", IMAGE_BITMAP, 0, 0, LR_DEFAULTCOLOR | LR_LOADFROMFILE);
	hdcBitmap = CreateCompatibleDC(hdcDisplay);
	hbmBitmapOld = (HBITMAP)SelectObject(hdcBitmap , hbmBitmap);
	GetObject(hbmBitmap , sizeof(BITMAP), &bmBitmapInfo);
}

void UnloadBitmap() {
	SelectObject(hdcBitmap, hbmBitmapOld);
	DeleteObject(hbmBitmap);
	DeleteDC(hdcBitmap);
}

void ClearScene() {
	GetClientRect(g_hWnd, &rClient);
}

void RenderScene() {
	BitBlt(hdcMemory, 0, 0, bmBitmapInfo.bmWidth, bmBitmapInfo.bmHeight, hdcBitmap, 0, 0, SRCCOPY);
}

void PresentScene() {
	BitBlt(hdcDisplay, 0, 0, rClient.right, rClient.bottom, hdcMemory, 0, 0, SRCCOPY);
}