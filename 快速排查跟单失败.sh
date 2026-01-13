#!/bin/bash

# 快速排查跟单失败问题

echo "╔════════════════════════════════════════════╗"
echo "║      跟单失败快速排查工具                  ║"
echo "╚════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="${1:-/opt/polybot}"
cd "$PROJECT_DIR" || exit 1

echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 1. 运行诊断工具
echo "🔍 步骤 1: 运行诊断工具..."
if [ -f "诊断跟单失败.js" ]; then
    node 诊断跟单失败.js
else
    echo "   ⚠️  诊断工具不存在，跳过"
fi
echo ""

# 2. 查看最新错误日志
echo "🔍 步骤 2: 查看最新错误日志..."
if command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "polybot"; then
        echo "   最近 50 行日志:"
        pm2 logs polybot --lines 50 --nostream | grep -i "失败\|失败\|error\|错误" | tail -20
    else
        echo "   ⚠️  PM2 进程不存在"
    fi
else
    echo "   ⚠️  未安装 PM2"
fi
echo ""

# 3. 检查配置
echo "🔍 步骤 3: 检查关键配置..."
if [ -f "config.js" ]; then
    echo "   订单类型:"
    grep -A 1 "orderType" config.js | head -2 || echo "     未找到"
    
    echo "   滑点容忍度:"
    grep -A 1 "maxSlippage" config.js | head -2 || echo "     未找到"
    
    echo "   最大单笔金额:"
    grep -A 1 "maxSizePerTrade" config.js | head -2 || echo "     未找到"
    
    echo "   测试模式:"
    grep -A 1 "dryRun" config.js | head -2 || echo "     未找到"
else
    echo "   ❌ config.js 不存在"
fi
echo ""

# 4. 检查网络连接
echo "🔍 步骤 4: 测试网络连接..."
if curl -s --max-time 10 -I https://polymarket.com > /dev/null 2>&1; then
    echo "   ✅ 网络连接正常"
else
    echo "   ❌ 网络连接失败"
    echo "   💡 建议：配置代理"
fi
echo ""

# 5. 检查文件完整性
echo "🔍 步骤 5: 检查文件完整性..."
for file in "src/WalletFollower.js" "config.js" "index.js"; do
    if [ -f "$file" ]; then
        if node --check "$file" 2>/dev/null; then
            echo "   ✅ $file"
        else
            echo "   ❌ $file - 语法错误"
        fi
    else
        echo "   ❌ $file - 不存在"
    fi
done
echo ""

# 6. 总结和建议
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 快速修复建议:"
echo ""
echo "1. 如果订单类型是 FOK，改为 FAK:"
echo "   orderType: 'FAK',"
echo ""
echo "2. 如果滑点过小，增加到 5%:"
echo "   maxSlippage: 0.05,"
echo ""
echo "3. 检查账户余额是否充足"
echo ""
echo "4. 查看详细日志:"
echo "   pm2 logs polybot --lines 100"
echo ""
echo "5. 运行完整诊断:"
echo "   node 诊断跟单失败.js"
echo ""
