# 🚀 如何运行 PolyBot

## 快速开始

### 1. 检查环境

确保已安装 Node.js（版本 >= 16）：

```bash
node --version
npm --version
```

### 2. 安装依赖

```bash
npm install
```

如果遇到网络问题，可以使用淘宝镜像：

```bash
npm config set registry https://registry.npmmirror.com
npm install
```

### 3. 配置项目

编辑 `config.js` 文件（如果没有，复制示例文件）：

```bash
# Windows
copy config.example.js config.js

# Linux/Mac
cp config.example.js config.js
```

然后编辑 `config.js`，设置：
- **私钥**（如果需要交易功能）
- **目标钱包**（要跟单的钱包地址）
- **跟单参数**（跟单比例、金额限制等）

### 4. 运行项目

#### 方式一：直接运行（推荐测试）

```bash
npm start
```

#### 方式二：开发模式（自动重启）

```bash
npm run dev
```

#### 方式三：使用 PM2（后台运行，推荐生产环境）

```bash
# 全局安装 PM2
npm install -g pm2

# 启动
npm run pm2:start

# 查看日志
npm run pm2:logs

# 查看状态
pm2 status

# 停止
npm run pm2:stop

# 重启
npm run pm2:restart
```

## 运行模式

### 只读模式（查看钱包信息）

不需要私钥，仅查看和分析钱包信息：

```javascript
// config.js
sdk: {
  privateKey: '',  // 留空
}
followSettings: {
  autoFollow: false,  // 禁用自动跟单
}
```

运行：
```bash
npm start
```

### 测试模式（推荐首次使用）

```javascript
// config.js
sdk: {
  privateKey: '0x您的私钥',
}
followSettings: {
  autoFollow: true,
  dryRun: true,  // ✅ 测试模式，不会执行真实交易
  sizeScale: 0.1,  // 跟单10%
  maxSizePerTrade: 5,  // 最大$5（测试用小金额）
}
```

运行：
```bash
npm start
```

### 真实交易模式

⚠️ **警告：只有在充分测试后才启用真实交易！**

```javascript
// config.js
sdk: {
  privateKey: '0x您的私钥',
}
followSettings: {
  autoFollow: true,
  dryRun: false,  // ⚠️ 真实交易模式
  sizeScale: 0.1,  // 跟单10%
  maxSizePerTrade: 10,  // 最大$10
  minTradeSize: 5,  // 最小$5
}
```

运行：
```bash
npm start
```

## 运行示例

### 示例 1：查看顶级交易者

```bash
# 1. 配置 config.js
targetWallets: [],  # 留空
topTradersCount: 10,
followSettings: {
  autoFollow: false,  # 仅查看
}

# 2. 运行
npm start
```

### 示例 2：跟单特定钱包（测试模式）

```bash
# 1. 配置 config.js
targetWallets: [
  '0x1234...',  # 要跟单的钱包地址
],
followSettings: {
  autoFollow: true,
  dryRun: true,  # 测试模式
  sizeScale: 0.1,  # 跟单10%
}

# 2. 运行
npm start
```

### 示例 3：后台运行（PM2）

```bash
# 1. 安装 PM2
npm install -g pm2

# 2. 启动（后台运行）
pm2 start index.js --name polybot

# 3. 查看日志
pm2 logs polybot

# 4. 查看状态
pm2 status

# 5. 设置开机自启
pm2 save
pm2 startup
```

## 常见问题

### Q: 运行后显示 "未找到配置文件"

A: 确保 `config.js` 文件存在：
```bash
cp config.example.js config.js
```

### Q: 显示 "无法连接到 SDK"

A: 
1. 检查网络连接
2. 确认依赖已安装：`npm install`
3. 查看详细错误信息

### Q: 显示 "私钥错误" 或 "认证失败"

A:
1. 检查私钥格式是否正确（以 `0x` 开头）
2. 确认私钥对应的账户有足够的 USDC 余额
3. 如果只是查看信息，可以设置 `privateKey: ''`（留空）

### Q: 没有检测到交易

A:
1. 确认目标钱包有活跃交易
2. 检查 `minTradeSize` 设置是否太大
3. 查看日志了解详细信息

### Q: 如何停止运行

A:
- 如果前台运行：按 `Ctrl+C`
- 如果使用 PM2：`pm2 stop polybot`

## 运行时的输出

正常运行时会看到：

```
╔════════════════════════════════════════════╗
║         PolyBot - 钱包跟单机器人          ║
╚════════════════════════════════════════════╝

🔧 初始化 poly-sdk...
✅ poly-sdk 初始化成功

🚀 初始化钱包跟单系统...
📊 获取前 10 名顶级交易者...
✅ 成功加载 10 名交易者
✅ 初始化完成，正在监听 X 个钱包

🎯 自动跟单已启用，开始监听...

⏳ 程序运行中... (按 Ctrl+C 退出)
```

## 环境变量方式（推荐）

更安全的方式是使用环境变量存储私钥：

**Windows (PowerShell):**
```powershell
$env:POLYMARKET_PRIVATE_KEY="0x您的私钥"
npm start
```

**Windows (CMD):**
```cmd
set POLYMARKET_PRIVATE_KEY=0x您的私钥
npm start
```

**Linux/Mac:**
```bash
export POLYMARKET_PRIVATE_KEY=0x您的私钥
npm start
```

然后在 `config.js` 中：
```javascript
privateKey: process.env.POLYMARKET_PRIVATE_KEY || '',
```

## 日志查看

- **前台运行**：日志直接输出到控制台
- **PM2 运行**：使用 `pm2 logs polybot` 查看
- **保存日志**：`pm2 logs polybot > logs.txt`（重定向到文件）

## 下一步

- 查看 [USAGE.md](USAGE.md) 了解详细使用说明
- 查看 [DEPLOY.md](DEPLOY.md) 了解服务器部署
- 查看 [README.md](README.md) 了解完整功能

---

**祝运行顺利！** 🚀
