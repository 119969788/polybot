# 使用指南

## 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置

编辑 `config.js` 文件，或者使用环境变量：

```bash
# 创建 .env 文件
echo "POLYMARKET_PRIVATE_KEY=0x你的私钥" > .env
```

### 3. 运行

#### 只读模式（查看钱包信息）

```bash
# 不需要私钥，仅查看和分析
npm start
```

#### 测试模式（推荐首次使用）

在 `config.js` 中设置：

```javascript
followSettings: {
  autoFollow: true,
  dryRun: true,  // 测试模式，不会执行真实交易
  sizeScale: 0.1,  // 跟单10%
  maxSizePerTrade: 5,  // 最大$5（测试用小金额）
}
```

然后运行：

```bash
npm start
```

## 使用场景

### 场景1：跟单特定钱包

假设你发现了一个优秀的交易者钱包地址 `0xABC...`，想要跟单：

1. 编辑 `config.js`：

```javascript
targetWallets: [
  '0xABC...',  // 你的目标钱包
],
followSettings: {
  autoFollow: true,
  sizeScale: 0.1,  // 跟单10%
  maxSizePerTrade: 10,  // 最大$10
  minTradeSize: 5,  // 最小$5
  dryRun: true,  // 先测试
}
```

2. 运行：`npm start`

### 场景2：跟单排行榜前10名

自动从排行榜获取顶级交易者并跟单：

1. 编辑 `config.js`：

```javascript
targetWallets: [],  // 留空，从排行榜获取
topTradersCount: 10,
filters: {
  minWinRate: 0.6,  // 只跟单胜率>60%的
  minSmartScore: 75,  // 智能评分>75的
},
followSettings: {
  autoFollow: true,
  sizeScale: 0.05,  // 跟单5%（因为是多个钱包）
  maxSizePerTrade: 5,
  dryRun: true,
}
```

2. 运行：`npm start`

### 场景3：只跟单买入交易

如果你只想跟单买入，忽略卖出：

```javascript
followSettings: {
  autoFollow: true,
  sideFilter: 'BUY',  // 只跟单买入
  sizeScale: 0.15,  // 跟单15%
  dryRun: true,
}
```

## 配置参数详解

### 跟单比例 (sizeScale)

- `0.1` = 跟单10%（如果对方买入$100，你买入$10）
- `0.2` = 跟单20%
- `1.0` = 完全跟单（不推荐，风险大）

**建议**：刚开始使用 `0.05-0.1`（5%-10%）

### 金额限制

- `minTradeSize`: 最小跟单金额（低于此金额不跟单）
  - 建议：`5`（$5）
  - Polymarket 最小订单是 $1，但建议至少 $5

- `maxSizePerTrade`: 最大单笔跟单金额
  - 建议：根据你的资金量设置
  - 例如：总资金 $1000，设置 `maxSizePerTrade: 50`

### 滑点容忍度 (maxSlippage)

- `0.01` = 1%（严格，可能错过机会）
- `0.03` = 3%（推荐）
- `0.05` = 5%（宽松，可能成交价较差）

### 订单类型

- `FOK` (Fill Or Kill): 全部成交或取消
  - 优点：确保全部成交
  - 缺点：可能失败
  
- `FAK` (Fill And Kill): 部分成交也可以
  - 优点：更容易成交
  - 缺点：可能只部分成交

**建议**：使用 `FOK` 更安全

## 安全建议

1. **先测试再实战**
   - 始终先使用 `dryRun: true` 测试
   - 观察一段时间，确认逻辑正确
   - 再设置 `dryRun: false`

2. **从小金额开始**
   - 第一次真实交易，使用很小的金额（如 $1-$5）
   - 确认一切正常后，再逐步增加

3. **设置合理的限制**
   - `maxSizePerTrade` 不要超过你总资金的 5-10%
   - `sizeScale` 不要太大（建议 0.1 以下）

4. **定期检查**
   - 定期查看跟单统计
   - 如果表现不佳，及时调整或停止

5. **保护私钥**
   - 永远不要将私钥提交到 Git
   - 使用环境变量存储私钥
   - 不要在不安全的设备上运行

## 常见问题

### Q: 为什么没有检测到交易？

A: 可能的原因：
- 目标钱包最近没有交易
- `minTradeSize` 设置太大
- 过滤条件太严格
- 检查日志查看详细信息

### Q: 交易执行失败怎么办？

A: 检查：
1. 账户是否有足够的 USDC 余额
2. 订单金额是否满足最小要求（$1）
3. 滑点是否在容忍范围内
4. 网络连接是否正常
5. 查看日志中的详细错误信息

### Q: 如何停止跟单？

A: 按 `Ctrl+C` 停止程序，程序会优雅退出并显示统计信息。

### Q: 可以同时跟单多个钱包吗？

A: 可以。`startAutoCopyTrading` 支持同时跟单多个钱包。建议：
- 如果跟单多个钱包，降低每个钱包的 `sizeScale`
- 例如：跟单10个钱包，每个设置 `sizeScale: 0.05`（5%）

### Q: 测试模式和真实模式有什么区别？

A: 
- `dryRun: true` (测试模式)：只模拟交易，不实际下单，不消耗资金
- `dryRun: false` (真实模式)：真实下单，会消耗资金

## 获取帮助

- 查看 [poly-sdk 文档](https://github.com/cyl19970726/poly-sdk)
- 检查日志输出了解详细信息
- 确保使用最新版本的 SDK
