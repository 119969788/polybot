#!/bin/bash

# 修复 .env 文件权限问题

PROJECT_DIR="${1:-/opt/poly-copy-trading}"

echo "╔════════════════════════════════════════════╗"
echo "║      修复 .env 文件权限                    ║"
echo "╚════════════════════════════════════════════╝"
echo ""

cd "$PROJECT_DIR" || {
    echo "❌ 无法进入目录: $PROJECT_DIR"
    exit 1
}

echo "📁 项目目录: $(pwd)"
echo ""

# 1. 检查 .env 文件是否存在
if [ -f ".env" ]; then
    echo "📋 当前 .env 文件权限:"
    ls -l .env
    echo ""
    
    # 2. 修复权限（仅当前用户可读写）
    echo "🔧 修复权限..."
    chmod 600 .env
    echo "✅ 已设置权限为 600（仅用户可读写）"
    
    # 3. 检查文件所有者
    OWNER=$(stat -c '%U' .env 2>/dev/null || stat -f '%Su' .env 2>/dev/null)
    CURRENT_USER=$(whoami)
    
    if [ "$OWNER" != "$CURRENT_USER" ]; then
        echo "⚠️  文件所有者是 $OWNER，当前用户是 $CURRENT_USER"
        echo "🔧 修改文件所有者..."
        sudo chown "$CURRENT_USER:$CURRENT_USER" .env 2>/dev/null || {
            echo "❌ 无法修改所有者，可能需要 sudo 权限"
            echo "💡 请执行: sudo chown $CURRENT_USER:$CURRENT_USER .env"
        }
    fi
else
    echo "⚠️  .env 文件不存在"
    
    # 从示例文件创建
    if [ -f "env.example.txt" ]; then
        echo "📋 从 env.example.txt 创建 .env..."
        cp env.example.txt .env
        chmod 600 .env
        echo "✅ 已创建 .env 文件并设置权限"
    else
        echo "❌ env.example.txt 也不存在"
        echo "💡 手动创建 .env 文件:"
        echo "   touch .env"
        echo "   chmod 600 .env"
        exit 1
    fi
fi

echo ""
echo "📋 修复后的权限:"
ls -l .env
echo ""

# 4. 测试写入权限
echo "🔍 测试写入权限..."
if echo "# Test write" >> .env 2>/dev/null; then
    # 删除测试行
    sed -i '/^# Test write$/d' .env 2>/dev/null || true
    echo "✅ 写入权限正常"
else
    echo "❌ 写入权限仍然有问题"
    echo ""
    echo "💡 尝试以下解决方案:"
    echo "   1. 使用 sudo: sudo chmod 600 .env"
    echo "   2. 检查目录权限: ls -ld ."
    echo "   3. 修改目录权限: chmod 755 ."
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 权限修复完成！"
echo ""
echo "💡 现在可以编辑 .env 文件:"
echo "   nano .env"
echo "   或"
echo "   vi .env"
echo ""
