[Setup]
AppId={{DA1CF62B-D790-488B-8A5E-49A8EDBBF1E3}
AppName=BetterAngle Pro
AppVersion={#AppVer}
AppPublisher=Mahan
AppPublisherURL=https://github.com/wavedropmaps/BetterAngle
AppSupportURL=https://github.com/wavedropmaps/BetterAngle
AppUpdatesURL=https://github.com/wavedropmaps/BetterAngle
DefaultDirName={autopf}\BetterAngle Pro
DisableProgramGroupPage=yes
PrivilegesRequired=admin
OutputDir=bin
OutputBaseFilename=BetterAngle_Setup
SetupIconFile=assets\BetterAngle_v162.ico
UninstallDisplayIcon={app}\assets\BetterAngle_v162.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern
CloseApplications=yes
RestartApplications=no

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Dirs]
Name: "{localappdata}\BetterAngle"; Permissions: users-modify
Name: "{app}"; Permissions: users-modify

[UninstallDelete]
Type: filesandordirs; Name: "{localappdata}\BetterAngle"
Type: filesandordirs; Name: "{userappdata}\BetterAngle"
Type: filesandordirs; Name: "{commonappdata}\BetterAngle"
Type: filesandordirs; Name: "{app}"

[Files]
Source: "build\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs
Source: "assets\BetterAngle_v162.ico"; DestDir: "{app}\assets"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\BetterAngle Pro"; Filename: "{app}\BetterAngle.exe"; IconFilename: "{app}\assets\BetterAngle_v162.ico"
Name: "{autodesktop}\BetterAngle Pro"; Filename: "{app}\BetterAngle.exe"; Tasks: desktopicon; IconFilename: "{app}\assets\BetterAngle_v162.ico"
Name: "{autoprograms}\BetterAngle Pro\Uninstall BetterAngle"; Filename: "{uninstallexe}"

[Run]
; Install Visual C++ Runtime silently before launching the app.
; Required on clean systems without Visual Studio installed.
Filename: "{app}\vc_redist.x64.exe"; Parameters: "/install /quiet /norestart"; StatusMsg: "Installing Visual C++ Runtime..."; Flags: waituntilterminated runhidden
Filename: "{app}\BetterAngle.exe"; Description: "{cm:LaunchProgram,BetterAngle Pro}"; Flags: nowait postinstall skipifsilent shellexec
