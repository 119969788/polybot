# Proxy Connection Test Script

Write-Host "Proxy Connection Test" -ForegroundColor Cyan
Write-Host ""

# Common proxy ports
$commonPorts = @(
    @{Name="Clash HTTP"; Port=7890; Type="http"},
    @{Name="Clash SOCKS5"; Port=7890; Type="socks5"},
    @{Name="V2Ray HTTP"; Port=10809; Type="http"},
    @{Name="V2Ray SOCKS5"; Port=10808; Type="socks5"},
    @{Name="Shadowsocks"; Port=1080; Type="socks5"},
    @{Name="System Proxy"; Port=8080; Type="http"}
)

$PROXY_HOST = "127.0.0.1"
$testUrl = "https://polymarket.com"

Write-Host "Testing common proxy ports..." -ForegroundColor Yellow
Write-Host ""

$foundProxy = $null

foreach ($proxy in $commonPorts) {
    $proxyUrl = if ($proxy.Type -eq "socks5") {
        "socks5://${PROXY_HOST}:$($proxy.Port)"
    } else {
        "http://${PROXY_HOST}:$($proxy.Port)"
    }
    
    Write-Host "  Testing $($proxy.Name) (port $($proxy.Port))..." -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $testUrl -Proxy $proxyUrl -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        Write-Host " OK! (Status: $($response.StatusCode))" -ForegroundColor Green
        $foundProxy = $proxy
        Write-Host ""
        Write-Host "Found working proxy:" -ForegroundColor Green
        Write-Host "  Name: $($proxy.Name)" -ForegroundColor Green
        Write-Host "  Port: $($proxy.Port)" -ForegroundColor Green
        Write-Host "  Type: $($proxy.Type)" -ForegroundColor Green
        Write-Host "  URL: $proxyUrl" -ForegroundColor Green
        Write-Host ""
        break
    } catch {
        Write-Host " Failed" -ForegroundColor Gray
    }
}

if ($foundProxy) {
    $proxyUrl = if ($foundProxy.Type -eq "socks5") {
        "socks5://${PROXY_HOST}:$($foundProxy.Port)"
    } else {
        "http://${PROXY_HOST}:$($foundProxy.Port)"
    }
    
    Write-Host "Setting proxy environment variables..." -ForegroundColor Cyan
    $env:HTTP_PROXY = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl
    $env:http_proxy = $proxyUrl
    $env:https_proxy = $proxyUrl
    
    Write-Host "Proxy configured: $proxyUrl" -ForegroundColor Green
    Write-Host ""
    Write-Host "You can now run:" -ForegroundColor Cyan
    Write-Host "  npm start" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "No working proxy found." -ForegroundColor Red
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Make sure your proxy software is running"
    Write-Host "  2. Check the HTTP proxy port in settings"
    Write-Host "  3. Edit start-with-proxy.ps1 and update the port"
    Write-Host ""
}
