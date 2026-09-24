# BetterAngle Pro

A high-performance, low-latency angle tracker and FOV detection overlay for Windows.
## 🔧 How to use
- **Step 1:** Input your sensitivity from Fortnite
- **Step 2:** Hop into a Fortnite match and hit the Select ROI key. Select the area of the screen with the text (Make sure to add some extra room). Select the color you want to track (white in the text)
- **Step 3:** Change the Percent to Match how much of the area.


- **Low-End Hardware Support**: Minimal RAM (<60MB) and CPU usage (~0.5%).
- **Connected Updates**: Automated builds and releases via GitHub Actions.
- **Zero Latency**: Direct Win32 Raw Input and GDI+ rendering.

## 🛠 Features
- **Raw Input Tracking**: Captures mouse delta directly from the hardware.
- **ROI FOV Detector**: Automatically detects game states (Dive/Glide) using high-speed pixel scanning.
- **Transition Modes**: Choose how dive/glide transitions are handled — *Block input* (exact angle) or *Blend* (never touches your input; angle estimated if you move mid-transition). See [docs/INPUT_LOCK.md](docs/INPUT_LOCK.md).
- **Transparent Overlay**: Click-through, topmost UI that doesn't interfere with gameplay.
- **Auto-Updater**: Automatically stays up-to-date with the latest releases from GitHub.
- **Auto-Installer**: Automatically installs the latest version of the software.
- **No Ban Risk**: Doesn't touch the game files or memory.

## ⚠️ Warning
- **this tool does not provide any advantages**
- **do not use this software in competitive matches**
- **do not use this software in tournaments**
- **we are not responsible for any bans or consequences**

## 📦 Download
Check the **[Releases](https://github.com/wavedropmaps-org/BetterAngle/releases)** page for the latest `BetterAngle.exe`.

## ⚙️ Development
1. Clone the repository: `git clone https://github.com/wavedropmaps-org/BetterAngle.git`
2. Install Visual Studio 2022 (MSVC) and Qt 6.5.3 (`win64_msvc2019_64`).
3. Configure and build with CMake:
   ```
   cmake -B build -G "Visual Studio 17 2022" -A x64
   cmake --build build --config Release
   ```
Releases are built by GitHub Actions on every push to `main` (see `PROJECT_POLICY.md`).

---
*Created by [Fruss](https://github.com/wavedropmaps) & [MahanYTT](https://github.com/MahanYTT) & [itsdolphin](https://github.com/byu163) with ❤️*
