#ifndef UPDATER_H
#define UPDATER_H

#include <windows.h>
#include <string>
#include <vector>

bool CheckForUpdates();
void UpdateApp();
void CleanupUpdateJunk();
void ApplyUpdateAndRestart();

#endif // UPDATER_H
