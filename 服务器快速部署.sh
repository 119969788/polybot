#!/bin/bash
# PolyBot 服务器快速部署脚本

echo "=========================================="
echo "PolyBot 服务器部署"
echo "=========================================="

# 检查是否在项目目录
if [ ! -f "package.json" ]; then
    echo "⚠️  当前目录没有 package.json 文件"
    echo ""
    echo "请按照以下步骤操作："
    echo ""
    echo "1. 创建项目目录并进入："
    echo "   mkdir -p /opt/polybot"
    echo "   cd /opt/polybot"
    echo ""
    echo "2. 克隆项目："
    echo "   git clone https://github.com/119969788/polybot.git ."
    echo ""
    echo "3. 或者如果项目已克隆，直接进入项目目录："
    echo "   cd /opt/polybot"
    echo "   # 或"
    echo "   cd ~/polybot"
    echo ""
    echo "然后重新运行此脚本"
    exit 1
fi

echo "✅ 已找到项目文件"
echo ""
echo "开始部署..."

# 1. 检查 Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js 未安装"
    echo "安装 Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt install -y nodejs
fi

echo "✅ Node.js 版本: $(node --version)"

# 2. 安装依赖
echo ""
echo "安装依赖..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ 依赖安装失败"
    echo "尝试使用国内镜像..."
    npm config set registry https://registry.npmmirror.com
    npm install
fi

echo "✅ 依赖安装完成"

# 3. 检查配置文件
if [ ! -f "config.js" ]; then
    echo ""
    echo "创建配置文件..."
    cp config.example.js config.js
    echo "✅ 已创建 config.js"
    echo "⚠️  请编辑 config.js 设置您的配置："
    echo "   nano config.js"
fi

# 4. 完成
echo ""
echo "=========================================="
echo "✅ 部署完成！"
echo "=========================================="
echo ""
echo "下一步："
echo "1. 编辑配置: nano config.js"
echo "2. 运行项目: npm start"
echo ""
echo "或者使用 PM2 后台运行："
echo "   npm install -g pm2"
echo "   pm2 start index.js --name polybot"
echo "   pm2 logs polybot"
echo ""
