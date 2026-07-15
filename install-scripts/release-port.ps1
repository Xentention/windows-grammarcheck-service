param(
    [Parameter(Mandatory = $true)]
    [int]$Port
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Remove the persistent excluded TCP port range reserved by reserve-port.ps1.
$netsh = Start-Process -FilePath 'netsh.exe' -ArgumentList @(
    'int', 'ipv4', 'delete', 'excludedportrange',
    'protocol=tcp',
    "startport=$Port",
    'numberofports=1',
    'store=persistent'
) -Wait -NoNewWindow -PassThru

# Non-zero is non-fatal: the range may already be gone.
if ($netsh.ExitCode -ne 0) {
    Write-Host "netsh delete excludedportrange for $Port returned $($netsh.ExitCode) (already released?)"
}
