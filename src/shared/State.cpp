#include "shared/State.h"
#include "shared/Logic.h"

#include <climits>
#include <fstream>
#include <locale>
#include <shlobj.h>
#include <sstream>
#include <string>
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "advapi32.lib")

SelectionState g_currentSelection = NONE;
std::atomic<bool> g_isSelectionActive{false};
HBITMAP g_screenSnapshot = NULL;
bool g_isDiving = false;
bool g_showROIBox = true;
std::atomic<int> g_matchCount{0};
std::atomic<bool> g_isCheckingForUpdates(false);
std::atomic<bool> g_hasCheckedForUpdates(false);
std::atomic<bool> g_updateAvailable(false);
std::atomic<bool> g_isDownloadingUpdate(false);
std::atomic<bool> g_downloadComplete(false);
std::mutex g_updateStringsMutex;
std::string g_updateHistory = "";
std::string g_latestVersionOnline = "v" VERSION_STR;
std::atomic<bool> g_fortniteFocusedCache(false);
std::atomic<bool> g_forceRedraw(true);
std::atomic<bool> g_keybindAssignmentActive(false);
std::atomic<long long> g_detectionDelayMs(0);
std::atomic<bool> g_showDebugOverlay(false);
std::atomic<int> g_lockTriggerReason(0);
std::atomic<bool> g_atomicShieldEnabled(true);
std::atomic<ULONGLONG> g_lastValidMatchTime(0);
std::atomic<int> g_lockCount(0);
std::atomic<bool> g_blockInputActive(false);
std::atomic<ULONGLONG> g_lastLockTime(0);

std::atomic<int> g_inputLockMode(kLockModeBlockInput);
std::atomic<int> g_transitionBlendMs(700);
std::atomic<ULONGLONG> g_ignoreMouseUntil(0);

std::atomic<bool> g_diagNoRawInput(false);
std::atomic<bool> g_diagNoTopmost(false);
std::atomic<bool> g_diagNoTimer(false);
std::atomic<bool> g_betaUpdates(false);

std::atomic<int> g_peakMatchCount{0};
std::atomic<int> g_requiredMatchCount{0};
std::atomic<int> g_scannerCpuPct(0);
std::atomic<bool> g_physicalKeys[256] = {};
std::atomic<bool> g_running(true);
int g_screenIndex = 0;
std::atomic<int> g_displayChangeGen{0};
std::atomic<int> g_hudDecimalPlaces{2};
std::atomic<UINT> g_mouseButtonKeybinds[6] = {};
std::atomic<UINT> g_mouseButtonModifiers[6] = {};

std::vector<Profile> g_allProfiles;
int g_selectedProfileIdx = 0;
std::wstring g_lastLoadedProfileName = L"";

bool g_showCrosshair = false;
float g_crossThickness = 1.0f;
COLORREF g_crossColor = RGB(255, 0, 0);
float g_crossOffsetX = 0.0f;
float g_crossOffsetY = 0.0f;
float g_crossAngle = 0.0f;
bool g_crossPulse = false;

COLORREF g_targetColor = RGB(255, 255, 255);
COLORREF g_pickedColor = RGB(255, 255, 255);
RECT g_selectionRect = {0, 0, 0, 0};
POINT g_startPoint = {0};

float g_currentAngle = 0.0f;
std::atomic<bool> g_isCursorVisible(false);
AngleLogic g_logic(0.05);

int g_hudX = 40;
int g_hudY = 40;
int g_dashX = INT_MIN;
int g_dashY = INT_MIN;
bool g_isDraggingHUD = false;
POINT g_dragStartHUD = {0, 0};
POINT g_dragStartMouse = {0, 0};
HWND g_hHUD = NULL;
HWND g_hPanel = NULL;
HWND g_hMsgWnd = NULL;

std::wstring GetAppRootPath() {
  wchar_t appdata[MAX_PATH];
  if (SUCCEEDED(
          SHGetFolderPathW(NULL, CSIDL_LOCAL_APPDATA, NULL, 0, appdata))) {
    std::wstring path = std::wstring(appdata) + L"\\BetterAngle";
    CreateDirectoryW(path.c_str(), NULL);
    return path + L"\\";
  }
  return L"";
}

std::wstring GetProfilesPath() {
  std::wstring root = GetAppRootPath();
  if (root.empty())
    return L"";
  std::wstring pPath = root + L"profiles";
  CreateDirectoryW(pPath.c_str(), NULL);
  SetFileAttributesW(pPath.c_str(), FILE_ATTRIBUTE_HIDDEN);
  return pPath + L"\\";
}

namespace {
std::string WideToUtf8(const std::wstring &w) {
  if (w.empty())
    return "";
  int n = WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), NULL, 0,
                              NULL, NULL);
  std::string s(n, '\0');
  WideCharToMultiByte(CP_UTF8, 0, w.c_str(), (int)w.size(), &s[0], n, NULL,
                      NULL);
  return s;
}

std::wstring Utf8ToWide(const std::string &s) {
  if (s.empty())
    return L"";
  int n = MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), NULL, 0);
  std::wstring w(n, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.c_str(), (int)s.size(), &w[0], n);
  return w;
}

std::string JsonEscape(const std::string &s) {
  std::string out;
  for (char c : s) {
    if (c == '"' || c == '\\')
      out += '\\';
    out += c;
  }
  return out;
}

// Reads the string value of "key":"..." (handles \" and \\ escapes).
bool ExtractJsonString(const std::string &content, const std::string &key,
                       std::string &out) {
  size_t p = content.find("\"" + key + "\":");
  if (p == std::string::npos)
    return false;
  p = content.find('"', p + key.length() + 3);
  if (p == std::string::npos)
    return false;
  out.clear();
  for (size_t i = p + 1; i < content.size(); ++i) {
    char c = content[i];
    if (c == '\\' && i + 1 < content.size()) {
      out += content[++i];
    } else if (c == '"') {
      return true;
    } else {
      out += c;
    }
  }
  return false;
}
} // namespace

void LoadSettings() {
  std::wstring sp = GetAppRootPath() + L"settings.json";
  std::ifstream ifs(sp.c_str());
  if (!ifs.is_open()) {
    // Migration: Check if it exists in the OLD path (profiles/settings.json)
    std::wstring oldPath = GetProfilesPath() + L"settings.json";
    if (GetFileAttributesW(oldPath.c_str()) != INVALID_FILE_ATTRIBUTES &&
        MoveFileW(oldPath.c_str(), sp.c_str())) {
      LoadSettings();
    }
    return;
  }

  std::string content((std::istreambuf_iterator<char>(ifs)),
                      std::istreambuf_iterator<char>());

  auto valueStart = [&](const std::string &k) -> size_t {
    size_t p = content.find("\"" + k + "\":");
    if (p == std::string::npos)
      return std::string::npos;
    return content.find_first_not_of(" \t\n\r", p + k.length() + 3);
  };
  auto eFloat = [&](const std::string &k, float def) -> float {
    size_t valStart = valueStart(k);
    if (valStart == std::string::npos)
      return def;
    std::istringstream iss(content.substr(valStart));
    iss.imbue(std::locale("C"));
    float v = def;
    if (!(iss >> v))
      return def;
    return v;
  };
  auto eInt = [&](const std::string &k, int def) -> int {
    size_t valStart = valueStart(k);
    if (valStart == std::string::npos)
      return def;
    try {
      return std::stoi(content.substr(valStart));
    } catch (...) {
      return def;
    }
  };

  g_hudX = eInt("hudX", 40);
  g_hudY = eInt("hudY", 40);
  g_dashX = eInt("dashX", INT_MIN);
  g_dashY = eInt("dashY", INT_MIN);

  g_showCrosshair = eFloat("showCrosshair", 1.0f) > 0.5f;
  g_selectedProfileIdx = eInt("selectedProfileIdx", 0);
  g_screenIndex = eInt("screenIndex", 0);

  // Before v6.0.5 this loader never actually read any value (an off-by-one
  // parsed ":" as the number), so the old diag* keys may hold toggles from
  // long-forgotten test sessions. Read them under new names so a stale
  // "raw input disabled" can't silently kill angle tracking after updating.
  g_diagNoRawInput = eFloat("diag2NoRawInput", 0.0f) > 0.5f;
  g_diagNoTopmost = eFloat("diag2NoTopmost", 0.0f) > 0.5f;
  g_diagNoTimer = eFloat("diag2NoTimer", 0.0f) > 0.5f;
  g_betaUpdates = eFloat("betaUpdates", 0.0f) > 0.5f;

  int mode = eInt("inputLockMode", kLockModeBlockInput);
  g_inputLockMode =
      (mode == kLockModeBlend) ? kLockModeBlend : kLockModeBlockInput;
  int blendMs = eInt("transitionBlendMs", 700);
  g_transitionBlendMs = blendMs < 100 ? 100 : (blendMs > 2000 ? 2000 : blendMs);

  std::string lastProfile;
  if (ExtractJsonString(content, "lastProfile", lastProfile))
    g_lastLoadedProfileName = Utf8ToWide(lastProfile);
}

void SaveSettings() {
  std::wstring sp = GetAppRootPath() + L"settings.json";
  std::wstring tempPath = sp + L".tmp";

  std::ostringstream oss;
  oss.imbue(std::locale("C"));

  oss << "{\n";
  oss << "  \"hudX\": " << g_hudX << ",\n";
  oss << "  \"hudY\": " << g_hudY << ",\n";
  if (g_dashX != INT_MIN) oss << "  \"dashX\": " << g_dashX << ",\n";
  if (g_dashY != INT_MIN) oss << "  \"dashY\": " << g_dashY << ",\n";
  oss << "  \"showCrosshair\": " << (g_showCrosshair ? 1 : 0) << ",\n";
  oss << "  \"selectedProfileIdx\": " << g_selectedProfileIdx << ",\n";
  oss << "  \"screenIndex\": " << g_screenIndex << ",\n";

  oss << "  \"diag2NoRawInput\": " << (g_diagNoRawInput ? 1 : 0) << ",\n";
  oss << "  \"diag2NoTopmost\": " << (g_diagNoTopmost ? 1 : 0) << ",\n";
  oss << "  \"diag2NoTimer\": " << (g_diagNoTimer ? 1 : 0) << ",\n";
  oss << "  \"betaUpdates\": " << (g_betaUpdates ? 1 : 0) << ",\n";
  oss << "  \"inputLockMode\": " << g_inputLockMode.load() << ",\n";
  oss << "  \"transitionBlendMs\": " << g_transitionBlendMs.load() << ",\n";
  oss << "  \"lastVersionRun\":\"" << VERSION_STR << "\",\n";
  oss << "  \"lastProfile\":\""
      << JsonEscape(WideToUtf8(g_lastLoadedProfileName)) << "\"\n";
  oss << "}\n";

  {
    std::ofstream ofs(tempPath.c_str(), std::ios::trunc);
    if (!ofs.is_open())
      return;
    ofs << oss.str();
    if (!ofs.good())
      return;
  }

  // Hidden files can't be replaced by MoveFileEx; clear the flag first.
  SetFileAttributesW(sp.c_str(), FILE_ATTRIBUTE_NORMAL);
  // Single replace step: a crash can never leave us with no settings file.
  MoveFileExW(tempPath.c_str(), sp.c_str(),
              MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH);
  SetFileAttributesW(sp.c_str(), FILE_ATTRIBUTE_HIDDEN);
}

namespace {
struct MonitorEnumData {
  int targetIndex;
  HMONITOR targetMonitor;
  int currentIndex;
  int foundIndex;
  RECT rect;
};

BOOL CALLBACK MonitorEnumProc(HMONITOR hMonitor, HDC, LPRECT lprcMonitor,
                              LPARAM dwData) {
  auto d = reinterpret_cast<MonitorEnumData *>(dwData);
  if (d->currentIndex == d->targetIndex || hMonitor == d->targetMonitor) {
    d->foundIndex = d->currentIndex;
    d->rect = *lprcMonitor;
    return FALSE;
  }
  d->currentIndex++;
  return TRUE;
}
} // namespace

RECT GetMonitorRectByIndex(int index) {
  MonitorEnumData data = {index, NULL, 0, -1, {0, 0, 0, 0}};
  EnumDisplayMonitors(NULL, NULL, MonitorEnumProc,
                      reinterpret_cast<LPARAM>(&data));
  if (data.foundIndex >= 0)
    return data.rect;

  // Index no longer exists: fall back to the primary monitor so the HUD is
  // never sized to an empty 0x0 rect (which makes it invisible).
  HMONITOR primary = MonitorFromPoint({0, 0}, MONITOR_DEFAULTTOPRIMARY);
  MONITORINFO mi = {sizeof(mi)};
  if (GetMonitorInfoW(primary, &mi))
    return mi.rcMonitor;
  return {0, 0, GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN)};
}

int GetMonitorIndex(HMONITOR monitor) {
  if (!monitor)
    return -1;
  MonitorEnumData data = {-1, monitor, 0, -1, {0, 0, 0, 0}};
  EnumDisplayMonitors(NULL, NULL, MonitorEnumProc,
                      reinterpret_cast<LPARAM>(&data));
  return data.foundIndex;
}

HWND FindFortniteWindow() {
  // Fortnite's window title has carried a trailing double space for years;
  // check the plain title too in case that ever changes.
  HWND fnWnd = FindWindowW(NULL, L"Fortnite  ");
  if (!fnWnd)
    fnWnd = FindWindowW(NULL, L"Fortnite");
  return (fnWnd && IsWindow(fnWnd)) ? fnWnd : NULL;
}
