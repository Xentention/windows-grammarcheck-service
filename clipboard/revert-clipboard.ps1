. "$PSScriptRoot\_common.ps1"

if (-not (Test-Path -LiteralPath $LastInputFile)) {
    Notify-Error 'no saved input to restore'
    exit 1
}

Write-ClipboardText (Load-Text $LastInputFile)
Notify-Success
