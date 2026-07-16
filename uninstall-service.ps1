param(
    [Parameter(Mandatory=$true)]
    [string]$InstallDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'SilentlyContinue'

$nssm = Join-Path $InstallDir 'nssm.exe'
$serviceName = 'RuGrammarCheck'

& $nssm stop $serviceName | Out-Null
& $nssm remove $serviceName confirm | Out-Null

# Release the reserved port range and remove the published port file.
$portFile = Join-Path $env:ProgramData 'RuGrammarCheck\port'
if (Test-Path -LiteralPath $portFile) {
    $port = (Get-Content -LiteralPath $portFile -Raw).Trim()
    if ($port -match '^\d+$') {
        & (Join-Path $InstallDir 'install-scripts\release-port.ps1') -Port ([int]$port)
    }
    Remove-Item -LiteralPath $portFile -Force
}