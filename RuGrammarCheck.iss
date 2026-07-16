#define RuGrammarCheckName "RuGrammarCheck"
#define RuGrammarCheckURL "https://github.com/Xentention/windows-grammarcheck-service"
#define RuGrammarCheckExeName "RuGrammarCheck.exe"

#ifndef RuGrammarCheckVersion
  #define RuGrammarCheckVersion "unknown"
#endif

#ifndef OutputBaseName
  #define OutputBaseName "RuGrammarCheck-Setup"
#endif

[Setup]
AppId={{BE32D788-8D76-46A7-9F33-429F2552E0BA}
AppName={#RuGrammarCheckName}
AppVersion={#RuGrammarCheckVersion}
AppPublisherURL={#RuGrammarCheckURL}
AppSupportURL={#RuGrammarCheckURL}
AppUpdatesURL={#RuGrammarCheckURL}
DefaultDirName={commonappdata}\{#RuGrammarCheckName}
; Locked: hotkeys.ahk / clipboard scripts assume the default location.
DisableDirPage=yes
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#RuGrammarCheckExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
SolidCompression=yes
WizardStyle=modern
OutputBaseFilename={#OutputBaseName}
OutputDir=output
SetupIconFile=icons\app.ico

[Languages]
Name: "en"; MessagesFile: "compiler:Default.isl"
Name: "ru"; MessagesFile: "compiler:Languages\Russian.isl"

[CustomMessages]
en.HotkeyPageLabel=Bind hotkeys?
en.HotkeyPageDesc=Bind Ctrl+Win+Shift+Alt+C and Ctrl+Shift+Alt+Z to correction and revertion?
en.HotkeyOpt=Enable hotkeys
ru.HotkeyPageLabel=Включить горячие клавиши?
ru.HotkeyPageDesc=Привязать Ctrl+Win+Shift+Alt+C и Ctrl+Shift+Alt+Z к действиям исправить и отменить исправление?
ru.HotkeyOpt=Включить горячие клавиши

[Files]
; Build from PyInstaller
Source: "dist\RuGrammarCheck\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; AutoHotkey runtime (expanded at install time by create-hotkeys.ps1)
Source: "ahk.zip"; DestDir: "{app}"; Flags: ignoreversion

; Web UI launcher (resolves the dynamic port at click time)
Source: "open-ui.vbs"; DestDir: "{app}"; Flags: ignoreversion

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"

[Icons]
Name: "{commonprograms}\{#RuGrammarCheckName}"; Filename: "{app}\open-ui.vbs"; IconFilename: "{app}\{#RuGrammarCheckExeName}"
Name: "{commondesktop}\{#RuGrammarCheckName}"; Filename: "{app}\open-ui.vbs"; IconFilename: "{app}\{#RuGrammarCheckExeName}"; Tasks: desktopicon

[Code]
var
  HotkeyPage: TInputOptionWizardPage;

function ShouldEnableHotkeys: Boolean;
begin
  Result := HotkeyPage.Values[0];
end;

procedure InitializeWizard;
begin
  // Hotkeys
  HotkeyPage := CreateInputOptionPage(
    wpSelectDir,
    ExpandConstant('{cm:HotkeyPageLabel}'),
    ExpandConstant('{cm:HotkeyPageDesc}'),
    '',
    False,
    False
  );
  HotkeyPage.Add(ExpandConstant('{cm:HotkeyOpt}'));
  HotkeyPage.Values[0] := True;
end;

function RunPs1(const ScriptName, Args: string): Integer;
var
  ResultCode: Integer;
  CmdLine: string;
begin
  CmdLine := '-NoProfile -ExecutionPolicy Bypass -File "' +
             ExpandConstant('{app}\') + ScriptName + '" ' + Args;
  if ShellExec('', 'powershell.exe', CmdLine, '', SW_HIDE, ewWaitUntilTerminated, ResultCode) then
    Result := ResultCode
  else
    Result := -1;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  Rc: Integer;
  AppDir: string;
begin
  if CurStep = ssPostInstall then
  begin
    AppDir := ExpandConstant('{app}');

    Rc := RunPs1('install-service.ps1', '-InstallDir "' + AppDir + '"');
    if Rc <> 0 then
      MsgBox('Service installation failed (code ' + IntToStr(Rc) + ').' + #13#10 +
             'Check logs in ' + AppDir + '\logs\RuGrammarCheck.', mbError, MB_OK);

    if ShouldEnableHotkeys then
    begin
      Rc := RunPs1('install-scripts\create-hotkeys.ps1', '-InstallDir "' + AppDir + '"');
      if Rc <> 0 then
        MsgBox('Hotkey setup failed (code ' + IntToStr(Rc) + '). The service still works ' +
               'via the web UI.', mbInformation, MB_OK);
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
var
  Rc: Integer;
begin
  if CurUninstallStep = usUninstall then
  begin
    Rc := RunPs1('uninstall-service.ps1', '-InstallDir "' + ExpandConstant('{app}') + '"');
    Rc := RunPs1('install-scripts\remove-hotkeys.ps1', '-InstallDir "' + ExpandConstant('{app}') + '"');
  end;
end;