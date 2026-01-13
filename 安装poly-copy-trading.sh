#!/bin/bash

# 在阿里云服务器上安装 poly-copy-trading 项目
# 使用方法: bash 安装poly-copy-trading.sh

set -e  # 遇到错误立即退出

echo "╔════════════════════════════════════════════╗"
echo "║  Poly-Copy-Trading 安装脚本                ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# 配置
PROJECT_NAME="poly-copy-trading"
PROJECT_DIR="/opt/${PROJECT_NAME}"
GITHUB_URL="https://github.com/119969788/poly-copy-trading.git"
NODE_VERSION="18"

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

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then 
    log_warning "建议使用 root 用户运行此脚本，或使用 sudo"
fi

# 1. 更新系统
log_info "步骤 1: 更新系统包..."
if command -v yum &> /dev/null; then
    yum update -y -q
    yum install -y -q curl git
elif command -v apt-get &> /dev/null; then
    apt-get update -qq
    apt-get install -y -qq curl git
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
        log_info "安装 Node.js ${NODE_VERSION}..."
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        yum install -y -q nodejs
    fi
else
    log_info "安装 Node.js ${NODE_VERSION}..."
    if command -v yum &> /dev/null; then
        curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -
        yum install -y -q nodejs
    elif command -v apt-get &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -
        apt-get install -y -qq nodejs
    fi
fi
log_success "Node.js: $(node -v)"
log_success "npm: $(npm -v)"
echo ""

# 3. 安装 pnpm
log_info "步骤 3: 安装 pnpm..."
if command -v pnpm &> /dev/null; then
    log_success "pnpm 已安装: $(pnpm -v)"
else
    log_info "安装 pnpm..."
    npm install -g pnpm
    log_success "pnpm 已安装: $(pnpm -v)"
fi
echo ""

# 4. 安装 PM2（可选但推荐）
log_info "步骤 4: 安装 PM2（进程管理器）..."
if command -v pm2 &> /dev/null; then
    log_success "PM2 已安装: $(pm2 -v)"
else
    log_info "安装 PM2..."
    npm install -g pm2
    log_success "PM2 已安装"
fi
echo ""

# 5. 克隆项目
log_info "步骤 5: 克隆项目..."
if [ -d "$PROJECT_DIR" ]; then
    log_warning "目录 $PROJECT_DIR 已存在"
    read -p "是否删除并重新克隆? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$PROJECT_DIR"
        git clone "$GITHUB_URL" "$PROJECT_DIR"
        log_success "项目已重新克隆"
    else
        log_info "跳过克隆，使用现有目录"
    fi
else
    git clone "$GITHUB_URL" "$PROJECT_DIR"
    log_success "项目已克隆到 $PROJECT_DIR"
fi
echo ""

# 6. 进入项目目录
cd "$PROJECT_DIR" || exit 1
log_info "当前目录: $(pwd)"
echo ""

# 7. 安装依赖
log_info "步骤 6: 安装项目依赖..."
if [ -f "package.json" ]; then
    pnpm install
    log_success "依赖安装完成"
else
    log_error "未找到 package.json 文件"
    exit 1
fi
echo ""

# 8. 创建 .env 文件
log_info "步骤 7: 配置环境变量..."
if [ -f ".env" ]; then
    log_warning ".env 文件已存在，跳过创建"
else
    if [ -f "env.example.txt" ]; then
        cp env.example.txt .env
        log_success "已从 env.example.txt 创建 .env 文件"
        log_warning "请编辑 .env 文件，填入您的私钥:"
        log_info "  nano $PROJECT_DIR/.env"
    else
        log_warning "未找到 env.example.txt，请手动创建 .env 文件"
    fi
fi
echo ""

# 9. 编译 TypeScript（如果需要）
log_info "步骤 8: 检查 TypeScript 配置..."
if [ -f "tsconfig.json" ]; then
    log_info "检测到 TypeScript 项目"
    if [ -f "package.json" ] && grep -q '"build"' package.json; then
        log_info "运行构建命令..."
        pnpm build 2>/dev/null || log_warning "构建失败或不需要构建（使用 tsx 直接运行）"
    else
        log_info "项目使用 tsx 直接运行，无需构建"
    fi
else
    log_info "未检测到 TypeScript，跳过构建"
fi
echo ""

# 10. 设置权限
log_info "步骤 9: 设置文件权限..."
chmod +x *.sh 2>/dev/null || true
log_success "权限设置完成"
echo ""

# 11. 完成
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log_success "安装完成！"
echo ""
echo "📋 下一步："
echo ""
echo "1. 配置环境变量:"
echo "   cd $PROJECT_DIR"
echo "   nano .env"
echo ""
echo "2. 填入必要的配置:"
echo "   POLYMARKET_PRIVATE_KEY=你的私钥"
echo "   DRY_RUN=true  # 测试模式（推荐先测试）"
echo ""
echo "3. 运行项目:"
echo "   测试模式: pnpm start"
echo "   开发模式: pnpm dev"
echo ""
echo "4. 使用 PM2 运行（后台运行）:"
echo "   pm2 start pnpm --name poly-copy-trading -- start"
echo "   pm2 save"
echo "   pm2 startup"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
