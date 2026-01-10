# PolyBot - 钱包跟单机器人

基于 [@catalyst-team/poly-sdk](https://github.com/cyl19970726/poly-sdk) 实现的 Polymarket 钱包跟单机器人。

## 功能特性

- 🎯 获取顶级交易者列表
- 📊 获取钱包详细资料和交易统计
- 👀 实时监听钱包交易活动
- 🔄 自动跟单功能（使用 SmartMoneyService）
- 📈 跟踪群体卖出比例
- 🛡️ 支持测试模式（dry run）
- ⚙️ 灵活配置（跟单比例、金额限制、滑点容忍度等）

## 安装

```bash
npm install
```

## 配置

### 方式一：使用环境变量（推荐）

创建 `.env` 文件（不要提交到 Git）：

```bash
POLYMARKET_PRIVATE_KEY=0x你的私钥
```

然后修改 `config.js` 中的配置。

### 方式二：直接修改配置文件

编辑 `config.js` 文件，填入您的配置。

⚠️ **重要提示**：
- 请妥善保管您的私钥，不要提交到版本控制系统
- 默认启用了 `dryRun: true`（测试模式），不会执行真实交易
- 只有在完全理解风险并确认无误后，才设置 `dryRun: false`

## 使用方法

### 只读模式（查看钱包信息）

```bash
# 不需要私钥，仅查看和分析钱包
npm start
```

### 自动跟单模式

1. 在 `config.js` 中设置 `privateKey` 和 `autoFollow: true`
2. 配置跟单参数（跟单比例、金额限制等）
3. 运行：

```bash
npm start
```

### 测试模式（推荐首次使用）

```javascript
// config.js
followSettings: {
  autoFollow: true,
  dryRun: true,  // 测试模式，不会执行真实交易
  sizeScale: 0.1,  // 跟单10%
  maxSizePerTrade: 10,  // 最大$10
}
```

## 配置说明

### 基本配置

- `sdk.privateKey`: 私钥（留空则为只读模式）
- `sdk.chainId`: 链ID（默认137，Polygon主网）
- `targetWallets`: 要跟单的钱包地址列表（留空则从排行榜获取）
- `topTradersCount`: 从排行榜获取的顶级交易者数量

### 跟单设置

- `sizeScale`: 跟单比例（0-1，例如 0.1 = 10%）
- `maxSizePerTrade`: 最大单笔跟单金额（美元）
- `minTradeSize`: 最小跟单金额（美元，低于此金额不跟单）
- `maxSlippage`: 滑点容忍度（0-1，例如 0.03 = 3%）
- `orderType`: 订单类型（'FOK' 或 'FAK'）
- `autoFollow`: 是否启用自动跟单
- `dryRun`: 测试模式（true = 仅模拟，false = 真实交易）
- `sideFilter`: 过滤方向（'BUY' 或 'SELL'，可选）

### 过滤条件

- `filters.minWinRate`: 最小胜率（0-1）
- `filters.minSmartScore`: 最小智能评分（0-100）

## 工作流程

1. **初始化**: SDK 连接到 Polymarket
2. **获取目标钱包**: 
   - 如果配置了 `targetWallets`，使用这些钱包
   - 否则从排行榜获取前 N 名交易者
   - 应用过滤条件筛选
3. **开始监听**: 
   - 自动跟单模式：使用 SmartMoneyService 实时监听并跟单
   - 手动模式：定期检查钱包活动
4. **执行跟单**: 当检测到符合条件的交易时，自动执行跟单

## 示例场景

### 场景1：跟单特定钱包

```javascript
targetWallets: [
  '0x1234...',  // 你要跟单的钱包地址
],
followSettings: {
  autoFollow: true,
  sizeScale: 0.1,  // 跟单10%
  dryRun: true,  // 先测试
}
```

### 场景2：跟单排行榜前10名

```javascript
targetWallets: [],  // 留空
topTradersCount: 10,
filters: {
  minWinRate: 0.6,  // 只跟单胜率>60%的
  minSmartScore: 75,  // 智能评分>75的
}
```

### 场景3：只跟单买入交易

```javascript
followSettings: {
  sideFilter: 'BUY',  // 只跟单买入
  sizeScale: 0.2,  // 跟单20%
}
```

## 安全提示

⚠️ **风险提示**：
- 跟单交易存在资金损失风险
- 请充分测试后再使用真实资金
- 建议从小额开始，逐步增加
- 定期检查和调整策略
- 不要使用超过您能承受损失的资金

## 故障排除

### 问题：无法连接 SDK

- 检查网络连接
- 确认 SDK 版本正确：`npm list @catalyst-team/poly-sdk`

### 问题：交易执行失败

- 检查私钥是否正确
- 确认账户有足够的 USDC 余额
- 检查订单金额是否满足最小要求（$1）
- 查看日志了解详细错误信息

### 问题：没有检测到交易

- 确认目标钱包有活跃交易
- 检查过滤条件是否太严格
- 确认 `minTradeSize` 设置合理

## 相关链接

- [poly-sdk GitHub](https://github.com/cyl19970726/poly-sdk)
- [poly-sdk 文档](https://github.com/cyl19970726/poly-sdk#readme)
- [Polymarket 官网](https://polymarket.com/)

## 许可证

MIT
