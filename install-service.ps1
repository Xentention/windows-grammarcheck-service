param(
    [Parameter(Mandatory = $true)]
    [string]$InstallDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$serviceName   = 'RuGrammarCheck'
$nssm          = Join-Path $InstallDir 'nssm.exe'
$exe           = Join-Path $InstallDir 'RuGrammarCheck.exe'
$envFile       = Join-Path $InstallDir '.env'
$logsDir       = Join-Path $InstallDir 'logs'
$serviceLogsDir = Join-Path $logsDir $serviceName

# --- Проверка базовых файлов ---
foreach ($path in $nssm, $exe) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Required file not found: $path"
    }
}

New-Item -ItemType Directory -Force -Path $serviceLogsDir | Out-Null

$port = & (Join-Path $InstallDir 'install-scripts\reserve-port.ps1')
if (-not $port) {
    throw "Failed to reserve port for service."
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$lines = @()
if (Test-Path -LiteralPath $envFile) {
    $lines = [IO.File]::ReadAllLines($envFile, [Text.Encoding]::UTF8)
}

$map = [ordered]@{}
foreach ($line in $lines) {
    if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '^(.*?)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        $map[$key] = $value
    }
}

$map['PORT'] = "$port"

$out = $map.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
[IO.File]::WriteAllText($envFile, ($out -join "`r`n"), $utf8NoBom)

Write-Host "Updated .env with PORT=$port"

$existing = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Removing existing service '$serviceName'..."
    & $nssm stop $serviceName 2>$null | Out-Null
    & $nssm remove $serviceName confirm 2>$null | Out-Null
    Start-Sleep -Seconds 1
}

Write-Host "Installing service '$serviceName'..."

$installResult = & $nssm install $serviceName $exe
if ($LASTEXITCODE -ne 0) {
    throw "NSSM install failed with exit code $LASTEXITCODE."
}

$sets = @(
    ('AppDirectory', $InstallDir),
    ('DisplayName', $serviceName),
    ('Description', 'Локальный сервис для исправления орфографии и пунктуации русского текста'),
    ('Start', 'SERVICE_AUTO_START'),
    ('AppEnvironmentExtra', "PORT=$port"),
    ('AppStdout', (Join-Path $serviceLogsDir 'stdout.log')),
    ('AppStderr', (Join-Path $serviceLogsDir 'stderr.log')),
    ('AppRotateFiles', '1'),
    ('AppRotateOnline', '1'),
    ('AppRotateBytes', '10485760')
)

foreach ($opt in $sets) {
    $key = $opt[0]
    $value = $opt[1]
    & $nssm set $serviceName $key $value
    if ($LASTEXITCODE -ne 0) {
        throw "NSSM set $key failed with exit code $LASTEXITCODE."
    }
}

Write-Host "Starting service '$serviceName'..."
& $nssm start $serviceName
if ($LASTEXITCODE -ne 0) {
    throw "NSSM start failed with exit code $LASTEXITCODE."
}

Start-Sleep -Seconds 2
$svc = Get-Service -Name $serviceName -ErrorAction Stop
if ($svc.Status -ne 'Running') {
    throw "Service '$serviceName' is not running (status: $($svc.Status)). Check logs in $serviceLogsDir"
}

Write-Host "Service '$serviceName' installed and running."