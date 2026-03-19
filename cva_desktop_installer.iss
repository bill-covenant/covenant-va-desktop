[Setup]
AppName=CVA Desktop
AppVersion=1.0.5
AppPublisher=Covenant VA
AppPublisherURL=https://covenant-va.com
DefaultDirName={autopf}\CVA Desktop
DefaultGroupName=CVA Desktop
OutputDir=Output
OutputBaseFilename=CVA-Desktop-Setup-v1.0.5
UninstallDisplayIcon={app}\covenant_va_desktop.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
DisableProgramGroupPage=yes

[Files]
Source: "C:\Users\USER\Desktop\covenant_va_desktop\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\CVA Desktop"; Filename: "{app}\covenant_va_desktop.exe"
Name: "{autodesktop}\CVA Desktop"; Filename: "{app}\covenant_va_desktop.exe"; Tasks: desktopicon
Name: "{userstartmenu}\CVA Desktop"; Filename: "{app}\covenant_va_desktop.exe"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\covenant_va_desktop.exe"; Description: "Launch CVA Desktop"; Flags: nowait postinstall skipifsilent