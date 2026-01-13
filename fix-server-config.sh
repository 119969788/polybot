#!/bin/bash

# PolyBot 服务器配置自动修复脚本
# 用途：自动检查并修复服务器上的配置文件问题

echo "╔════════════════════════════════════════════╗"
echo "║   PolyBot 服务器配置自动修复脚本          ║"
echo "╚════════════════════════════════════════════╝"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 项目目录（自动检测或使用当前目录）
PROJECT_DIR="${1:-$(pwd)}"
CONFIG_FILE="$PROJECT_DIR/config.js"
CONFIG_BACKUP="$PROJECT_DIR/config.js.backup.$(date +%Y%m%d_%H%M%S)"

# 私钥（请替换为您的实际私钥）
PRIVATE_KEY="0xd4ae880287b31d8316f31e938a4bb50d6260d765229076be83d8fa7962f2531b"

# 目标钱包地址
TARGET_WALLETS=(
  "0xe00740bce98a594e26861838885ab310ec3b548c"
  "0x6031b6eed1c97e853c6e0f03ad3ce3529351f96d"
)

echo -e "${CYAN}项目目录: $PROJECT_DIR${NC}"
echo ""

# 检查配置文件是否存在
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ 错误: 配置文件不存在: $CONFIG_FILE${NC}"
    if [ -f "$PROJECT_DIR/config.example.js" ]; then
        echo -e "${YELLOW}💡 从 config.example.js 创建配置文件...${NC}"
        cp "$PROJECT_DIR/config.example.js" "$CONFIG_FILE"
        echo -e "${GREEN}✅ 已创建配置文件${NC}"
    else
        echo -e "${RED}❌ 错误: config.example.js 也不存在${NC}"
        exit 1
    fi
    echo ""
fi

# 备份配置文件
echo -e "${CYAN}📦 备份配置文件...${NC}"
cp "$CONFIG_FILE" "$CONFIG_BACKUP"
echo -e "${GREEN}✅ 已备份到: $CONFIG_BACKUP${NC}"
echo ""

# 检查当前配置
echo -e "${CYAN}🔍 检查当前配置...${NC}"

# 检查私钥
if grep -q "privateKey:.*0x[a-fA-F0-9]\{64\}" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ 私钥已配置${NC}"
    HAS_PRIVATE_KEY=true
else
    echo -e "${YELLOW}⚠️  私钥未配置或格式不正确${NC}"
    HAS_PRIVATE_KEY=false
fi

# 检查 autoFollow
if grep -q "autoFollow:.*true" "$CONFIG_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ autoFollow 已启用${NC}"
    HAS_AUTOFOLLOW=true
else
    echo -e "${YELLOW}⚠️  autoFollow 未启用或为 false${NC}"
    HAS_AUTOFOLLOW=false
fi

# 检查 targetWallets
if grep -A 10 "targetWallets:" "$CONFIG_FILE" | grep -q "0x[a-fA-F0-9]\{40\}" 2>/dev/null; then
    echo -e "${GREEN}✅ targetWallets 已配置${NC}"
    WALLET_COUNT=$(grep -A 10 "targetWallets:" "$CONFIG_FILE" | grep -c "0x[a-fA-F0-9]\{40\}" || echo "0")
    echo -e "   钱包数量: $WALLET_COUNT"
    HAS_TARGET_WALLETS=true
else
    echo -e "${YELLOW}⚠️  targetWallets 未配置或为空${NC}"
    HAS_TARGET_WALLETS=false
fi

echo ""

# 生成修复后的配置
echo -e "${CYAN}🔧 生成修复后的配置...${NC}"

# 创建临时配置文件
TEMP_CONFIG=$(mktemp)

cat > "$TEMP_CONFIG" << 'EOF'
/**
 * 钱包跟单配置
 * 已通过自动修复脚本配置
 */

export default {
  // poly-sdk 配置
  sdk: {
    // 私钥（用于交易功能，如果只读可以留空）
    privateKey: 'PRIVATE_KEY_PLACEHOLDER',
    
    // 链ID（Polygon 主网是 137，默认值）
    chainId: 137,
  },

  // 目标钱包列表（要跟单的钱包地址）
  targetWallets: [
    TARGET_WALLETS_PLACEHOLDER
  ],

  // 获取顶级交易者数量（当 targetWallets 为空时使用）
  topTradersCount: 10,

  // 跟单设置
  followSettings: {
    // 跟单比例（0-1之间，例如 0.1 表示跟单10%的交易量）
    sizeScale: 0.1,
    
    // 最大单笔跟单金额（美元）
    maxSizePerTrade: 10,
    
    // 最小单笔跟单金额（美元）
    minTradeSize: 1,
    
    // 滑点容忍度（0-1之间，例如 0.03 表示3%）
    maxSlippage: 0.03,
    
    // 订单类型：'FOK'（全部成交或取消）或 'FAK'（部分成交也可以）
    orderType: 'FOK',
    
    // 是否启用自动跟单
    autoFollow: true,
    
    // 测试模式（dry run）- 设置为 false 才会执行真实交易
    dryRun: false,
    
    // 监听间隔（毫秒）- 仅用于手动监听模式
    watchInterval: 5000,
  },

  // 过滤条件（仅用于手动监听模式）
  filters: {
    // 最小胜率（0-1之间，0 或 undefined 表示不限制）
    // minWinRate: 0,
    
    // 最小智能评分（0-100，0 或 undefined 表示不限制）
    // minSmartScore: 0,
    
    // 排除的代币地址列表
    excludeTokens: [],
  }
};
EOF

# 替换占位符
sed -i "s|PRIVATE_KEY_PLACEHOLDER|$PRIVATE_KEY|g" "$TEMP_CONFIG"

# 生成钱包列表
WALLET_LIST=""
for wallet in "${TARGET_WALLETS[@]}"; do
    if [ -z "$WALLET_LIST" ]; then
        WALLET_LIST="    '$wallet'"
    else
        WALLET_LIST="$WALLET_LIST,
    '$wallet'"
    fi
done

# 使用 awk 替换占位符（更安全）
awk -v wallets="$WALLET_LIST" '{gsub(/TARGET_WALLETS_PLACEHOLDER/, wallets); print}' "$TEMP_CONFIG" > "${TEMP_CONFIG}.tmp"
mv "${TEMP_CONFIG}.tmp" "$TEMP_CONFIG"

# 检查是否需要修复
NEED_FIX=false

if [ "$HAS_PRIVATE_KEY" = false ] || [ "$HAS_AUTOFOLLOW" = false ] || [ "$HAS_TARGET_WALLETS" = false ]; then
    NEED_FIX=true
fi

if [ "$NEED_FIX" = true ]; then
    echo -e "${YELLOW}⚠️  发现配置问题，开始修复...${NC}"
    echo ""
    
    # 询问确认
    read -p "是否应用修复？(Y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        echo -e "${YELLOW}已取消修复${NC}"
        rm -f "$TEMP_CONFIG"
        exit 0
    fi
    
    # 应用修复
    cp "$TEMP_CONFIG" "$CONFIG_FILE"
    echo -e "${GREEN}✅ 配置已修复${NC}"
else
    echo -e "${GREEN}✅ 配置检查通过，无需修复${NC}"
fi

rm -f "$TEMP_CONFIG"

echo ""
echo -e "${CYAN}📋 修复后的配置摘要:${NC}"
echo -e "   私钥: ${GREEN}已配置${NC} ($(echo $PRIVATE_KEY | cut -c1-10)...)"
echo -e "   自动跟单: ${GREEN}已启用${NC}"
echo -e "   目标钱包: ${GREEN}已配置${NC} (${#TARGET_WALLETS[@]} 个)"
echo -e "   测试模式: ${RED}已禁用（真实交易模式）${NC}"
echo ""

# 验证配置
echo -e "${CYAN}🔍 验证配置...${NC}"
if node -e "import('./config.js').then(c => { const cfg = c.default; console.log('验证结果:'); console.log('  私钥:', cfg.sdk?.privateKey ? '✅ 已配置 (' + cfg.sdk.privateKey.length + ' 字符)' : '❌ 未配置'); console.log('  自动跟单:', cfg.followSettings?.autoFollow === true ? '✅ 已启用' : '❌ 未启用'); console.log('  目标钱包:', cfg.targetWallets?.length || 0, '个'); console.log('  测试模式:', cfg.followSettings?.dryRun === false ? '❌ 否（真实交易）' : '✅ 是'); }).catch(e => console.error('❌ 验证失败:', e.message));" 2>&1; then
    echo -e "${GREEN}✅ 配置验证通过${NC}"
else
    echo -e "${RED}❌ 配置验证失败，请手动检查${NC}"
    echo -e "${YELLOW}💡 可以使用备份文件恢复: $CONFIG_BACKUP${NC}"
fi

echo ""
echo -e "${CYAN}📝 下一步:${NC}"
echo -e "   1. 检查配置: cat config.js"
echo -e "   2. 运行程序: npm start"
echo -e "   3. 如果出错，恢复备份: cp $CONFIG_BACKUP config.js"
echo ""
