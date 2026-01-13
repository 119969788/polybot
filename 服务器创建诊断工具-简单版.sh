#!/bin/bash

# 简化版：直接在服务器上创建诊断工具
# 如果无法上传文件，运行此脚本

cd /opt/polybot || exit 1

echo "📝 创建诊断工具文件..."

# 检查是否已存在
if [ -f "diagnose-failures.js" ]; then
    echo "⚠️  文件已存在，是否覆盖？(y/n)"
    read -r answer
    if [ "$answer" != "y" ] && [ "$answer" != "Y" ]; then
        echo "❌ 取消操作"
        exit 0
    fi
fi

# 使用 heredoc 创建文件
cat > diagnose-failures.js << 'DIAG_EOF'
/**
 * 跟单失败诊断工具
 */

import PolymarketSDK from '@catalyst-team/poly-sdk';
import config from './config.js';

async function diagnose() {
  console.log('╔════════════════════════════════════════════╗');
  console.log('║      跟单失败诊断工具                      ║');
  console.log('╚════════════════════════════════════════════╝\n');

  const issues = [];
  const suggestions = [];
  const settings = config.followSettings || {};

  // 检查订单类型
  console.log('🔍 配置检查:');
  if (settings.orderType === 'FOK') {
    console.log('   ⚠️  订单类型: FOK（可能因无法全部成交而失败）');
    suggestions.push('改用 orderType: "FAK"');
  } else {
    console.log(`   ✅ 订单类型: ${settings.orderType || 'FOK'}`);
  }

  // 检查滑点
  const slippage = settings.maxSlippage || 0.03;
  if (slippage < 0.05) {
    console.log(`   ⚠️  滑点: ${slippage * 100}%（建议 >= 5%）`);
    suggestions.push('增加 maxSlippage 到 0.05');
  } else {
    console.log(`   ✅ 滑点: ${slippage * 100}%`);
  }

  console.log(`   ✅ 最大单笔: $${settings.maxSizePerTrade || 10}`);
  console.log(`   ✅ 测试模式: ${settings.dryRun !== false ? '是' : '否'}\n`);

  // SDK 测试
  console.log('🔍 SDK 测试:');
  try {
    const privateKey = (config.sdk?.privateKey || process.env.POLYMARKET_PRIVATE_KEY || '').trim();
    if (privateKey) {
      const sdk = new PolymarketSDK({
        privateKey: privateKey,
        chainId: config.sdk?.chainId || 137,
      });
      if (sdk.tradingService) {
        console.log('   ✅ 交易服务可用');
      } else {
        console.log('   ⚠️  交易服务不可用');
        issues.push('交易服务不可用');
      }
    } else {
      console.log('   ⚠️  未配置私钥');
    }
  } catch (error) {
    console.log(`   ⚠️  SDK 初始化失败: ${error.message}`);
    issues.push('SDK 初始化失败');
  }

  // 总结
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  if (issues.length === 0 && suggestions.length === 0) {
    console.log('✅ 配置正常');
    console.log('\n💡 如果仍然失败，请检查:');
    console.log('   1. 账户 USDC 余额');
    console.log('   2. 网络连接');
    console.log('   3. 查看详细错误日志');
  } else {
    if (suggestions.length > 0) {
      console.log('💡 建议:');
      suggestions.forEach((s, i) => console.log(`   ${i + 1}. ${s}`));
    }
  }
  console.log('');
}

diagnose().catch(console.error);
DIAG_EOF

chmod +x diagnose-failures.js

echo "✅ 文件创建完成"
echo ""
echo "📋 验证:"
node --check diagnose-failures.js && echo "✅ 语法正确" || echo "❌ 语法错误"
echo ""
echo "💡 运行: node diagnose-failures.js"
