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

Start-Process -FilePath "netsh.exe" -ArgumentList @(
    'int','ipv4','add','excludedportrange',
    'protocol=tcp',
    "startport=$port",
    'numberofports=1',
    'store=persistent'
) -Wait -NoNewWindow

Write-Output $port