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