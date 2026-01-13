#!/bin/bash

# 设置自动更新（使用 Crontab）

echo "╔════════════════════════════════════════════╗"
echo "║      PolyBot 自动更新设置脚本              ║"
echo "╚════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="${1:-/opt/polybot}"
UPDATE_INTERVAL="${2:-30}"  # 默认 30 分钟检查一次

echo "📁 项目目录: $PROJECT_DIR"
echo "⏰ 更新间隔: 每 $UPDATE_INTERVAL 分钟检查一次"
echo ""

# 检查自动更新脚本是否存在
UPDATE_SCRIPT="${PROJECT_DIR}/auto-update.sh"

if [ ! -f "$UPDATE_SCRIPT" ]; then
    echo "❌ 自动更新脚本不存在: $UPDATE_SCRIPT"
    echo "💡 请确保 auto-update.sh 文件存在"
    exit 1
fi

# 添加执行权限
chmod +x "$UPDATE_SCRIPT"
echo "✅ 已设置执行权限"

# 创建 crontab 条目
CRON_JOB="*/${UPDATE_INTERVAL} * * * * cd ${PROJECT_DIR} && bash ${UPDATE_SCRIPT} >> ${PROJECT_DIR}/logs/auto-update-cron.log 2>&1"

# 检查是否已存在
if crontab -l 2>/dev/null | grep -q "$UPDATE_SCRIPT"; then
    echo "⚠️  检测到已存在的自动更新任务"
    read -p "是否要替换现有的自动更新任务？(y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # 删除旧的
        crontab -l 2>/dev/null | grep -v "$UPDATE_SCRIPT" | crontab -
        # 添加新的
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        echo "✅ 已更新自动更新任务"
    else
        echo "ℹ️  保留现有任务"
        exit 0
    fi
else
    # 添加新的
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "✅ 已添加自动更新任务"
fi

echo ""
echo "📋 当前 Crontab 任务:"
crontab -l | grep -E "(polybot|auto-update)" || echo "  （未找到相关任务）"

echo ""
echo "✅ 自动更新已设置完成！"
echo ""
echo "📝 任务详情:"
echo "   脚本: $UPDATE_SCRIPT"
echo "   间隔: 每 $UPDATE_INTERVAL 分钟"
echo "   日志: ${PROJECT_DIR}/logs/auto-update-cron.log"
echo ""
echo "💡 管理命令:"
echo "   查看任务: crontab -l"
echo "   编辑任务: crontab -e"
echo "   删除任务: crontab -r"
echo "   查看日志: tail -f ${PROJECT_DIR}/logs/auto-update-cron.log"
echo ""
