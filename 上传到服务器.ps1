# 上传诊断工具到服务器的 PowerShell 脚本
# 使用方法: .\上传到服务器.ps1 user@server-ip

param(
    [Parameter(Mandatory=$true)]
    [string]$ServerAddress
)

$ProjectDir = "/opt/polybot"

Write-Host "╔════════════════════════════════════════════╗"
Write-Host "║      上传诊断工具到服务器                  ║"
Write-Host "╚════════════════════════════════════════════╝"
Write-Host ""

# 检查文件是否存在
if (-not (Test-Path "diagnose-failures.js")) {
    Write-Host "❌ 错误: diagnose-failures.js 文件不存在" -ForegroundColor Red
    Write-Host "💡 请确保在项目根目录执行此脚本" -ForegroundColor Yellow
    exit 1
}

Write-Host "📤 上传文件到: $ServerAddress:$ProjectDir" -ForegroundColor Cyan
Write-Host ""

try {
    # 上传诊断工具
    Write-Host "📤 上传 diagnose-failures.js..." -ForegroundColor Yellow
    scp diagnose-failures.js "${ServerAddress}:${ProjectDir}/"
    Write-Host "✅ diagnose-failures.js 上传成功" -ForegroundColor Green
    
    # 可选：上传其他文件
    if (Test-Path "src/WalletFollower.js") {
        Write-Host ""
        Write-Host "📤 上传 src/WalletFollower.js（改进版本）..." -ForegroundColor Yellow
        scp src/WalletFollower.js "${ServerAddress}:${ProjectDir}/src/"
        Write-Host "✅ WalletFollower.js 上传成功" -ForegroundColor Green
    }
    
    if (Test-Path "package.json") {
        Write-Host ""
        Write-Host "📤 上传 package.json（更新版本）..." -ForegroundColor Yellow
        scp package.json "${ServerAddress}:${ProjectDir}/"
        Write-Host "✅ package.json 上传成功" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host "✅ 上传完成！" -ForegroundColor Green
    Write-Host ""
    Write-Host "💡 在服务器上运行以下命令验证:" -ForegroundColor Yellow
    Write-Host "   ssh $ServerAddress" -ForegroundColor White
    Write-Host "   cd $ProjectDir" -ForegroundColor White
    Write-Host "   node --check diagnose-failures.js" -ForegroundColor White
    Write-Host "   node diagnose-failures.js" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "❌ 上传失败: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 替代方案:" -ForegroundColor Yellow
    Write-Host "   1. 使用 Git（如果使用版本控制）" -ForegroundColor White
    Write-Host "   2. 在服务器上使用 cat 手动创建文件" -ForegroundColor White
    Write-Host "   3. 运行: bash 服务器上创建诊断工具.sh" -ForegroundColor White
    exit 1
}
