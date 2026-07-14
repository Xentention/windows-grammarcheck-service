param(
    [Parameter(Mandatory=$true)]
    [string]$InstallDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$ahkSource = Join-Path $InstallDir 'hotkeys.ahk'
$ahkDir    = Join-Path $env:LOCALAPPDATA 'RuGrammarCheck'
$ahkExe    = Join-Path $ahkDir 'AutoHotkey64.exe'
$ahkScript = Join-Path $ahkDir 'hotkeys.ahk'
$taskName  = 'RuGrammarCheckHotkeys'
if (-not (Test-Path $ahkExe)) {
    New-Item -ItemType Directory -Force -Path $ahkDir | Out-Null
    $ahkZip = Join-Path $env:TEMP 'AutoHotkey.zip'
    Invoke-WebRequest -Uri 'https://github.com/AutoHotkey/AutoHotkey/releases/download/v2.0.26/AutoHotkey_2.0.26.zip' -OutFile $ahkZip
    Expand-Archive -Path $ahkZip -DestinationPath $ahkDir -Force
    if (-not (Test-Path $ahkExe)) {
        $candidates = Get-ChildItem $ahkDir -Filter 'AutoHotkey*.exe' | Sort-Object Name
        if ($candidates) {
            Rename-Item $candidates[0].FullName 'AutoHotkey64.exe' -Force
        }
    }
}

Copy-Item -LiteralPath $ahkSource -Destination $ahkScript -Force

$action = New-ScheduledTaskAction -Execute $ahkExe -Argument "`"$ahkScript`""
$trigger = New-ScheduledTaskTrigger -AtLogon
$settings = New-ScheduledTaskSettingsSet -Hidden -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -RunOnlyIfNetworkAvailable:$false
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null

Start-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue