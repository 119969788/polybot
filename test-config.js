/**
 * 配置测试脚本
 */
import config from './config.js';

console.log('╔════════════════════════════════════════════╗');
console.log('║          配置检查工具                      ║');
console.log('╚════════════════════════════════════════════╝\n');

console.log('📋 配置信息:');
console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

// 检查私钥
const privateKey = config.sdk?.privateKey || '';
console.log(`私钥: ${privateKey ? `✅ 已配置 (${privateKey.length} 字符, 前10字符: ${privateKey.substring(0, 10)}...)` : '❌ 未配置'}`);

// 检查链ID
console.log(`链ID: ${config.sdk?.chainId || 137}`);

// 检查目标钱包
console.log(`目标钱包数量: ${config.targetWallets?.length || 0}`);
if (config.targetWallets && config.targetWallets.length > 0) {
  config.targetWallets.forEach((wallet, index) => {
    console.log(`  ${index + 1}. ${wallet}`);
  });
}

// 检查跟单设置
console.log(`\n跟单设置:`);
console.log(`  自动跟单: ${config.followSettings?.autoFollow ? '✅ 已启用' : '❌ 已禁用'}`);
console.log(`  测试模式: ${config.followSettings?.dryRun !== false ? '✅ 是' : '❌ 否'}`);
console.log(`  跟单比例: ${(config.followSettings?.sizeScale || 0.1) * 100}%`);
console.log(`  最大单笔: $${config.followSettings?.maxSizePerTrade || 10}`);
console.log(`  最小单笔: $${config.followSettings?.minTradeSize || 5}`);

// 检查过滤条件
console.log(`\n过滤条件:`);
const filters = config.filters || {};
const hasFilters = (filters.minWinRate !== undefined && filters.minWinRate > 0) || 
                   (filters.minSmartScore !== undefined && filters.minSmartScore > 0);
console.log(`  过滤条件: ${hasFilters ? '⚠️  已启用（可能会过滤钱包）' : '✅ 未启用（不过滤）'}`);
if (hasFilters) {
  if (filters.minWinRate) console.log(`    最小胜率: ${filters.minWinRate * 100}%`);
  if (filters.minSmartScore) console.log(`    最小评分: ${filters.minSmartScore}`);
}

console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
console.log('✅ 配置检查完成\n');
