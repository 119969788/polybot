# 🚀 阿里云服务器部署指南

## 前置要求

- 阿里云 ECS 实例（Ubuntu 20.04/22.04 或 CentOS 7/8）
- 已配置 SSH 访问
- root 或具有 sudo 权限的用户

## 步骤 1：连接到服务器

```bash
# 使用 SSH 连接到服务器
ssh root@your_server_ip
# 或者使用密钥
ssh -i your_key.pem root@your_server_ip
```

## 步骤 2：更新系统包

### Ubuntu/Debian

```bash
apt update && apt upgrade -y
```

### CentOS/RHEL

```bash
yum update -y
```

## 步骤 3：安装 Node.js 和 npm

### 方法一：使用 NodeSource 仓库（推荐）

#### Ubuntu/Debian

```bash
# 安装 Node.js 18.x LTS
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# 验证安装
node --version
npm --version
```

#### CentOS/RHEL

```bash
# 安装 Node.js 18.x LTS
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# 验证安装
node --version
npm --version
```

### 方法二：使用 NVM（Node Version Manager）

```bash
# 安装 NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# 重新加载 shell 配置
source ~/.bashrc

# 安装 Node.js
nvm install 18
nvm use 18
nvm alias default 18

# 验证安装
node --version
npm --version
```

## 步骤 4：安装 Git（如果还没有）

### Ubuntu/Debian

```bash
apt install -y git
```

### CentOS/RHEL

```bash
yum install -y git
```

## 步骤 5：克隆项目

```bash
# 创建项目目录
mkdir -p /opt/polybot
cd /opt/polybot

# 克隆项目（替换为您的实际仓库地址）
git clone https://github.com/119969788/polybot.git .

# 或者如果您使用 SSH
# git clone git@github.com:119969788/polybot.git .
```

## 步骤 6：安装项目依赖

```bash
cd /opt/polybot
npm install
```

如果遇到网络问题，可以使用淘宝镜像：

```bash
# 设置 npm 镜像
npm config set registry https://registry.npmmirror.com

# 安装依赖
npm install

# 可选：恢复官方源
# npm config set registry https://registry.npmjs.org
```

## 步骤 7：配置项目

```bash
# 复制配置示例文件
cp config.example.js config.js

# 编辑配置文件
nano config.js
# 或使用 vi
# vi config.js
```

在配置文件中设置：
- `sdk.privateKey`: 您的私钥（从环境变量读取更安全）
- `targetWallets`: 要跟单的钱包地址
- `followSettings`: 跟单参数

### 更安全的方式：使用环境变量

```bash
# 创建 .env 文件
nano /opt/polybot/.env
```

添加以下内容（不要提交到 Git）：

```bash
POLYMARKET_PRIVATE_KEY=0x您的私钥
```

然后修改 `config.js` 从环境变量读取：

```javascript
privateKey: process.env.POLYMARKET_PRIVATE_KEY || '',
```

## 步骤 8：测试运行

```bash
# 测试运行（前台模式）
cd /opt/polybot
npm start
```

如果看到正常运行日志，按 `Ctrl+C` 停止。

## 步骤 9：安装 PM2（进程管理器，推荐）

PM2 可以让应用在后台运行，并自动重启。

```bash
# 全局安装 PM2
npm install -g pm2

# 验证安装
pm2 --version
```

## 步骤 10：使用 PM2 启动项目

```bash
cd /opt/polybot

# 启动项目
pm2 start index.js --name polybot

# 查看运行状态
pm2 status

# 查看日志
pm2 logs polybot

# 查看详细信息
pm2 info polybot
```

### PM2 常用命令

```bash
# 查看所有应用
pm2 list

# 查看日志
pm2 logs polybot
pm2 logs polybot --lines 100  # 查看最后 100 行

# 重启应用
pm2 restart polybot

# 停止应用
pm2 stop polybot

# 删除应用
pm2 delete polybot

# 查看实时监控
pm2 monit

# 保存当前进程列表（开机自启）
pm2 save

# 设置开机自启（需要先执行 pm2 save）
pm2 startup
# 然后执行显示的命令
```

## 步骤 11：配置开机自启

```bash
# 保存当前 PM2 进程列表
pm2 save

# 生成开机自启脚本
pm2 startup

# 执行上一步显示的命令（类似这样）：
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u root --hp /root
```

## 步骤 12：配置防火墙（如果需要）

### 如果使用阿里云安全组

在阿里云控制台配置安全组规则，通常不需要开放端口（应用只对外连接）。

### 如果使用 UFW（Ubuntu）

```bash
# 通常不需要开放端口，但如果需要
# ufw allow 22/tcp   # SSH
# ufw enable
```

### 如果使用 firewalld（CentOS）

```bash
# 通常不需要开放端口，但如果需要
# firewall-cmd --permanent --add-service=ssh
# firewall-cmd --reload
```

## 步骤 13：监控和维护

### 查看日志

```bash
# PM2 日志
pm2 logs polybot

# 查看系统日志
journalctl -u pm2-root -f  # systemd 日志
```

### 定期更新

```bash
cd /opt/polybot

# 拉取最新代码
git pull

# 重新安装依赖（如果有新依赖）
npm install

# 重启应用
pm2 restart polybot
```

### 备份配置

```bash
# 备份配置文件（重要！）
cp /opt/polybot/config.js /opt/polybot/config.js.backup
```

## 故障排除

### 问题 1：Node.js 版本过低

```bash
# 检查 Node.js 版本
node --version

# 应该 >= 16.x，如果版本太低，重新安装（见步骤 3）
```

### 问题 2：npm install 失败

```bash
# 清除 npm 缓存
npm cache clean --force

# 删除 node_modules 重新安装
rm -rf node_modules package-lock.json
npm install
```

### 问题 3：PM2 启动失败

```bash
# 查看详细错误
pm2 logs polybot --err

# 检查配置文件
node -c index.js  # 检查语法错误
```

### 问题 4：内存不足

```bash
# 查看内存使用
free -h

# 如果内存不足，可以考虑：
# 1. 升级服务器配置
# 2. 使用 swap 空间
# 3. 优化 Node.js 内存限制
```

### 问题 5：网络连接问题

```bash
# 测试网络连接
ping github.com
curl -I https://github.com

# 如果在中国大陆，可能需要配置代理
# 在 config.js 或环境变量中配置代理
```

## 安全建议

1. **保护私钥**
   - 使用环境变量存储私钥
   - 不要将私钥提交到 Git
   - 定期更换私钥

2. **文件权限**
   ```bash
   # 设置合适的文件权限
   chmod 600 /opt/polybot/config.js
   chmod 600 /opt/polybot/.env
   ```

3. **定期更新**
   - 定期更新系统和依赖包
   - 关注安全公告

4. **日志管理**
   ```bash
   # 配置日志轮转
   pm2 install pm2-logrotate
   pm2 set pm2-logrotate:max_size 10M
   pm2 set pm2-logrotate:retain 7
   ```

## 性能优化

### 使用 PM2 Cluster 模式（多进程）

```bash
# 启动多个实例（充分利用多核 CPU）
pm2 start index.js -i max --name polybot

# -i max 表示使用所有 CPU 核心
```

### 监控资源使用

```bash
# 安装监控模块
pm2 install pm2-server-monit

# 查看资源使用
pm2 monit
```

## 完整安装脚本

您也可以创建一个自动化安装脚本：

```bash
#!/bin/bash
# install.sh

# 更新系统
apt update && apt upgrade -y

# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs git

# 安装 PM2
npm install -g pm2

# 克隆项目
mkdir -p /opt/polybot
cd /opt/polybot
git clone https://github.com/119969788/polybot.git .

# 安装依赖
npm config set registry https://registry.npmmirror.com
npm install

# 复制配置文件
cp config.example.js config.js

echo "安装完成！请编辑 /opt/polybot/config.js 配置文件，然后运行："
echo "cd /opt/polybot && pm2 start index.js --name polybot"
```

保存为 `install.sh`，然后执行：

```bash
chmod +x install.sh
sudo ./install.sh
```

## 验证部署

部署完成后，检查：

1. ✅ PM2 进程运行正常：`pm2 status`
2. ✅ 日志正常输出：`pm2 logs polybot`
3. ✅ 没有错误：查看日志中的错误信息
4. ✅ 应用正常连接：查看日志中的连接信息

---

**祝部署顺利！** 🚀
