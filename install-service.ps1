param(
    [Parameter(Mandatory=$true)]
    [string]$InstallDir,
    [Parameter(Mandatory=$true)]
    [string]$QuantModel
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$serviceName = 'RuGrammarCheck'
$nssm = Join-Path $InstallDir 'nssm.exe'
$exe = Join-Path $InstallDir 'RuGrammarCheck.exe'
$envFile = Join-Path $InstallDir '.env'
$logsDir = Join-Path $InstallDir 'logs'
$serviceLogsDir = Join-Path $logsDir $serviceName

New-Item -ItemType Directory -Force -Path $serviceLogsDir | Out-Null

$port = & (Join-Path $InstallDir 'install-scripts\reserve-port.ps1')

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$lines = @()
if (Test-Path $envFile) {
    $lines = [IO.File]::ReadAllLines($envFile, [Text.Encoding]::UTF8)
}

$map = [ordered]@{}
foreach ($line in $lines) {
    if ($line -match '^\s*#' -or [string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '^(.*?)=(.*)$') { $map[$matches[1].Trim()] = $matches[2].Trim() }
}
$map['PORT'] = "$port"
$map['QUANT_MODEL'] = $QuantModel

$out = $map.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }
[IO.File]::WriteAllText($envFile, ($out -join "`r`n"), $utf8NoBom)

& $nssm install $serviceName $exe
& $nssm set $serviceName AppDirectory $InstallDir
& $nssm set $serviceName DisplayName $serviceName
& $nssm set $serviceName Description "Локальный сервис для исправления орфографии и пунктуации русского текста"
& $nssm set $serviceName Start SERVICE_AUTO_START
& $nssm set $serviceName AppEnvironmentExtra "PORT=$port`0QUANT_MODEL=$QuantModel"
& $nssm set $serviceName AppStdout (Join-Path $serviceLogsDir 'stdout.log')
& $nssm set $serviceName AppStderr (Join-Path $serviceLogsDir 'stderr.log')
& $nssm set $serviceName AppRotateFiles 1
& $nssm set $serviceName AppRotateOnline 1
& $nssm set $serviceName AppRotateBytes 10485760
& $nssm start $serviceName