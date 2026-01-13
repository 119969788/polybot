#!/bin/bash
# PolyBot 自动安装脚本 - 适用于 Ubuntu/Debian

set -e  # 遇到错误立即退出

echo "=========================================="
echo "PolyBot 自动安装脚本"
echo "=========================================="

# 检查是否为 root 用户，如果不是则使用 sudo
SUDO=""
if [ "$EUID" -ne 0 ]; then 
    if command -v sudo &> /dev/null; then
        SUDO="sudo"
        echo "⚠️  检测到非 root 用户，将使用 sudo 执行命令"
    else
        echo "❌ 错误: 请使用 root 用户运行此脚本，或安装 sudo"
        echo "   或使用: sudo bash install.sh"
        exit 1
    fi
fi

# 1. 更新系统
echo "[1/8] 更新系统包..."
$SUDO apt update && $SUDO apt upgrade -y

# 2. 安装基础工具
echo "[2/8] 安装基础工具..."
$SUDO apt install -y curl wget git

# 3. 安装 Node.js
echo "[3/8] 安装 Node.js 20.x LTS..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO bash -
    $SUDO apt install -y nodejs
else
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 20 ]; then
        echo "⚠️  Node.js 版本过低 ($(node -v))，升级到 20.x LTS..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | $SUDO bash -
        $SUDO apt install -y nodejs
    else
        echo "✅ Node.js 已安装，版本: $(node --version)"
    fi
fi

# 验证 Node.js 安装
if ! command -v node &> /dev/null; then
    echo "错误: Node.js 安装失败"
    exit 1
fi

echo "Node.js 版本: $(node --version)"
echo "npm 版本: $(npm --version)"

# 4. 安装 PM2
echo "[4/8] 安装 PM2 进程管理器..."
if ! command -v pm2 &> /dev/null; then
    $SUDO npm install -g pm2
else
    echo "✅ PM2 已安装，版本: $(pm2 --version)"
fi

# 5. 创建项目目录
echo "[5/8] 创建项目目录..."
PROJECT_DIR="/opt/polybot"
mkdir -p $PROJECT_DIR
cd $PROJECT_DIR

# 6. 克隆或更新项目
echo "[6/8] 克隆/更新项目代码..."
if [ -d ".git" ]; then
    echo "项目已存在，拉取最新代码..."
    git pull
else
    echo "克隆项目..."
    read -p "请输入 GitHub 仓库地址 (默认: https://github.com/119969788/polybot.git): " REPO_URL
    REPO_URL=${REPO_URL:-"https://github.com/119969788/polybot.git"}
    git clone $REPO_URL .
fi

# 7. 安装项目依赖
echo "[7/8] 安装项目依赖..."
# 使用淘宝镜像加速（中国大陆）
npm config set registry https://registry.npmmirror.com
npm install

# 8. 配置文件设置
echo "[8/8] 配置项目..."
if [ ! -f "config.js" ]; then
    cp config.example.js config.js
    echo "✅ 已创建 config.js 配置文件"
    echo "⚠️  请编辑 $PROJECT_DIR/config.js 设置您的配置"
else
    echo "config.js 已存在，跳过..."
fi

# 设置文件权限
chmod 600 config.js 2>/dev/null || true

echo ""
echo "=========================================="
echo "✅ 安装完成！"
echo "=========================================="
echo ""
echo "下一步操作："
echo "1. 编辑配置文件: nano $PROJECT_DIR/config.js"
echo "2. 启动应用: cd $PROJECT_DIR && pm2 start index.js --name polybot"
echo "3. 查看日志: pm2 logs polybot"
echo "4. 设置开机自启: pm2 save && pm2 startup"
echo ""
echo "常用命令："
echo "  pm2 status              # 查看状态"
echo "  pm2 logs polybot        # 查看日志"
echo "  pm2 restart polybot     # 重启"
echo "  pm2 stop polybot        # 停止"
echo "  pm2 monit               # 监控"
echo ""
echo "项目目录: $PROJECT_DIR"
echo "=========================================="
