#!/bin/bash

# 在阿里云服务器上安装 polybot 项目
# 使用方法: bash 阿里云安装polybot.sh

set -e  # 遇到错误立即退出

echo "╔════════════════════════════════════════════╗"
echo "║  PolyBot 安装脚本（阿里云）                 ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# 配置
PROJECT_NAME="polybot"
PROJECT_DIR="/opt/${PROJECT_NAME}"
GITHUB_URL="https://github.com/119969788/polybot.git"
NODE_VERSION="20"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查是否为 root 用户，如果不是则使用 sudo
SUDO=""
if [ "$EUID" -ne 0 ]; then 
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
        log_warning "检测到非 root 用户，将使用 sudo 执行命令"
    else
        log_warning "建议使用 root 用户运行此脚本，或安装 sudo"
        log_error "请使用: sudo bash $0"
        exit 1
    fi
fi

# 1. 更新系统
log_info "步骤 1: 更新系统包..."
if command -v yum &> /dev/null; then
    $SUDO yum update -y -q
    $SUDO yum install -y -q curl git
elif command -v apt-get &> /dev/null; then
    $SUDO apt-get update -qq
    $SUDO apt-get install -y -qq curl git
else
    log_error "无法识别的包管理器"
    exit 1
fi
log_success "系统包更新完成"
echo ""

# 2. 安装 Node.js
log_info "步骤 2: 检查 Node.js..."
if command -v node &> /dev/null; then
    NODE_CURRENT=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_CURRENT" -ge "$NODE_VERSION" ]; then
        log_success "Node.js 已安装: $(node -v)"
    else
        log_warning "Node.js 版本过低 ($(node -v))，需要 >= v${NODE_VERSION}"
        log_info "升级 Node.js 到 ${NODE_VERSION}.x LTS..."
        if command -v yum &> /dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
            $SUDO yum install -y -q nodejs
        elif command -v apt-get &> /dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
            $SUDO apt-get install -y -qq nodejs
        fi
    fi
else
    log_info "安装 Node.js ${NODE_VERSION}.x LTS..."
    if command -v yum &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
        $SUDO yum install -y -q nodejs
    elif command -v apt-get &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | $SUDO bash -
        $SUDO apt-get install -y -qq nodejs
    fi
fi
log_success "Node.js: $(node -v)"
log_success "npm: $(npm -v)"
echo ""

# 3. 安装 PM2（推荐）
log_info "步骤 3: 安装 PM2（进程管理器）..."
if command -v pm2 &> /dev/null; then
    log_success "PM2 已安装: $(pm2 -v)"
else
    log_info "安装 PM2..."
    $SUDO npm install -g pm2
    log_success "PM2 已安装"
fi
echo ""

# 4. 处理现有目录
log_info "步骤 4: 检查项目目录..."
if [ -d "$PROJECT_DIR" ]; then
    log_warning "目录 $PROJECT_DIR 已存在"
    read -p "是否删除并重新安装? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "删除现有目录..."
        rm -rf "$PROJECT_DIR"
        log_success "目录已删除"
    else
        log_info "跳过删除，将更新现有目录"
        cd "$PROJECT_DIR" || exit 1
        log_info "拉取最新代码..."
        git pull origin main || git pull origin master || {
            log_warning "拉取失败，将重新克隆"
            cd /opt
            rm -rf "$PROJECT_DIR"
        }
    fi
fi

# 5. 克隆项目
if [ ! -d "$PROJECT_DIR" ]; then
    log_info "步骤 5: 克隆项目..."
    mkdir -p /opt
    git clone "$GITHUB_URL" "$PROJECT_DIR"
    log_success "项目已克隆到 $PROJECT_DIR"
    echo ""
fi

# 6. 进入项目目录
cd "$PROJECT_DIR" || exit 1
log_info "当前目录: $(pwd)"
echo ""

# 7. 安装依赖
log_info "步骤 6: 安装项目依赖..."
if [ -f "package.json" ]; then
    npm install
    log_success "依赖安装完成"
else
    log_error "未找到 package.json 文件"
    exit 1
fi
echo ""

# 8. 创建配置文件
log_info "步骤 7: 配置项目..."
if [ ! -f "config.js" ]; then
    if [ -f "config.example.js" ]; then
        cp config.example.js config.js
        log_success "已从 config.example.js 创建 config.js"
        log_warning "请编辑 config.js 文件，填入您的配置:"
        log_info "  nano $PROJECT_DIR/config.js"
    else
        log_warning "未找到 config.example.js，请手动创建 config.js"
    fi
else
    log_warning "config.js 已存在，跳过创建"
fi
echo ""

# 9. 设置权限
log_info "步骤 8: 设置文件权限..."
chmod +x *.sh 2>/dev/null || true
if [ -d "data" ]; then
    chmod 755 data 2>/dev/null || true
fi
log_success "权限设置完成"
echo ""

# 10. 完成
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "安装完成！"
echo ""
echo "📋 下一步："
echo ""
echo "1. 配置项目:"
echo "   cd $PROJECT_DIR"
echo "   nano config.js"
echo ""
echo "2. 填入必要的配置:"
echo "   - privateKey: 0xd4ae880287b31d8316f31e938a4bb50d6260d765229076be83d8fa7962f2531b"
echo "   - targetWallets: 0xe00740bce98a594e26861838885ab310ec3b548c,0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"
echo "   - followSettings.autoFollow: true"
echo "   - followSettings.dryRun: true  # 测试模式（推荐先测试）"
echo ""
echo "3. 测试运行:"
echo "   cd $PROJECT_DIR"
echo "   npm start"
echo ""
echo "4. 使用 PM2 运行（后台运行）:"
echo "   cd $PROJECT_DIR"
echo "   pm2 start index.js --name polybot"
echo "   pm2 save"
echo "   pm2 startup  # 设置开机自启"
echo "   pm2 logs polybot  # 查看日志"
echo ""
echo "5. PM2 常用命令:"
echo "   pm2 list           # 查看运行状态"
echo "   pm2 restart polybot  # 重启"
echo "   pm2 stop polybot     # 停止"
echo "   pm2 logs polybot     # 查看日志"
echo "   pm2 monit           # 监控面板"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
