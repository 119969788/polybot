#!/bin/bash

# 快速修复实盘跟单失败的常见问题

PROJECT_DIR="${1:-/opt/polybot}"

echo "╔════════════════════════════════════════════╗"
echo "║      快速修复实盘跟单失败                  ║"
echo "╚════════════════════════════════════════════╝"
echo ""

cd "$PROJECT_DIR" || {
    echo "❌ 无法进入目录: $PROJECT_DIR"
    exit 1
}

echo "📁 当前目录: $(pwd)"
echo ""

# 备份配置文件
if [ -f "config.js" ]; then
    echo "📋 备份 config.js..."
    cp config.js config.js.bak
    echo "✅ 已备份为 config.js.bak"
    echo ""
else
    echo "❌ 未找到 config.js 文件"
    exit 1
fi

echo "🔧 应用推荐配置（提高成功率）..."
echo ""

# 使用 sed 修改配置（如果存在的话）
# 注意：这个脚本只做简单的替换，复杂情况建议手动编辑

# 1. 修改订单类型为 FAK（如果当前是 FOK）
if grep -q "orderType: 'FOK'" config.js; then
    echo "✅ 修改订单类型: FOK -> FAK"
    sed -i "s/orderType: 'FOK'/orderType: 'FAK'/" config.js
    sed -i 's/orderType: "FOK"/orderType: "FAK"/' config.js
fi

# 2. 检查滑点设置（如果小于 0.03，增加到 0.05）
if grep -q "maxSlippage: 0.0[12]" config.js; then
    echo "✅ 修改滑点容忍度: 增加至 0.05 (5%)"
    sed -i 's/maxSlippage: 0.01/maxSlippage: 0.05/' config.js
    sed -i 's/maxSlippage: 0.02/maxSlippage: 0.05/' config.js
fi

# 3. 确保自动跟单已启用
if grep -q "autoFollow: false" config.js; then
    echo "✅ 启用自动跟单"
    sed -i "s/autoFollow: false/autoFollow: true/" config.js
fi

echo ""
echo "📋 验证配置..."
echo ""

# 检查关键配置
echo "关键配置检查："
if grep -q "orderType: 'FAK'" config.js || grep -q 'orderType: "FAK"' config.js; then
    echo "   ✅ 订单类型: FAK"
else
    echo "   ⚠️  订单类型: 请检查（建议使用 FAK）"
fi

if grep -q "maxSlippage: 0.05" config.js; then
    echo "   ✅ 滑点容忍度: 0.05 (5%)"
else
    echo "   ⚠️  滑点容忍度: 请检查（建议 0.05）"
fi

if grep -q "autoFollow: true" config.js; then
    echo "   ✅ 自动跟单: 已启用"
else
    echo "   ⚠️  自动跟单: 请检查（必须启用）"
fi

if grep -q "dryRun: false" config.js; then
    echo "   ✅ 运行模式: 实盘模式"
else
    echo "   ⚠️  运行模式: 测试模式（实盘需要改为 false）"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 配置修改完成！"
echo ""
echo "💡 建议："
echo "   1. 手动检查 config.js 确认配置正确"
echo "   2. 运行诊断工具: npm run diagnose"
echo "   3. 检查账户余额是否充足"
echo "   4. 使用小金额测试: maxSizePerTrade: 1"
echo "   5. 查看错误日志了解具体失败原因"
echo ""
echo "📝 详细说明请查看: 实盘跟单失败排查.md"
echo ""
