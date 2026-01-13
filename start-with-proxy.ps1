# PolyBot 代理启动脚本（Windows PowerShell）

Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      PolyBot 代理配置启动脚本              ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ===== 代理配置 =====
# 请根据您的实际代理软件修改以下配置

# 常见代理软件默认端口：
# Clash: HTTP 端口 7890, SOCKS5 端口 7890
# V2Ray: HTTP 端口 10809, SOCKS5 端口 10808
# Shadowsocks: SOCKS5 端口 1080
# 系统代理: 通常 8080 或 1080

# Clash 默认端口（已测试可用）
$PROXY_HOST = "127.0.0.1"
$PROXY_PORT = "7890"  # ✅ 已确认此端口可用
$PROXY_URL = "http://$PROXY_HOST`:$PROXY_PORT"

# 如果需要使用 SOCKS5（Clash 通常也支持）
# $PROXY_URL = "socks5://127.0.0.1:7890"

# 如果需要认证（用户名和密码）
# $PROXY_URL = "http://username:password@127.0.0.1:7890"

# V2Ray 示例（如果使用 V2Ray）
# $PROXY_URL = "http://127.0.0.1:10809"

# 请根据您的实际代理软件修改上面的配置

Write-Host "📋 代理配置:" -ForegroundColor Yellow
Write-Host "   代理地址: $PROXY_URL"
Write-Host ""

# ===== 设置环境变量 =====
Write-Host "🔧 设置代理环境变量..." -ForegroundColor Yellow
$env:HTTP_PROXY = $PROXY_URL
$env:HTTPS_PROXY = $PROXY_URL
$env:http_proxy = $PROXY_URL
$env:https_proxy = $PROXY_URL

# 同时设置 no_proxy（如果需要绕过某些地址）
$env:NO_PROXY = "localhost,127.0.0.1"
$env:no_proxy = "localhost,127.0.0.1"

Write-Host "✅ 代理环境变量已设置"
Write-Host ""

# ===== 测试代理连接 =====
Write-Host "🧪 测试代理连接..." -ForegroundColor Yellow
try {
    $testUrl = "https://polymarket.com"
    Write-Host "   测试 URL: $testUrl" -NoNewline
    
    $response = Invoke-WebRequest -Uri $testUrl -Proxy $PROXY_URL -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    Write-Host " ✅ 成功 (状态码: $($response.StatusCode))" -ForegroundColor Green
    Write-Host ""
} catch {
    Write-Host " ❌ 失败" -ForegroundColor Red
    Write-Host "   错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "⚠️  警告: 代理连接测试失败，但继续尝试运行程序" -ForegroundColor Yellow
    Write-Host "💡 提示: 请检查代理地址和端口是否正确，或代理软件是否已启动" -ForegroundColor Yellow
    Write-Host ""
    
    # 询问是否继续
    $continue = Read-Host "是否继续运行程序？(Y/N)"
    if ($continue -ne "Y" -and $continue -ne "y") {
        Write-Host "已取消运行" -ForegroundColor Yellow
        exit
    }
    Write-Host ""
}

# ===== 设置私钥（如果还没有设置） =====
if (-not $env:POLYMARKET_PRIVATE_KEY) {
    Write-Host "🔑 检查私钥..." -ForegroundColor Yellow
    Write-Host "   未在环境变量中找到私钥" -ForegroundColor Gray
    Write-Host "   将从 config.js 读取私钥" -ForegroundColor Gray
    Write-Host ""
}

# ===== 运行程序 =====
Write-Host "🚀 启动 PolyBot..." -ForegroundColor Cyan
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Gray
Write-Host ""

# 切换到项目目录
Set-Location $PSScriptRoot

# 运行程序
npm start
