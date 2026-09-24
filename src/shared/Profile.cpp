#include "shared/Profile.h"
#include <fstream>
#include <iomanip>
#include <iostream>
#include <locale>
#include <sstream>
#include <vector>
#include <windows.h>

namespace {
std::wstring Utf8ToWide(const std::string &s) {
  if (s.empty())
    return L"";
  int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), NULL, 0);
  std::wstring w(n, L'\0');
  MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), &w[0], n);
  return w;
}

std::string WideToUtf8(const std::wstring &w) {
  if (w.empty())
    return "";
  int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), NULL, 0,
                              NULL, NULL);
  std::string s(n, '\0');
  WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), &s[0], n, NULL,
                      NULL);
  return s;
}

// Quote a string for JSON (escapes " and \).
std::string JsonQuote(const std::wstring &w) {
  std::string out = "\"";
  for (char c : WideToUtf8(w)) {
    if (c == '"' || c == '\\')
      out += '\\';
    out += c;
  }
  return out + "\"";
}

// Read the JSON string that opens at content[quotePos] ('"'). Returns the
// unescaped text and sets `end` to the index of the closing quote.
std::string ReadJsonString(const std::string &content, size_t quotePos,
                           size_t &end) {
  std::string out;
  size_t i = quotePos + 1;
  for (; i < content.size() && content[i] != '"'; ++i) {
    if (content[i] == '\\' && i + 1 < content.size())
      ++i;
    out += content[i];
  }
  end = i;
  return out;
}

// Find `target` outside of any JSON string, starting at `from`.
size_t FindUnquoted(const std::string &content, char target, size_t from) {
  bool inString = false;
  for (size_t i = from; i < content.size(); ++i) {
    char c = content[i];
    if (inString) {
      if (c == '\\')
        ++i;
      else if (c == '"')
        inString = false;
    } else if (c == '"') {
      inString = true;
    } else if (c == target) {
      return i;
    }
  }
  return std::string::npos;
}
} // namespace

bool Profile::Load(const std::wstring &path) {
  std::ifstream f(path, std::ios::binary);
  if (!f.is_open())
    return false;

  // Simple manual JSON parser to avoid external dependencies
  std::string content((std::istreambuf_iterator<char>(f)),
                      std::istreambuf_iterator<char>());

  // Extract name (always the first key in the file)
  size_t namePos = content.find("\"name\": \"");
  if (namePos != std::string::npos) {
    size_t end;
    name = Utf8ToWide(ReadJsonString(content, namePos + 8, end));
  }

  auto hasKey = [&](const std::string &key) {
    return content.find("\"" + key + "\": ") != std::string::npos;
  };
  // Numeric value of "key": <number>, or `def` if the key is missing.
  auto extractDouble = [&](const std::string &key, double def = 0.0) -> double {
    size_t pos = content.find("\"" + key + "\": ");
    if (pos == std::string::npos)
      return def;
    size_t start = pos + 4 + key.length();
    size_t end = content.find_first_of(",}\n", start);
    std::string valStr = content.substr(start, end - start);
    std::istringstream iss(valStr);
    iss.imbue(std::locale("C"));
    double d = def;
    if (!(iss >> d))
      return def;
    return d;
  };

  sensitivityX = extractDouble("sensitivityX");
  if (sensitivityX <= 0.0)
    sensitivityX = 0.05;

  sensitivityY = extractDouble("sensitivityY");
  if (sensitivityY <= 0.0)
    sensitivityY = 0.05;

  roi_x = (int)extractDouble("roi_x");
  roi_y = (int)extractDouble("roi_y");
  roi_w = (int)extractDouble("roi_w");
  roi_h = (int)extractDouble("roi_h");
  target_color = (COLORREF)extractDouble("target_color");
  tolerance = (int)extractDouble("tolerance");
  if (tolerance <= 0)
    tolerance = 2;

  diveGlideMatch = (float)extractDouble("diveGlideMatch", 9.0);
  screenIndex = (int)extractDouble("screenIndex", 0);
  hudDecimalPlaces = (int)extractDouble("hudDecimalPlaces", 2);
  if (hudDecimalPlaces < 1 || hudDecimalPlaces > 2)
    hudDecimalPlaces = 2;
  atomicShield = extractDouble("atomicShield", 1.0) > 0.5;

  // Load Keybinds
  keybinds.toggleMod = (UINT)extractDouble("kb_toggleMod");
  keybinds.toggleKey = (UINT)extractDouble("kb_toggleKey");
  keybinds.roiMod = (UINT)extractDouble("kb_roiMod");
  keybinds.roiKey = (UINT)extractDouble("kb_roiKey");
  keybinds.crossMod = (UINT)extractDouble("kb_crossMod");
  keybinds.crossKey = (UINT)extractDouble("kb_crossKey");
  keybinds.zeroMod = (UINT)extractDouble("kb_zeroMod");
  keybinds.zeroKey = (UINT)extractDouble("kb_zeroKey");

  // Fallback defaults for new files or legacy ones
  if (keybinds.toggleKey == 0) {
    keybinds.toggleMod = MOD_CONTROL;
    keybinds.toggleKey = 'U';
  }
  if (keybinds.roiKey == 0) {
    keybinds.roiMod = MOD_CONTROL;
    keybinds.roiKey = 'R';
  }
  if (keybinds.crossKey == 0) {
    keybinds.crossMod = 0;
    keybinds.crossKey = VK_F10;
  }
  if (keybinds.zeroKey == 0) {
    keybinds.zeroMod = MOD_CONTROL;
    keybinds.zeroKey = 'G';
  }

  // Load Crosshair (with defaults for legacy files)
  crossThickness = (float)extractDouble("crossThickness");
  if (crossThickness < 1.0f)
    crossThickness = 1.0f;

  // Black (0) is a valid colour; only default when the key is missing.
  crossColor = (COLORREF)extractDouble("crossColor", RGB(255, 0, 0));
  crossOffsetX = (float)extractDouble("crossOffsetX");
  crossOffsetY = (float)extractDouble("crossOffsetY");
  crossAngle = (float)extractDouble("crossAngle");
  bool pulseVal = extractDouble("crossPulse") > 0.5;
  crossPulse = pulseVal;
  showCrosshair = extractDouble("showCrosshair", 1.0) > 0.5;

  // Load Presets Array (Manual Parser)
  crosshairPresets.clear();
  size_t arrPos = content.find("\"crosshairPresets\": [");
  if (arrPos != std::string::npos) {
    size_t endArr = FindUnquoted(content, ']', arrPos + 20);
    std::string arrContent = content.substr(arrPos + 20, endArr - arrPos - 20);
    size_t objPos = 0;
    while ((objPos = FindUnquoted(arrContent, '{', objPos)) != std::string::npos) {
      size_t objEnd = FindUnquoted(arrContent, '}', objPos);
      if (objEnd == std::string::npos)
        break;
      std::string obj = arrContent.substr(objPos, objEnd - objPos);

      CrosshairPreset cp;
      // Parse name
      size_t nP = obj.find("\"name\": \"");
      if (nP != std::string::npos) {
        size_t nE;
        cp.name = Utf8ToWide(ReadJsonString(obj, nP + 8, nE));
      }
      // Parse coords
      auto exD = [&](std::string k) -> float {
        size_t p = obj.find("\"" + k + "\": ");
        if (p == std::string::npos)
          return 0.0f;
        return (float)std::atof(obj.substr(p + k.length() + 3).c_str());
      };
      cp.offsetX = exD("x");
      cp.offsetY = exD("y");
      cp.angle = exD("a");
      cp.thickness = exD("t");
      if (cp.thickness < 1.0f)
        cp.thickness = 1.0f;
      cp.color = obj.find("\"c\": ") != std::string::npos
                     ? (COLORREF)exD("c")
                     : RGB(255, 0, 0);
      cp.pulse = exD("p") > 0.5f;
      crosshairPresets.push_back(cp);
      objPos = objEnd + 1;
    }
  }

  // Ensure default if empty
  if (crosshairPresets.empty()) {
    CrosshairPreset def = {L"🎯 Screen Center", 0.0f, 0.0f, 0.0f, 1.0f,
                           RGB(255, 0, 0),      false};
    crosshairPresets.push_back(def);
  }

  return true;
}

bool Profile::Save(const std::wstring &path) {
  std::wstring tempPath = path + L".tmp";

  // Use a stringstream with C locale for consistent decimal points
  std::stringstream ss;
  ss.imbue(std::locale("C"));

  ss << "{\n";
  ss << "  \"name\": " << JsonQuote(name) << ",\n";
  ss << "  \"sensitivityX\": " << sensitivityX << ",\n";
  ss << "  \"sensitivityY\": " << sensitivityY << ",\n";
  ss << "  \"roi_x\": " << roi_x << ",\n";
  ss << "  \"roi_y\": " << roi_y << ",\n";
  ss << "  \"roi_w\": " << roi_w << ",\n";
  ss << "  \"roi_h\": " << roi_h << ",\n";
  ss << "  \"target_color\": " << (unsigned long)target_color << ",\n";
  ss << "  \"tolerance\": " << tolerance << ",\n";
  ss << "  \"diveGlideMatch\": " << diveGlideMatch << ",\n";
  ss << "  \"screenIndex\": " << screenIndex << ",\n";
  ss << "  \"hudDecimalPlaces\": " << hudDecimalPlaces << ",\n";
  ss << "  \"atomicShield\": " << (atomicShield ? 1 : 0) << ",\n";
  ss << "  \"kb_toggleMod\": " << keybinds.toggleMod << ",\n";
  ss << "  \"kb_toggleKey\": " << keybinds.toggleKey << ",\n";
  ss << "  \"kb_roiMod\": " << keybinds.roiMod << ",\n";
  ss << "  \"kb_roiKey\": " << keybinds.roiKey << ",\n";
  ss << "  \"kb_crossMod\": " << keybinds.crossMod << ",\n";
  ss << "  \"kb_crossKey\": " << keybinds.crossKey << ",\n";
  ss << "  \"kb_zeroMod\": " << keybinds.zeroMod << ",\n";
  ss << "  \"kb_zeroKey\": " << keybinds.zeroKey << ",\n";

  ss << "  \"crossThickness\": " << std::fixed << std::setprecision(6) << crossThickness << ",\n";
  ss << "  \"showCrosshair\": " << (showCrosshair ? 1 : 0) << ",\n";
  ss << "  \"crossColor\": " << (unsigned long)crossColor << ",\n";
  ss << "  \"crossOffsetX\": " << crossOffsetX << ",\n";
  ss << "  \"crossOffsetY\": " << crossOffsetY << ",\n";
  ss << "  \"crossAngle\": " << crossAngle << ",\n";
  ss << "  \"crossPulse\": " << (crossPulse ? 1 : 0) << ",\n";

  ss << "  \"crosshairPresets\": [\n";
  for (size_t i = 0; i < crosshairPresets.size(); i++) {
    const auto &cp = crosshairPresets[i];
    ss << "    {\"name\": " << JsonQuote(cp.name) << ", \"x\": " << cp.offsetX
       << ", \"y\": " << cp.offsetY << ", \"a\": " << cp.angle
       << ", \"t\": " << cp.thickness << ", \"c\": "
       << (unsigned long)cp.color << ", \"p\": " << (cp.pulse ? 1 : 0)
       << "}";
    if (i < crosshairPresets.size() - 1)
      ss << ",";
    ss << "\n";
  }
  ss << "  ]\n";
  ss << "}";

  {
    std::ofstream f(tempPath, std::ios::trunc);
    if (!f.is_open())
      return false;
    f << ss.str();
    if (!f.good())
      return false;
  }

  // Hidden files can't be replaced by MoveFileEx; clear the flag first.
  SetFileAttributesW(path.c_str(), FILE_ATTRIBUTE_NORMAL);
  // Single replace step: a crash can never leave us without the profile.
  bool ok = MoveFileExW(tempPath.c_str(), path.c_str(),
                        MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) != 0;
  SetFileAttributesW(path.c_str(), FILE_ATTRIBUTE_HIDDEN);
  return ok;
}

std::vector<Profile> GetProfiles(const std::wstring &directory) {
  std::vector<Profile> profiles;
  WIN32_FIND_DATAW findData;
  std::wstring searchPath = directory + L"/*.json";
  HANDLE hFind = FindFirstFileW(searchPath.c_str(), &findData);

  if (hFind != INVALID_HANDLE_VALUE) {
    do {
      // last_calibrated.json is a backup copy of the active profile; loading
      // it would list that profile twice.
      if (!(findData.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) &&
          _wcsicmp(findData.cFileName, L"last_calibrated.json") != 0 &&
          _wcsicmp(findData.cFileName, L"settings.json") != 0) {
        Profile p;
        if (p.Load(directory + findData.cFileName)) {
          profiles.push_back(p);
        }
      }
    } while (FindNextFileW(hFind, &findData));
    FindClose(hFind);
  }

  return profiles;
}
