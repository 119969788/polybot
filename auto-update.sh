#!/bin/bash

# PolyBot 自动更新脚本
# 用途：自动从 Git 仓库拉取最新代码并重启服务

echo "╔════════════════════════════════════════════╗"
echo "║      PolyBot 自动更新脚本                  ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# 配置
PROJECT_DIR="${POLYBOT_DIR:-/opt/polybot}"
BRANCH="${POLYBOT_BRANCH:-main}"
LOG_FILE="${PROJECT_DIR}/logs/auto-update.log"
USE_PM2=true  # 是否使用 PM2
PM2_NAME="polybot"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 确保日志目录存在
mkdir -p "$(dirname "$LOG_FILE")"

log "开始自动更新..."

# 检查项目目录
if [ ! -d "$PROJECT_DIR" ]; then
    log "${RED}❌ 项目目录不存在: $PROJECT_DIR${NC}"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1

# 检查是否是 Git 仓库
if [ ! -d ".git" ]; then
    log "${YELLOW}⚠️  当前目录不是 Git 仓库${NC}"
    log "${YELLOW}💡 提示: 如果使用 Git，请先初始化: git init${NC}"
    exit 1
fi

# 检查是否有未提交的更改
if ! git diff-index --quiet HEAD --; then
    log "${YELLOW}⚠️  检测到未提交的更改${NC}"
    log "${YELLOW}💡 提示: 正在备份未提交的更改...${NC}"
    
    # 备份未提交的更改
    BACKUP_DIR="${PROJECT_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    git diff > "${BACKUP_DIR}/changes.patch"
    git stash save "Auto-update backup $(date +%Y%m%d_%H%M%S)"
    log "${GREEN}✅ 已备份未提交的更改到: $BACKUP_DIR${NC}"
fi

# 获取当前分支
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
log "当前分支: $CURRENT_BRANCH"

# 获取远程最新信息
log "获取远程更新..."
git fetch origin

# 检查是否有更新
LOCAL_COMMIT=$(git rev-parse HEAD)
REMOTE_COMMIT=$(git rev-parse origin/$BRANCH 2>/dev/null || echo "")

if [ -z "$REMOTE_COMMIT" ]; then
    log "${YELLOW}⚠️  无法获取远程分支信息${NC}"
    log "${YELLOW}💡 提示: 检查网络连接和 Git 配置${NC}"
    exit 1
fi

if [ "$LOCAL_COMMIT" = "$REMOTE_COMMIT" ]; then
    log "${GREEN}✅ 代码已是最新版本${NC}"
    log "本地提交: ${LOCAL_COMMIT:0:7}"
    log "远程提交: ${REMOTE_COMMIT:0:7}"
    exit 0
fi

# 有更新，显示更新信息
log "${CYAN}📥 发现新版本，开始更新...${NC}"
log "本地提交: ${LOCAL_COMMIT:0:7}"
log "远程提交: ${REMOTE_COMMIT:0:7}"

# 显示更新日志
log "更新内容:"
git log --oneline ${LOCAL_COMMIT}..${REMOTE_COMMIT} | head -10 | while read line; do
    log "  $line"
done

# 切换到目标分支（如果需要）
if [ "$CURRENT_BRANCH" != "$BRANCH" ]; then
    log "切换到分支: $BRANCH"
    git checkout "$BRANCH" || {
        log "${RED}❌ 切换分支失败${NC}"
        exit 1
    }
fi

# 拉取最新代码
log "拉取最新代码..."
if git pull origin "$BRANCH"; then
    log "${GREEN}✅ 代码更新成功${NC}"
else
    log "${RED}❌ 代码更新失败${NC}"
    log "${YELLOW}💡 提示: 可能需要解决冲突或检查权限${NC}"
    exit 1
fi

# 安装/更新依赖（如果需要）
if [ -f "package.json" ]; then
    log "检查依赖..."
    if [ "package.json" -nt "node_modules" ] || [ ! -d "node_modules" ]; then
        log "安装/更新依赖..."
        npm install
        if [ $? -eq 0 ]; then
            log "${GREEN}✅ 依赖安装成功${NC}"
        else
            log "${YELLOW}⚠️  依赖安装失败，但继续运行${NC}"
        fi
    else
        log "${GREEN}✅ 依赖已是最新${NC}"
    fi
fi

# 验证代码
log "验证代码..."
if node --check index.js 2>/dev/null; then
    log "${GREEN}✅ 代码验证通过${NC}"
else
    log "${YELLOW}⚠️  代码验证警告（可能有一些问题）${NC}"
fi

# 重启服务
if [ "$USE_PM2" = true ] && command -v pm2 &> /dev/null; then
    if pm2 list | grep -q "$PM2_NAME"; then
        log "重启 PM2 服务: $PM2_NAME"
        pm2 restart "$PM2_NAME"
        
        # 等待一下，检查服务状态
        sleep 2
        if pm2 list | grep "$PM2_NAME" | grep -q "online"; then
            log "${GREEN}✅ 服务重启成功${NC}"
            log "查看日志: pm2 logs $PM2_NAME"
        else
            log "${RED}❌ 服务重启后未正常运行${NC}"
            log "查看错误: pm2 logs $PM2_NAME --err"
        fi
    else
        log "${YELLOW}⚠️  PM2 进程 '$PM2_NAME' 不存在${NC}"
        log "${YELLOW}💡 提示: 手动启动服务或检查 PM2 配置${NC}"
    fi
else
    log "${YELLOW}ℹ️  未使用 PM2 或 PM2 未安装${NC}"
    log "${YELLOW}💡 提示: 请手动重启服务${NC}"
fi

log "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
log "${GREEN}✅ 自动更新完成！${NC}"
log "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
