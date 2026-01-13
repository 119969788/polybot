# PolyBot 启动脚本（Windows PowerShell）
# 使用此脚本可以确保环境变量正确传递

# 设置私钥（如果需要）
$env:POLYMARKET_PRIVATE_KEY="0xd4ae880287b31d8316f31e938a4bb50d6260d765229076be83d8fa7962f2531b"

# 显示配置信息
Write-Host "╔════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║      PolyBot 启动脚本                     ║" -ForegroundColor Cyan
Write-Host "╚════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""
Write-Host "🔑 私钥状态: " -NoNewline
if ($env:POLYMARKET_PRIVATE_KEY) {
    Write-Host "✅ 已设置 (长度: $($env:POLYMARKET_PRIVATE_KEY.Length) 字符)" -ForegroundColor Green
} else {
    Write-Host "❌ 未设置" -ForegroundColor Red
}
Write-Host ""

# 运行程序
npm start
