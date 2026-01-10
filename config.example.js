/**
 * 钱包跟单配置示例
 * 复制此文件为 config.js 并填入实际配置
 */

export default {
  // poly-sdk 配置
  sdk: {
    // 私钥（用于交易功能，如果只读可以留空）
    // privateKey: process.env.POLYMARKET_PRIVATE_KEY || '0x...',
    
    // 链ID（Polygon 主网是 137，默认值）
    // chainId: 137,
  },

  // 目标钱包列表（要跟单的钱包地址）
  targetWallets: [
    // '0x1234567890123456789012345678901234567890',
    // '0xabcdefabcdefabcdefabcdefabcdefabcdefabcd'
  ],

  // 获取顶级交易者数量
  topTradersCount: 10,

  // 跟单设置
  followSettings: {
    // 跟单比例（0-1之间，例如 0.1 表示跟单10%）
    followRatio: 0.1,
    
    // 最小跟单金额（美元）
    minAmount: 10,
    
    // 最大跟单金额（美元）
    maxAmount: 1000,
    
    // 是否启用自动跟单
    autoFollow: false,
    
    // 监听间隔（毫秒）
    watchInterval: 5000,
  },

  // 过滤条件
  filters: {
    // 最小胜率（0-1之间）
    minWinRate: 0.5,
    
    // 最小智能评分（0-100）
    minSmartScore: 70,
    
    // 排除的代币地址列表
    excludeTokens: [],
  }
};
