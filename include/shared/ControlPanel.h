#ifndef CONTROLPANEL_H
#define CONTROLPANEL_H

#include <windows.h>
#include <string>

HWND CreateControlPanel(HINSTANCE hInst);
void ShowControlPanel();
void EnsureEngineInitialized();

#endif
