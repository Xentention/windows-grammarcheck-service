Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, 0)
$listener.Start()
try {
    $port = $listener.LocalEndpoint.Port
}
finally {
    $listener.Stop()
}

$netsh = Start-Process -FilePath "netsh.exe" -ArgumentList @(
    'int','ipv4','add','excludedportrange',
    'protocol=tcp',
    "startport=$port",
    'numberofports=1',
    'store=persistent'
) -Wait -NoNewWindow -PassThru
if ($netsh.ExitCode -ne 0) {
    throw "netsh failed to reserve port $port (exit $($netsh.ExitCode))."
}

Write-Output $port