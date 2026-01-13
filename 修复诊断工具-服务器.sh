#!/bin/bash

# 在服务器上修复 diagnose-failures.js 的导入错误

echo "╔════════════════════════════════════════════╗"
echo "║      修复诊断工具导入错误                   ║"
echo "╚════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="${1:-/opt/polybot}"

cd "$PROJECT_DIR" || {
    echo "❌ 无法进入目录: $PROJECT_DIR"
    exit 1
}

echo "📁 当前目录: $(pwd)"
echo ""

# 检查文件是否存在
if [ ! -f "diagnose-failures.js" ]; then
    echo "❌ 未找到 diagnose-failures.js 文件"
    exit 1
fi

# 备份原文件
echo "📋 备份原文件..."
cp diagnose-failures.js diagnose-failures.js.bak
echo "✅ 已备份为 diagnose-failures.js.bak"
echo ""

# 修复导入方式：从默认导入改为命名导入
echo "🔧 修复导入方式..."
sed -i "s/import PolymarketSDK from '@catalyst-team\/poly-sdk';/import { PolymarketSDK } from '@catalyst-team\/poly-sdk';/" diagnose-failures.js

# 检查是否修复成功
if grep -q "import { PolymarketSDK } from '@catalyst-team/poly-sdk';" diagnose-failures.js; then
    echo "✅ 导入方式已修复"
else
    echo "⚠️  导入方式可能已修复，或需要手动检查"
fi
echo ""

# 修复 SDK 初始化方式（使用 create 方法）
echo "🔧 修复 SDK 初始化方式..."
# 修复交易模式的初始化
sed -i 's/sdk = new PolymarketSDK({/sdk = await PolymarketSDK.create({/' diagnose-failures.js

# 检查是否修复成功
if grep -q "await PolymarketSDK.create" diagnose-failures.js; then
    echo "✅ SDK 初始化方式已修复"
else
    echo "⚠️  SDK 初始化方式可能需要手动检查"
fi
echo ""

# 验证修复
echo "🔍 验证修复..."
if grep -q "import { PolymarketSDK } from '@catalyst-team/poly-sdk';" diagnose-failures.js; then
    echo "✅ 导入方式正确"
else
    echo "❌ 导入方式仍有问题"
fi

if grep -q "PolymarketSDK.create" diagnose-failures.js; then
    echo "✅ SDK 初始化方式正确"
else
    echo "❌ SDK 初始化方式仍有问题"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 修复完成！"
echo ""
echo "💡 现在可以运行诊断工具:"
echo "   npm run diagnose"
echo "   或"
echo "   node diagnose-failures.js"
echo ""
