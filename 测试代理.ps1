# 代理连接测试脚本

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║           代理连接测试工具                  ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# 常见代理端口列表
$commonPorts = @(
    @{Name="Clash HTTP"; Port=7890; Type="http"},
    @{Name="Clash SOCKS5"; Port=7890; Type="socks5"},
    @{Name="Clash SOCKS5 Alt"; Port=7891; Type="socks5"},
    @{Name="V2Ray HTTP"; Port=10809; Type="http"},
    @{Name="V2Ray SOCKS5"; Port=10808; Type="socks5"},
    @{Name="Shadowsocks"; Port=1080; Type="socks5"},
    @{Name="系统代理"; Port=8080; Type="http"}
)

$PROXY_HOST = "127.0.0.1"
$testUrl = "https://polymarket.com"

Write-Host "🔍 自动检测可用代理端口..." -ForegroundColor Yellow
Write-Host ""

$foundProxy = $null

foreach ($proxy in $commonPorts) {
    $proxyUrl = if ($proxy.Type -eq "socks5") {
        "socks5://${PROXY_HOST}:$($proxy.Port)"
    } else {
        "http://${PROXY_HOST}:$($proxy.Port)"
    }
    
    Write-Host "   测试 $($proxy.Name) (端口 $($proxy.Port))..." -NoNewline
    
    try {
        $response = Invoke-WebRequest -Uri $testUrl -Proxy $proxyUrl -TimeoutSec 3 -UseBasicParsing -ErrorAction Stop
        Write-Host " ✅ 可用！(状态码: $($response.StatusCode))" -ForegroundColor Green
        $foundProxy = $proxy
        Write-Host ""
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        Write-Host "✅ 找到可用代理:" -ForegroundColor Green
        Write-Host "   名称: $($proxy.Name)" -ForegroundColor Green
        Write-Host "   端口: $($proxy.Port)" -ForegroundColor Green
        Write-Host "   类型: $($proxy.Type)" -ForegroundColor Green
        Write-Host "   URL: $proxyUrl" -ForegroundColor Green
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
        Write-Host ""
        break
    } catch {
        Write-Host " ❌ 不可用" -ForegroundColor Gray
    }
}

if (-not $foundProxy) {
    Write-Host ""
    Write-Host "❌ 未找到可用的代理端口" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 请手动配置代理:" -ForegroundColor Yellow
    Write-Host "   1. 打开您的代理软件（Clash/V2Ray/等）"
    Write-Host "   2. 查看 HTTP 代理端口（通常在设置中）"
    Write-Host "   3. 修改 start-with-proxy.ps1 中的端口配置"
    Write-Host ""
    Write-Host "常见端口:" -ForegroundColor Cyan
    Write-Host "   Clash: 7890"
    Write-Host "   V2Ray: 10809 (HTTP) 或 10808 (SOCKS5)"
    Write-Host "   Shadowsocks: 1080 (SOCKS5)"
    Write-Host ""
    
    # 询问是否手动输入端口
    $manual = Read-Host "是否手动输入代理端口？(Y/N)"
    if ($manual -eq "Y" -or $manual -eq "y") {
        $manualPort = Read-Host "请输入代理端口 (例如 7890)"
        if ($manualPort) {
            $manualUrl = "http://127.0.0.1:$manualPort"
            Write-Host ""
            Write-Host "测试端口 $manualPort..." -ForegroundColor Yellow
            try {
                $response = Invoke-WebRequest -Uri $testUrl -Proxy $manualUrl -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                Write-Host "✅ 端口 $manualPort 可用！(状态码: $($response.StatusCode))" -ForegroundColor Green
                Write-Host ""
                Write-Host "现在可以使用以下命令设置代理并运行:" -ForegroundColor Cyan
                Write-Host "`$env:HTTP_PROXY=`"$manualUrl`"" -ForegroundColor White
                Write-Host "`$env:HTTPS_PROXY=`"$manualUrl`"" -ForegroundColor White
                Write-Host "npm start" -ForegroundColor White
                Write-Host ""
            } catch {
                Write-Host "❌ 端口 $manualPort 不可用: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
} else {
    # 自动配置代理
    $proxyUrl = if ($foundProxy.Type -eq "socks5") {
        "socks5://${PROXY_HOST}:$($foundProxy.Port)"
    } else {
        "http://${PROXY_HOST}:$($foundProxy.Port)"
    }
    
    Write-Host "🚀 自动配置代理..." -ForegroundColor Cyan
    $env:HTTP_PROXY = $proxyUrl
    $env:HTTPS_PROXY = $proxyUrl
    $env:http_proxy = $proxyUrl
    $env:https_proxy = $proxyUrl
    
    Write-Host "✅ 代理已配置: $proxyUrl" -ForegroundColor Green
    Write-Host ""
    Write-Host "现在可以运行程序:" -ForegroundColor Cyan
    Write-Host "   npm start" -ForegroundColor White
    Write-Host ""
}
