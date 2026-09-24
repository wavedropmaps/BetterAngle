#ifndef INPUT_H
#define INPUT_H

#include <windows.h>

// 1ms GetAsyncKeyState poll of the movement keys and mouse buttons into
// g_physicalKeys (used for HUD dragging and the debug tab's key readout).
void StartPollingThread();

// Raw Input Mouse Tracking (Delta only)
void RegisterRawMouse(HWND hwnd);
int GetRawInputDeltaX(LPARAM lparam);

// Runtime input gating helpers
bool IsFortniteProcessName(const wchar_t *processName);
bool IsFortniteForeground();
bool IsCursorCurrentlyVisible();

#endif // INPUT_H
