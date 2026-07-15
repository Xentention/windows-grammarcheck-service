#define RuGrammarCheckName "RuGrammarCheck"
#define RuGrammarCheckURL "https://github.com/Xentention/windows-grammarcheck-service"
#define RuGrammarCheckExeName "RuGrammarCheck.exe"

#ifndef RuGrammarCheckVersion
  #define RuGrammarCheckVersion "unknown"
#endif

[Setup]
AppId={{BE32D788-8D76-46A7-9F33-429F2552E0BA}
AppName={#RuGrammarCheckName}
AppVersion={#RuGrammarCheckVersion}
AppPublisherURL={#RuGrammarCheckURL}
AppSupportURL={#RuGrammarCheckURL}
AppUpdatesURL={#RuGrammarCheckURL}
DefaultDirName={commonappdata}\{#RuGrammarCheckName}
DisableDirPage=no
DisableProgramGroupPage=yes
UninstallDisplayIcon={app}\{#RuGrammarCheckExeName}
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
PrivilegesRequired=admin
SolidCompression=yes
WizardStyle=modern
OutputBaseFilename={#RuGrammarCheckName}-Setup
OutputDir=output

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
; Build from PyInstaller (includes both model folders)
Source: "dist\RuGrammarCheck\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Install scripts (root: install-service.ps1, uninstall-service.ps1, etc.)
Source: "install-scripts\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Clipboard scripts
Source: "clipboard\*"; DestDir: "{app}\clipboard"; Flags: ignoreversion recursesubdirs createallsubdirs

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

procedure RunPs1(const ScriptName, Args: string);
var
  ResultCode: Integer;
  CmdLine: string;
begin
  CmdLine := '-NoProfile -ExecutionPolicy Bypass -File "' +
             ExpandConstant('{app}\') + ScriptName + '" ' + Args;
  ShellExec(
    '',
    'powershell.exe',
    CmdLine,
    '',
    SW_HIDE,
    ewWaitUntilTerminated,
    ResultCode
  );
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    RunPs1(
      'install-service.ps1',
      '-InstallDir "' + ExpandConstant('{app}') + '"'
    );

    if ShouldEnableHotkeys then
    begin
      RunPs1(
        'install-scripts\create-hotkeys.ps1',
        '-InstallDir "' + ExpandConstant('{app}') + '"'
      );
    end;
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usUninstall then
  begin
    RunPs1(
      'uninstall-service.ps1',
      '-InstallDir "' + ExpandConstant('{app}') + '"'
    );

    RunPs1(
      'install-scripts\remove-hotkeys.ps1',
      '-InstallDir "' + ExpandConstant('{app}') + '"'
    );
  end;
end;