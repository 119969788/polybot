#!/bin/bash

# 在服务器上修复 package.json，添加 diagnose 脚本

PROJECT_DIR="${1:-/opt/polybot}"

echo "╔════════════════════════════════════════════╗"
echo "║      修复 package.json (添加 diagnose)      ║"
echo "╚════════════════════════════════════════════╝"
echo ""

cd "$PROJECT_DIR" || {
    echo "❌ 无法进入目录: $PROJECT_DIR"
    exit 1
}

echo "📁 当前目录: $(pwd)"
echo ""

# 备份 package.json
if [ -f "package.json" ]; then
    echo "📋 备份 package.json..."
    cp package.json package.json.bak
    echo "✅ 已备份为 package.json.bak"
    echo ""
else
    echo "❌ 未找到 package.json 文件"
    exit 1
fi

# 检查是否已有 diagnose 脚本
if grep -q '"diagnose"' package.json; then
    echo "✅ diagnose 脚本已存在"
    echo ""
    echo "💡 如果需要重新添加，请先删除现有脚本"
    exit 0
fi

# 方法1：使用 sed 添加 diagnose 脚本（在 "scripts" 部分）
echo "🔧 添加 diagnose 脚本..."

# 检查 scripts 部分是否存在
if grep -q '"scripts"' package.json; then
    # 在 start 脚本后添加 diagnose 脚本
    sed -i '/"start": "node index.js",/a\    "diagnose": "node diagnose-failures.js",' package.json
    
    echo "✅ diagnose 脚本已添加"
    echo ""
    echo "📋 验证修复..."
    if grep -q '"diagnose"' package.json; then
        echo "✅ 验证成功"
        grep -A 2 '"diagnose"' package.json
    else
        echo "❌ 添加失败，请手动编辑 package.json"
        echo ""
        echo "💡 手动添加方法："
        echo "   在 \"scripts\" 部分添加："
        echo "   \"diagnose\": \"node diagnose-failures.js\","
    fi
else
    echo "❌ 未找到 \"scripts\" 部分"
    echo ""
    echo "💡 请手动编辑 package.json，在 \"scripts\" 部分添加："
    echo "   \"diagnose\": \"node diagnose-failures.js\","
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
