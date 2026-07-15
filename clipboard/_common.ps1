Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$GcHost = if ($env:GRAMMARCHECK_HOST) { $env:GRAMMARCHECK_HOST } else { '127.0.0.1' }

$PortFile = Join-Path $env:ProgramData 'RuGrammarCheck\port'
$GcPort =
    if (Test-Path -LiteralPath $PortFile) { (Get-Content -LiteralPath $PortFile -Raw).Trim() }
    elseif ($env:PORT) { $env:PORT }
    else { '8501' }

$BaseUrl = if ($env:GRAMMARCHECK_URL) { $env:GRAMMARCHECK_URL } else { "http://${GcHost}:${GcPort}" }

$StateDir = if ($env:GRAMMARCHECK_STATE_DIR) { $env:GRAMMARCHECK_STATE_DIR } else { Join-Path $env:LOCALAPPDATA 'grammarcheck' }
if (-not (Test-Path -LiteralPath $StateDir)) { New-Item -ItemType Directory -Path $StateDir -Force | Out-Null }
$LastInputFile = Join-Path $StateDir 'last_input.txt'

$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Read-ClipboardText { Get-Clipboard -Raw }
function Write-ClipboardText { param([string]$Text) Set-Clipboard -Value $Text }

function Save-Text { param([string]$Path, [string]$Text) [IO.File]::WriteAllText($Path, $Text, $Utf8NoBom) }
function Load-Text { param([string]$Path) [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8) }

# --- HTTP: POST /correct with explicit UTF-8 both ways ------------------------
function Invoke-Correction {
    param([string]$Text)
    # ConvertTo-Json escapes non-ASCII -> body is ASCII-safe JSON.
    $json = @{ text = $Text } | ConvertTo-Json -Compress
    $bytes = [Text.Encoding]::UTF8.GetBytes($json)
    $resp = Invoke-WebRequest -Uri "$BaseUrl/correct" -Method Post `
        -ContentType 'application/json; charset=utf-8' -Body $bytes -UseBasicParsing
    $decoded = [Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    return ($decoded | ConvertFrom-Json).corrected
}

function Notify-Success { [System.Media.SystemSounds]::Asterisk.Play(); Write-Host 'grammarcheck: OK' }
function Notify-Error {
    param([string]$Message)
    [System.Media.SystemSounds]::Hand.Play()
    Write-Host "grammarcheck: ERROR - $Message" -ForegroundColor Red
}
