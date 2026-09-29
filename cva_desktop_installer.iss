; Keep in sync with pubspec.yaml `version:` (without the +build suffix)
; and UpdateService.currentVersion.
#define MyAppVersion "1.0.34"
#define MyAppName "CVA Desktop"
#define MyAppExeName "covenant_va_desktop.exe"
; Flutter Windows build output, relative to this script's folder.
#define MyBuildDir AddBackslash(SourcePath) + "build\windows\x64\runner\Release"

[Setup]
; AppId identifies this app to Windows/Inno Setup across upgrades.
; NEVER change it once a release has shipped with it.
AppId={{EB314A9B-C99C-4CA6-A6BE-E2DE82DB010B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
VersionInfoVersion={#MyAppVersion}
AppPublisher=Covenant VA
AppPublisherURL=https://covenant-va.com
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
OutputDir=Output
OutputBaseFilename=CVA-Desktop-Setup-v{#MyAppVersion}
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
DisableProgramGroupPage=yes

[Files]
Source: "{#MyBuildDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon
Name: "{userstartmenu}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; App data written by the Flutter app (shared_preferences, secure storage,
; caches): %APPDATA%\<CompanyName>\<ProductName> from windows\runner\Runner.rc
Type: filesandordirs; Name: "{userappdata}\Covenant VA\CVA Desktop"
Type: dirifempty; Name: "{userappdata}\Covenant VA"

[Code]
// Releases up to v1.0.34 had no AppId, so Inno Setup registered them under the
// AppName ("CVA Desktop_is1"). Silently remove such a legacy install before
// installing so users don't end up with two entries in Apps & Features.
// The legacy uninstaller has no [UninstallDelete], so user data is kept.
function GetLegacyUninstallString(): String;
var
  Key: String;
begin
  Result := '';
  Key := 'Software\Microsoft\Windows\CurrentVersion\Uninstall\CVA Desktop_is1';
  if not RegQueryStringValue(HKCU, Key, 'UninstallString', Result) then
    RegQueryStringValue(HKLM, Key, 'UninstallString', Result);
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  UninstallString: String;
  ResultCode: Integer;
begin
  if CurStep = ssInstall then
  begin
    UninstallString := RemoveQuotes(GetLegacyUninstallString());
    if (UninstallString <> '') and FileExists(UninstallString) then
      Exec(UninstallString, '/VERYSILENT /NORESTART /SUPPRESSMSGBOXES', '',
        SW_HIDE, ewWaitUntilTerminated, ResultCode);
  end;
end;
