#!/bin/bash

# 快速修复 Git 分支分歧并运行诊断工具

PROJECT_DIR="${1:-/opt/polybot}"
cd "$PROJECT_DIR" || exit 1

echo "╔════════════════════════════════════════════╗"
echo "║      修复 Git 分支并运行诊断                ║"
echo "╚════════════════════════════════════════════╝"
echo ""
echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 1. 设置合并策略
echo "🔧 设置 Git 合并策略..."
git config pull.rebase false
echo "✅ 已设置使用 merge 策略"
echo ""

# 2. 查看当前状态
echo "📋 当前 Git 状态:"
git status --short | head -10
echo ""

# 3. 拉取最新代码
echo "📥 拉取最新代码..."
if git pull origin main; then
    echo "✅ 代码拉取成功"
else
    echo "❌ 代码拉取失败"
    echo ""
    echo "💡 如果仍有冲突，可以尝试:"
    echo "   git fetch origin"
    echo "   git reset --hard origin/main"
    exit 1
fi
echo ""

# 4. 检查文件
echo "🔍 检查文件..."
if [ -f "diagnose-failures.js" ]; then
    echo "✅ diagnose-failures.js 存在"
    ls -lh diagnose-failures.js
else
    echo "❌ diagnose-failures.js 不存在"
    echo ""
    echo "💡 尝试查看所有文件:"
    git ls-files | grep diagnose
    exit 1
fi
echo ""

# 5. 验证语法
echo "🔍 验证语法..."
if node --check diagnose-failures.js 2>/dev/null; then
    echo "✅ 语法正确"
else
    echo "❌ 语法错误"
    exit 1
fi
echo ""

# 6. 运行诊断
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 运行诊断工具..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

node diagnose-failures.js

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 诊断完成"
else
    echo "❌ 诊断过程出错（退出码: $EXIT_CODE）"
fi
