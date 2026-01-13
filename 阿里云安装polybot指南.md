# 🚀 阿里云服务器安装 PolyBot 指南

本指南将帮助您在阿里云 ECS 服务器上安装并运行 [polybot](https://github.com/119969788/polybot)。

## 📋 前置要求

- 阿里云 ECS 实例（Ubuntu 20.04/22.04 或 CentOS 7/8）
- 已配置 SSH 访问
- root 或具有 sudo 权限的用户

## 🚀 快速安装（推荐）

### 方法一：使用安装脚本（最简单）

```bash
# 1. 连接到服务器
ssh root@your_server_ip

# 2. 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/119969788/polybot/main/install.sh | bash

# 或者手动下载
wget https://raw.githubusercontent.com/119969788/polybot/main/install.sh
chmod +x install.sh
sudo bash install.sh
```

### 方法二：使用本地脚本

如果您已经有脚本文件：

```bash
# 1. 上传脚本到服务器（在本地执行）
scp 阿里云安装polybot.sh user@server:/tmp/

# 2. 在服务器上执行
ssh user@server
bash /tmp/阿里云安装polybot.sh
```

## 📝 手动安装步骤

### 步骤 1: 连接到服务器

```bash
ssh root@your_server_ip
# 或者使用密钥
ssh -i your_key.pem root@your_server_ip
```

### 步骤 2: 更新系统包

**Ubuntu/Debian:**

```bash
apt update && apt upgrade -y
apt install -y curl git
```

**CentOS/RHEL:**

```bash
yum update -y
yum install -y curl git
```

### 步骤 3: 安装 Node.js

**Ubuntu/Debian:**

```bash
# 安装 Node.js 18.x LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 验证安装
node --version
npm --version
```

**CentOS/RHEL:**

```bash
# 安装 Node.js 18.x LTS
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# 验证安装
node --version
npm --version
```

### 步骤 4: 安装 PM2（推荐）

```bash
npm install -g pm2

# 验证安装
pm2 --version
```

### 步骤 5: 克隆项目

```bash
# 创建项目目录
mkdir -p /opt/polybot
cd /opt/polybot

# 克隆项目
git clone https://github.com/119969788/polybot.git .

# 或者如果目录已存在，先删除再克隆
rm -rf /opt/polybot
git clone https://github.com/119969788/polybot.git /opt/polybot
cd /opt/polybot
```

### 步骤 6: 安装依赖

```bash
cd /opt/polybot
npm install
```

### 步骤 7: 配置项目

```bash
# 复制示例配置文件
cp config.example.js config.js

# 编辑配置文件
nano config.js
# 或使用 vi
vi config.js
```

**重要配置项：**

```javascript
export default {
  sdk: {
    privateKey: process.env.POLYMARKET_PRIVATE_KEY || '你的私钥',
    chainId: 137,
  },
  targetWallets: [
    '0x...',  // 要跟单的钱包地址
  ],
  followSettings: {
    autoFollow: true,
    dryRun: true,  // ✅ 测试模式 - 不会执行真实交易
    sizeScale: 0.1,
    maxSizePerTrade: 10,
  },
  // ...
};
```

## 🎯 运行项目

### 测试运行（前台）

```bash
cd /opt/polybot
npm start
```

按 `Ctrl+C` 停止。

### 使用 PM2 运行（后台）

```bash
cd /opt/polybot

# 启动
pm2 start index.js --name polybot

# 保存进程列表（开机自启需要）
pm2 save

# 设置开机自启
pm2 startup
# 执行上面命令输出的命令（类似：sudo env PATH=... pm2 startup ...）

# 查看状态
pm2 list

# 查看日志
pm2 logs polybot

# 实时监控
pm2 monit
```

### PM2 常用命令

```bash
pm2 list              # 查看所有进程
pm2 logs polybot      # 查看日志
pm2 restart polybot   # 重启
pm2 stop polybot      # 停止
pm2 delete polybot    # 删除进程
pm2 monit             # 监控面板
pm2 info polybot      # 查看详细信息
```

## 🔧 配置说明

### 基本配置

- `sdk.privateKey`: 私钥（留空则为只读模式）
- `sdk.chainId`: 链ID（默认137，Polygon主网）
- `targetWallets`: 要跟单的钱包地址列表
- `topTradersCount`: 从排行榜获取的顶级交易者数量

### 跟单设置

- `autoFollow`: 是否启用自动跟单（`true`/`false`）
- `dryRun`: 测试模式（`true` = 仅模拟，`false` = 真实交易）
- `sizeScale`: 跟单比例（0-1，例如 0.1 = 10%）
- `maxSizePerTrade`: 最大单笔跟单金额（美元）
- `minTradeSize`: 最小跟单金额（美元）
- `maxSlippage`: 滑点容忍度（0-1，例如 0.05 = 5%）
- `orderType`: 订单类型（'FOK' 或 'FAK'）

### 安全提示

⚠️ **重要提示**：

- 默认启用了 `dryRun: true`（测试模式），不会执行真实交易
- 只有在完全理解风险并确认无误后，才设置 `dryRun: false`
- 请妥善保管您的私钥，不要提交到版本控制系统
- 建议从小额开始，逐步增加

## 🔄 更新项目

### 方法一：手动更新

```bash
cd /opt/polybot

# 停止 PM2 进程
pm2 stop polybot

# 拉取最新代码
git pull origin main

# 更新依赖（如果有变化）
npm install

# 重启
pm2 restart polybot
```

### 方法二：使用更新脚本

如果有 `auto-update.sh` 脚本：

```bash
cd /opt/polybot
bash auto-update.sh
```

## 🛠️ 故障排除

### 问题 1: 无法连接 GitHub

**解决方案：**

```bash
# 检查网络连接
ping github.com

# 如果无法访问，可能需要配置代理或使用镜像
```

### 问题 2: npm install 失败

**解决方案：**

```bash
# 清除 npm 缓存
npm cache clean --force

# 删除 node_modules 和 package-lock.json
rm -rf node_modules package-lock.json

# 重新安装
npm install
```

### 问题 3: PM2 启动失败

**解决方案：**

```bash
# 查看详细错误
pm2 logs polybot --err

# 检查 Node.js 版本
node --version

# 尝试直接运行
cd /opt/polybot
node index.js
```

### 问题 4: 权限问题

**解决方案：**

```bash
# 检查文件权限
ls -l /opt/polybot

# 修复权限
chown -R $(whoami):$(whoami) /opt/polybot
chmod +x /opt/polybot/*.sh
```

### 问题 5: 诊断工具

使用内置诊断工具：

```bash
cd /opt/polybot
npm run diagnose
# 或
node diagnose-failures.js
```

## 📚 相关文档

- [使用指南](./USAGE.md)
- [部署指南](./DEPLOY.md)
- [故障排除](./TROUBLESHOOTING.md)
- [README](./README.md)

## 🔗 相关链接

- [GitHub 仓库](https://github.com/119969788/polybot)
- [poly-sdk 文档](https://github.com/cyl19970726/poly-sdk)
- [Polymarket 官网](https://polymarket.com/)

## ✅ 安装完成检查清单

- [ ] Node.js 已安装（版本 >= 18）
- [ ] npm 已安装
- [ ] PM2 已安装（可选但推荐）
- [ ] 项目已克隆到 `/opt/polybot`
- [ ] 依赖已安装（`npm install`）
- [ ] 配置文件已创建（`config.js`）
- [ ] 已填入私钥和配置
- [ ] 测试运行成功（`npm start`）
- [ ] PM2 进程运行正常（`pm2 list`）
- [ ] 日志正常（`pm2 logs polybot`）

---

**安装完成后，记得先在测试模式（`dryRun: true`）下运行，确认一切正常后再切换到真实交易模式！**
