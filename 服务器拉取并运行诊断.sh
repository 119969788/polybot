#!/bin/bash

# 在服务器上拉取最新代码并运行诊断工具

echo "╔════════════════════════════════════════════╗"
echo "║      拉取代码并运行诊断工具                ║"
echo "╚════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="${1:-/opt/polybot}"
cd "$PROJECT_DIR" || exit 1

echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 1. 拉取最新代码
echo "📥 拉取最新代码..."
if [ -d ".git" ]; then
    git fetch origin
    git pull origin main
    
    if [ $? -eq 0 ]; then
        echo "✅ 代码拉取成功"
    else
        echo "❌ 代码拉取失败"
        exit 1
    fi
else
    echo "❌ 不是 Git 仓库"
    exit 1
fi
echo ""

# 2. 检查文件是否存在
echo "🔍 检查文件..."
if [ -f "diagnose-failures.js" ]; then
    echo "✅ diagnose-failures.js 存在"
else
    echo "❌ diagnose-failures.js 不存在"
    exit 1
fi
echo ""

# 3. 验证语法
echo "🔍 验证语法..."
if node --check diagnose-failures.js 2>/dev/null; then
    echo "✅ 语法正确"
else
    echo "❌ 语法错误"
    exit 1
fi
echo ""

# 4. 运行诊断工具
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 运行诊断工具..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

node diagnose-failures.js

EXIT_CODE=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $EXIT_CODE -eq 0 ]; then
    echo "✅ 诊断完成"
else
    echo "❌ 诊断过程出错（退出码: $EXIT_CODE）"
fi
echo ""
