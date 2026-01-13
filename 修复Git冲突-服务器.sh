#!/bin/bash

# 修复 package.json 中的 Git 合并冲突

PROJECT_DIR="${1:-/opt/polybot}"

echo "╔════════════════════════════════════════════╗"
echo "║      修复 package.json Git 冲突           ║"
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

# 检查是否有冲突标记
if ! grep -q "<<<<<<< HEAD" package.json; then
    echo "✅ 未发现 Git 冲突标记"
    echo ""
    echo "💡 如果仍有问题，请检查 JSON 语法："
    echo "   node -e \"require('./package.json')\""
    exit 0
fi

echo "⚠️  发现 Git 冲突标记，正在修复..."
echo ""

# 使用 Node.js 修复冲突（保留 HEAD 版本）
node << 'NODE_SCRIPT'
const fs = require('fs');

try {
    let content = fs.readFileSync('package.json', 'utf8');
    
    // 查找并移除所有冲突标记
    // 保留 HEAD 版本（<<<<<<< HEAD 和 ======= 之间的内容）
    let resolved = content.replace(/<<<<<<< HEAD\n([\s\S]*?)\n=======\n([\s\S]*?)\n>>>>>>>[^\n]*\n?/g, '$1');
    
    // 写入修复后的内容
    fs.writeFileSync('package.json', resolved);
    
    console.log('✅ 已移除冲突标记（保留 HEAD 版本）');
} catch (error) {
    console.error('❌ 修复失败:', error.message);
    console.error('');
    console.error('💡 请手动编辑 package.json');
    process.exit(1);
}
NODE_SCRIPT

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ 自动修复失败"
    echo ""
    echo "💡 请手动编辑 package.json，删除以下冲突标记："
    echo "   <<<<<<< HEAD"
    echo "   ======="
    echo "   >>>>>>>"
    echo ""
    echo "   保留 HEAD 版本的内容（冲突标记之间的第一部分）"
    exit 1
fi

echo ""
echo "📋 验证修复..."
if node -e "require('./package.json')" 2>/dev/null; then
    echo "✅ JSON 语法验证通过"
else
    echo "❌ JSON 语法验证失败"
    echo ""
    echo "💡 请手动检查 package.json"
    echo "   恢复备份: cp package.json.bak package.json"
    exit 1
fi

# 再次检查是否还有冲突标记
if grep -q "<<<<<<< HEAD" package.json; then
    echo "⚠️  仍有冲突标记，可能需要手动修复"
    echo ""
    echo "💡 请查看文件中的冲突标记并手动解决"
else
    echo "✅ 冲突标记已清理"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 修复完成！"
echo ""
echo "💡 现在可以运行："
echo "   npm install"
echo "   npm run diagnose"
echo ""
