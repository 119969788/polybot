#!/bin/bash

# 在服务器上直接创建诊断工具文件
# 如果无法上传文件，可以使用此脚本

cd /opt/polybot || exit 1

echo "📝 创建诊断工具文件..."

cat > diagnose-failures.js << 'EOF'
/**
 * 跟单失败诊断工具
 * 用于检查可能导致跟单失败的常见问题
 */

import PolymarketSDK from '@catalyst-team/poly-sdk';
import config from './config.js';

async function diagnoseCopyTradingIssues() {
  console.log('╔════════════════════════════════════════════╗');
  console.log('║      跟单失败诊断工具                      ║');
  console.log('╚════════════════════════════════════════════╝');
  console.log('');

  const issues = [];
  const warnings = [];
  const suggestions = [];

  // 1. 检查 SDK 初始化
  console.log('🔍 检查 1: SDK 初始化...');
  let sdk;
  try {
    const privateKey = (config.sdk?.privateKey || process.env.POLYMARKET_PRIVATE_KEY || '').trim();
    
    if (privateKey) {
      try {
        sdk = new PolymarketSDK({
          privateKey: privateKey,
          chainId: config.sdk?.chainId || 137,
        });
        console.log('   ✅ SDK 初始化成功（交易模式）');
      } catch (error) {
        console.log('   ⚠️  交易模式初始化失败，使用只读模式');
        sdk = new PolymarketSDK();
        issues.push('交易服务不可用 - 可能是钱包未在 Polymarket 注册或网络问题');
      }
    } else {
      sdk = new PolymarketSDK();
      console.log('   ⚠️  未配置私钥，使用只读模式');
      warnings.push('未配置私钥，无法执行交易');
    }
  } catch (error) {
    console.log(`   ❌ SDK 初始化失败: ${error.message}`);
    issues.push(`SDK 初始化失败: ${error.message}`);
    return;
  }
  console.log('');

  // 2. 检查配置
  console.log('🔍 检查 2: 配置参数...');
  const settings = config.followSettings || {};
  
  // 检查订单类型
  if (settings.orderType === 'FOK') {
    console.log('   ⚠️  订单类型: FOK（可能因无法全部成交而失败）');
    suggestions.push('考虑改用 FAK 订单类型以提高成功率');
  } else if (settings.orderType === 'FAK') {
    console.log('   ✅ 订单类型: FAK（允许部分成交）');
  } else {
    console.log(`   ⚠️  订单类型: ${settings.orderType || '未设置'}（默认可能是 FOK）`);
    suggestions.push('建议明确设置 orderType: "FAK"');
  }

  // 检查滑点
  const slippage = settings.maxSlippage || 0.03;
  if (slippage < 0.03) {
    console.log(`   ⚠️  滑点容忍度: ${slippage * 100}%（可能过小）`);
    suggestions.push('考虑增加 maxSlippage 到 0.05 (5%)');
  } else {
    console.log(`   ✅ 滑点容忍度: ${slippage * 100}%`);
  }

  // 检查金额设置
  const minTradeSize = settings.minTradeSize || 1;
  if (minTradeSize < 1) {
    console.log(`   ❌ 最小交易金额: $${minTradeSize}（低于平台最小值 $1）`);
    issues.push('minTradeSize 必须 >= 1');
  } else {
    console.log(`   ✅ 最小交易金额: $${minTradeSize}`);
  }

  const maxSizePerTrade = settings.maxSizePerTrade || 10;
  console.log(`   ✅ 最大单笔金额: $${maxSizePerTrade}`);

  // 检查跟单比例
  const sizeScale = settings.sizeScale || 0.1;
  console.log(`   ✅ 跟单比例: ${sizeScale * 100}%`);
  console.log('');

  // 3. 检查目标钱包
  console.log('🔍 检查 3: 目标钱包配置...');
  if (config.targetWallets && config.targetWallets.length > 0) {
    console.log(`   ✅ 配置了 ${config.targetWallets.length} 个目标钱包`);
    
    // 验证钱包地址格式
    for (const addr of config.targetWallets) {
      if (!addr.startsWith('0x') || addr.length !== 42) {
        console.log(`   ❌ 无效的钱包地址: ${addr}`);
        issues.push(`无效的钱包地址: ${addr}`);
      }
    }
  } else {
    console.log('   ⚠️  未配置目标钱包，将从排行榜获取');
    if (config.topTradersCount <= 0) {
      issues.push('未配置目标钱包且 topTradersCount <= 0');
    }
  }
  console.log('');

  // 4. 检查账户余额（如果可能）
  console.log('🔍 检查 4: 账户状态...');
  if (sdk.tradingService) {
    try {
      console.log('   ℹ️  交易服务可用');
      console.log('   💡 建议：手动检查 Polymarket 账户 USDC 余额');
      console.log(`   💡 确保余额 >= $${maxSizePerTrade + 5}（最大单笔 + 手续费缓冲）`);
    } catch (error) {
      console.log('   ⚠️  无法查询余额（SDK 可能不支持）');
      warnings.push('无法自动检查账户余额，请手动确认');
    }
  } else {
    console.log('   ⚠️  交易服务不可用，无法检查余额');
    warnings.push('交易服务不可用，无法执行交易');
  }
  console.log('');

  // 5. 检查网络连接
  console.log('🔍 检查 5: 网络连接...');
  try {
    if (sdk.wallets) {
      await Promise.race([
        sdk.wallets.getTopTraders(1),
        new Promise((_, reject) => setTimeout(() => reject(new Error('超时')), 10000))
      ]);
      console.log('   ✅ 网络连接正常');
    } else {
      console.log('   ⚠️  无法测试网络连接');
    }
  } catch (error) {
    if (error.message.includes('超时')) {
      console.log('   ❌ 网络连接超时');
      issues.push('网络连接超时，可能需要配置代理');
      suggestions.push('配置 HTTP_PROXY 和 HTTPS_PROXY 环境变量');
    } else {
      console.log(`   ⚠️  网络测试失败: ${error.message}`);
      warnings.push(`网络连接可能有问题: ${error.message}`);
    }
  }
  console.log('');

  // 6. 检查测试模式
  console.log('🔍 检查 6: 运行模式...');
  if (settings.dryRun === false) {
    console.log('   ⚠️  真实交易模式（会消耗真实资金）');
    warnings.push('当前为真实交易模式，请确认配置正确');
  } else {
    console.log('   ✅ 测试模式（不会执行真实交易）');
    console.log('   💡 注意：测试模式下交易可能显示失败，这是正常的');
  }
  console.log('');

  // 7. 检查自动跟单配置
  console.log('🔍 检查 7: 自动跟单配置...');
  if (settings.autoFollow === true) {
    console.log('   ✅ 自动跟单已启用');
  } else {
    console.log('   ⚠️  自动跟单未启用');
    issues.push('autoFollow 未启用，不会执行跟单交易');
  }
  console.log('');

  // 总结
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📋 诊断结果:');
  console.log('');

  if (issues.length === 0 && warnings.length === 0) {
    console.log('✅ 未发现明显问题');
    console.log('');
    console.log('💡 如果仍然失败，可能的原因：');
    console.log('   1. 账户余额不足');
    console.log('   2. 市场深度不足（FOK 订单无法全部成交）');
    console.log('   3. 价格变动过快（滑点过大）');
    console.log('   4. 市场已关闭或条件不存在');
    console.log('   5. API 限流或临时网络问题');
    console.log('');
    console.log('💡 建议：');
    console.log('   - 查看详细错误日志');
    console.log('   - 检查具体错误信息');
    console.log('   - 根据错误类型调整配置');
  } else {
    if (issues.length > 0) {
      console.log('❌ 发现的问题:');
      issues.forEach((issue, i) => {
        console.log(`   ${i + 1}. ${issue}`);
      });
      console.log('');
    }

    if (warnings.length > 0) {
      console.log('⚠️  警告:');
      warnings.forEach((warning, i) => {
        console.log(`   ${i + 1}. ${warning}`);
      });
      console.log('');
    }
  }

  if (suggestions.length > 0) {
    console.log('💡 建议:');
    suggestions.forEach((suggestion, i) => {
      console.log(`   ${i + 1}. ${suggestion}`);
    });
    console.log('');
  }

  // 推荐配置
  console.log('📝 推荐配置（提高成功率）:');
  console.log('```javascript');
  console.log('followSettings: {');
  console.log('  orderType: "FAK",        // 允许部分成交');
  console.log('  maxSlippage: 0.05,       // 5% 滑点');
  console.log('  maxSizePerTrade: 10,      // 根据余额调整');
  console.log('  minTradeSize: 1,         // 最小 $1');
  console.log('  autoFollow: true,         // 启用自动跟单');
  console.log('  dryRun: true,             // 测试模式');
  console.log('}');
  console.log('```');
  console.log('');

  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
}

// 运行诊断
diagnoseCopyTradingIssues().catch(error => {
  console.error('❌ 诊断过程出错:', error);
  process.exit(1);
});
EOF

echo "✅ 文件创建完成"
chmod +x diagnose-failures.js

echo ""
echo "📋 验证文件:"
ls -lh diagnose-failures.js

echo ""
echo "🔍 验证语法:"
node --check diagnose-failures.js && echo "✅ 语法正确" || echo "❌ 语法错误"

echo ""
echo "💡 现在可以运行:"
echo "   node diagnose-failures.js"
