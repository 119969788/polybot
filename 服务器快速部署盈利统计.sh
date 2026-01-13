#!/bin/bash

# 腾讯云服务器快速部署盈利统计功能脚本

echo "╔════════════════════════════════════════════╗"
echo "║   部署盈利统计功能到腾讯云服务器          ║"
echo "╚════════════════════════════════════════════╝"
echo ""

PROJECT_DIR="${1:-/opt/polybot}"
cd "$PROJECT_DIR" || exit 1

echo "📁 项目目录: $PROJECT_DIR"
echo ""

# 1. 检查必需文件
echo "🔍 检查必需文件..."
REQUIRED_FILES=(
  "src/ProfitTracker.js"
  "src/WalletFollower.js"
  "config.js"
  "index.js"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
  if [ ! -f "$file" ]; then
    MISSING_FILES+=("$file")
    echo "  ❌ $file - 不存在"
  else
    echo "  ✅ $file - 存在"
  fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
  echo ""
  echo "❌ 缺少必需文件，请先上传文件到服务器"
  exit 1
fi

echo ""

# 2. 检查语法
echo "🔍 检查语法..."
node --check src/ProfitTracker.js && echo "  ✅ ProfitTracker.js 语法正确" || echo "  ❌ ProfitTracker.js 语法错误"
node --check src/WalletFollower.js && echo "  ✅ WalletFollower.js 语法正确" || echo "  ❌ WalletFollower.js 语法错误"
node --check config.js && echo "  ✅ config.js 语法正确" || echo "  ❌ config.js 语法错误"
echo ""

# 3. 检查配置
echo "🔍 检查盈利统计配置..."
if grep -q "profitTracking" config.js; then
  echo "  ✅ profitTracking 配置已存在"
  grep -A 3 "profitTracking:" config.js | head -4
else
  echo "  ⚠️  profitTracking 配置不存在，将添加默认配置"
  
  # 备份配置文件
  cp config.js config.js.backup.$(date +%Y%m%d_%H%M%S)
  
  # 添加配置（在 followSettings 之后）
  if grep -q "watchInterval:" config.js; then
    sed -i '/watchInterval:/a\
  },\
\
  // 盈利统计配置\
  profitTracking: {\
    enabled: true,\
    autoSaveInterval: 60000,\
    displayInterval: 30,\
  },' config.js
    
    # 修复最后一个逗号
    sed -i 's/  },$/  },/g' config.js
    
    echo "  ✅ 已添加 profitTracking 配置"
  else
    echo "  ❌ 无法自动添加配置，请手动编辑 config.js"
  fi
fi
echo ""

# 4. 创建数据目录
echo "📁 创建数据目录..."
mkdir -p data
chmod 755 data
if [ -d "data" ]; then
  echo "  ✅ data/ 目录已创建"
else
  echo "  ❌ 无法创建 data/ 目录"
  exit 1
fi
echo ""

# 5. 检查 PM2（如果使用）
if command -v pm2 &> /dev/null; then
  echo "📊 检测到 PM2，检查进程状态..."
  if pm2 list | grep -q "polybot"; then
    echo "  ✅ polybot 进程正在运行"
    echo "  💡 运行 'pm2 restart polybot' 重启进程以加载新代码"
  else
    echo "  ℹ️  polybot 进程未运行"
  fi
else
  echo "  ℹ️  未安装 PM2（可选）"
fi
echo ""

# 6. 测试运行（可选）
read -p "是否测试运行程序（5秒后自动停止）？(y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "🧪 测试运行程序..."
  timeout 5 node index.js 2>&1 | head -30 || true
  echo ""
fi

# 7. 完成
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ 部署检查完成！"
echo ""
echo "📋 下一步："
echo "   1. 如果使用 PM2: pm2 restart polybot"
echo "   2. 或直接运行: npm start"
echo "   3. 查看日志: pm2 logs polybot（如果使用 PM2）"
echo ""
