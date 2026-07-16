param(
    [Parameter(Mandatory=$true)]
    [string]$InstallDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$taskName = 'RuGrammarCheckHotkeys'

Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

$ahkDir = Join-Path $env:LOCALAPPDATA 'RuGrammarCheck'
if (Test-Path $ahkDir) {
    Remove-Item -Recurse -Force -Path $ahkDir -ErrorAction SilentlyContinue
}