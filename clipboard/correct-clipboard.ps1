. "$PSScriptRoot\_common.ps1"

$original = Read-ClipboardText
if ([string]::IsNullOrWhiteSpace($original)) {
    Notify-Error 'clipboard is empty'
    exit 1
}

Save-Text $LastInputFile $original

try {
    $corrected = Invoke-Correction $original
    Write-ClipboardText $corrected 
    Notify-Success
}
catch {
    Notify-Error $_.Exception.Message
    exit 1
}
