#!/bin/bash

# 腾讯云服务器一键更新脚本
# 自动更新代码、验证、重启服务

echo "╔════════════════════════════════════════════╗"
echo "║      PolyBot 服务器一键更新脚本            ║"
echo "╚════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="${1:-/opt/polybot}"
cd "$PROJECT_DIR" || exit 1

echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 1. 备份配置
echo "📦 备份配置文件..."
BACKUP_FILE="config.js.backup.$(date +%Y%m%d_%H%M%S)"
cp config.js "$BACKUP_FILE" 2>/dev/null || true
echo "✅ 已备份到: $BACKUP_FILE"
echo ""

# 2. 检查 Git 仓库
if [ -d ".git" ]; then
    echo "📥 从 Git 拉取最新代码..."
    git fetch origin
    
    # 检查是否有更新
    LOCAL=$(git rev-parse HEAD)
    REMOTE=$(git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null || echo "")
    
    if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
        echo "   发现新版本，正在更新..."
        git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || {
            echo "❌ Git 拉取失败"
            exit 1
        }
        echo "✅ 代码更新成功"
    else
        echo "✅ 代码已是最新版本"
    fi
else
    echo "⚠️  不是 Git 仓库，跳过自动拉取"
    echo "💡 如需更新，请手动上传文件"
fi
echo ""

# 3. 检查必需文件
echo "🔍 检查必需文件..."
MISSING=0
for file in "src/ProfitTracker.js" "src/WalletFollower.js" "config.js" "index.js"; do
    if [ -f "$file" ]; then
        echo "   ✅ $file"
    else
        echo "   ❌ $file - 缺失"
        MISSING=1
    fi
done

if [ $MISSING -eq 1 ]; then
    echo ""
    echo "❌ 缺少必需文件，请先上传文件"
    exit 1
fi
echo ""

# 4. 验证语法
echo "🔍 验证代码语法..."
ERRORS=0

if node --check src/ProfitTracker.js 2>/dev/null; then
    echo "   ✅ ProfitTracker.js 语法正确"
else
    echo "   ❌ ProfitTracker.js 语法错误"
    ERRORS=1
fi

if node --check src/WalletFollower.js 2>/dev/null; then
    echo "   ✅ WalletFollower.js 语法正确"
else
    echo "   ❌ WalletFollower.js 语法错误"
    ERRORS=1
fi

if node --check config.js 2>/dev/null; then
    echo "   ✅ config.js 语法正确"
else
    echo "   ❌ config.js 语法错误"
    ERRORS=1
fi

if [ $ERRORS -eq 1 ]; then
    echo ""
    echo "⚠️  发现语法错误，但继续更新..."
fi
echo ""

# 5. 检查配置
echo "🔍 检查配置..."
if grep -q "orderType.*FAK" config.js; then
    echo "   ✅ orderType: FAK（已优化）"
else
    echo "   ⚠️  orderType: 未设置为 FAK"
fi

if grep -q "maxSlippage.*0.05" config.js; then
    echo "   ✅ maxSlippage: 0.05（5%）"
else
    echo "   ⚠️  maxSlippage: 未设置为 0.05"
fi

if grep -q "profitTracking" config.js; then
    echo "   ✅ profitTracking: 已配置"
else
    echo "   ⚠️  profitTracking: 未配置（可选）"
fi
echo ""

# 6. 创建数据目录
echo "📁 创建数据目录..."
mkdir -p data
chmod 755 data
if [ -d "data" ]; then
    echo "   ✅ data/ 目录已准备"
else
    echo "   ❌ 无法创建 data/ 目录"
    exit 1
fi
echo ""

# 7. 安装依赖（如果需要）
if [ -f "package.json" ] && [ "package.json" -nt "node_modules" ] 2>/dev/null; then
    echo "📦 安装/更新依赖..."
    npm install --silent 2>/dev/null || {
        echo "   ⚠️  依赖安装失败，但继续运行"
    }
    echo ""
fi

# 8. 重启服务
echo "🔄 重启服务..."

if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "polybot"; then
        echo "   使用 PM2 重启..."
        pm2 restart polybot
        
        sleep 2
        
        if pm2 list | grep "polybot" | grep -q "online"; then
            echo "   ✅ 服务重启成功"
            echo ""
            echo "📋 服务状态:"
            pm2 list | grep polybot
        else
            echo "   ❌ 服务重启失败"
            echo "   💡 查看日志: pm2 logs polybot"
            exit 1
        fi
    else
        echo "   ⚠️  PM2 进程 'polybot' 不存在"
        echo "   💡 请手动启动: pm2 start index.js --name polybot"
    fi
else
    echo "   ℹ️  未安装 PM2，请手动重启服务"
    echo "   💡 运行: npm start"
fi
echo ""

# 9. 完成
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 更新完成！"
echo ""
echo "📋 更新摘要:"
echo "   项目目录: $PROJECT_DIR"
echo "   备份文件: $BACKUP_FILE"
echo "   服务状态: $(pm2 list | grep polybot | awk '{print $10}' 2>/dev/null || echo 'N/A')"
echo ""
echo "💡 查看日志:"
echo "   pm2 logs polybot --lines 50"
echo ""
