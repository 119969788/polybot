# 🚀 在阿里云服务器上安装 poly-copy-trading

## 项目信息

- **仓库地址**: https://github.com/119969788/poly-copy-trading
- **项目类型**: TypeScript 项目
- **包管理器**: pnpm
- **运行环境**: Node.js 18+

## 快速安装（推荐）

### 方法一：使用安装脚本（最简单）

```bash
# 1. 下载安装脚本
curl -O https://raw.githubusercontent.com/119969788/poly-copy-trading/main/install.sh
# 或者使用本地脚本（如果已上传）
# scp 安装poly-copy-trading.sh user@server:/tmp/

# 2. 运行安装脚本
bash 安装poly-copy-trading.sh

# 或者直接一行命令
bash <(curl -sSL https://raw.githubusercontent.com/119969788/poly-copy-trading/main/install.sh)
```

### 方法二：手动安装

```bash
# 1. 更新系统
yum update -y  # CentOS/RHEL
# 或
apt-get update && apt-get upgrade -y  # Ubuntu/Debian

# 2. 安装 Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -  # CentOS/RHEL
yum install -y nodejs
# 或
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -  # Ubuntu/Debian
apt-get install -y nodejs

# 3. 安装 pnpm
npm install -g pnpm

# 4. 安装 PM2（推荐）
npm install -g pm2

# 5. 克隆项目
cd /opt
git clone https://github.com/119969788/poly-copy-trading.git
cd poly-copy-trading

# 6. 安装依赖
pnpm install

# 7. 配置环境变量
cp env.example.txt .env
nano .env
# 填入：POLYMARKET_PRIVATE_KEY=你的私钥
```

## 详细安装步骤

### 步骤 1: 连接到服务器

```bash
ssh root@your-server-ip
# 或
ssh user@your-server-ip
```

### 步骤 2: 安装依赖

项目需要：
- Node.js 18+
- pnpm
- Git

**安装 Node.js 18**:

```bash
# CentOS/RHEL
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 验证安装
node -v  # 应该显示 v18.x.x
npm -v
```

**安装 pnpm**:

```bash
npm install -g pnpm
pnpm -v
```

**安装 PM2（推荐用于生产环境）**:

```bash
npm install -g pm2
pm2 -v
```

### 步骤 3: 克隆项目

```bash
# 创建项目目录
mkdir -p /opt
cd /opt

# 克隆仓库
git clone https://github.com/119969788/poly-copy-trading.git
cd poly-copy-trading

# 验证文件
ls -la
```

### 步骤 4: 安装项目依赖

```bash
# 进入项目目录
cd /opt/poly-copy-trading

# 安装依赖
pnpm install
```

### 步骤 5: 配置环境变量

```bash
# 复制示例文件
cp env.example.txt .env

# 编辑配置文件
nano .env
```

**必需的配置**:

```env
# 必需：Polymarket 私钥
POLYMARKET_PRIVATE_KEY=0x你的私钥

# 可选：指定要跟随的钱包地址（用逗号分隔）
# 如果不设置，则跟随排行榜前 50 名
# TARGET_ADDRESSES=0x1234...,0x5678...

# 可选：是否启用模拟模式（默认 true，推荐先测试）
DRY_RUN=true
```

**保存文件**: 按 `Ctrl+X`，然后 `Y`，最后 `Enter`

### 步骤 6: 运行项目

**测试模式（推荐首次使用）**:

```bash
cd /opt/poly-copy-trading
pnpm start
```

**开发模式（自动重载）**:

```bash
pnpm dev
```

**使用 PM2 后台运行（生产环境）**:

```bash
# 启动
pm2 start pnpm --name poly-copy-trading -- start

# 查看状态
pm2 status

# 查看日志
pm2 logs poly-copy-trading

# 保存配置（开机自启）
pm2 save
pm2 startup
```

## 配置说明

### 环境变量配置

`.env` 文件配置项：

| 配置项 | 必需 | 说明 | 示例 |
|--------|------|------|------|
| `POLYMARKET_PRIVATE_KEY` | ✅ | Polymarket 私钥 | `0x1234...` |
| `TARGET_ADDRESSES` | ❌ | 目标钱包地址（逗号分隔） | `0x1234...,0x5678...` |
| `DRY_RUN` | ❌ | 模拟模式（默认 true） | `true` 或 `false` |

### 风险控制参数

项目中的风险控制参数（在 `src/index.ts` 中）：

- **sizeScale**: 0.1（跟随 10% 规模）
- **maxSizePerTrade**: 10 USDC（最大单笔交易金额）
- **maxSlippage**: 0.03（最大滑点 3%）
- **orderType**: FOK（Fill or Kill）
- **minTradeSize**: 5 USDC（最小交易金额）

## 常见问题

### Q1: pnpm 命令不存在

```bash
# 安装 pnpm
npm install -g pnpm

# 或使用 npm
# 但项目推荐使用 pnpm
```

### Q2: TypeScript 编译错误

项目使用 `tsx` 直接运行 TypeScript，无需编译。如果遇到问题：

```bash
# 检查 tsx 是否安装
pnpm list tsx

# 重新安装依赖
pnpm install
```

### Q3: 权限问题

```bash
# 确保有权限访问目录
chmod -R 755 /opt/poly-copy-trading

# 如果使用非 root 用户
sudo chown -R $USER:$USER /opt/poly-copy-trading
```

### Q4: PM2 无法启动

```bash
# 检查 PM2 是否正确安装
which pm2

# 重新安装 PM2
npm install -g pm2

# 使用完整路径
pm2 start /usr/bin/pnpm --name poly-copy-trading -- start
```

### Q5: 端口被占用

```bash
# 检查端口使用情况
netstat -tulpn | grep :端口号

# 或使用
lsof -i :端口号
```

## 管理命令

### PM2 常用命令

```bash
# 启动
pm2 start pnpm --name poly-copy-trading -- start

# 停止
pm2 stop poly-copy-trading

# 重启
pm2 restart poly-copy-trading

# 查看状态
pm2 status

# 查看日志
pm2 logs poly-copy-trading

# 查看实时日志
pm2 logs poly-copy-trading --lines 100

# 删除进程
pm2 delete poly-copy-trading

# 保存配置
pm2 save

# 设置开机自启
pm2 startup
```

### 更新项目

```bash
cd /opt/poly-copy-trading

# 停止服务（如果使用 PM2）
pm2 stop poly-copy-trading

# 拉取最新代码
git pull origin main

# 更新依赖
pnpm install

# 重启服务
pm2 restart poly-copy-trading
```

## 安全建议

⚠️ **重要安全提示**：

1. ✅ **私钥安全**: 确保 `.env` 文件权限正确
   ```bash
   chmod 600 /opt/poly-copy-trading/.env
   ```

2. ✅ **测试优先**: 始终先在 `DRY_RUN=true` 模式下测试

3. ✅ **防火墙配置**: 确保服务器防火墙配置正确

4. ✅ **定期备份**: 定期备份配置文件

5. ✅ **监控日志**: 定期检查运行日志

## 验证安装

安装完成后，验证：

```bash
# 1. 检查 Node.js
node -v  # 应该 >= v18.0.0

# 2. 检查 pnpm
pnpm -v

# 3. 检查项目文件
cd /opt/poly-copy-trading
ls -la

# 4. 检查依赖
pnpm list

# 5. 测试运行（测试模式）
DRY_RUN=true pnpm start
```

## 下一步

1. ✅ 配置 `.env` 文件
2. ✅ 在测试模式下运行
3. ✅ 观察日志和统计信息
4. ✅ 确认一切正常后，考虑切换到实盘模式

---

**参考**: [GitHub 仓库](https://github.com/119969788/poly-copy-trading)
