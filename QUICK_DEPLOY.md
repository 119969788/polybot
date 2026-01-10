# ⚡ 快速部署指南（阿里云）

## 一键安装（推荐）

在阿里云服务器上执行以下命令：

```bash
# 下载并运行安装脚本
curl -fsSL https://raw.githubusercontent.com/119969788/polybot/main/install.sh | bash

# 或者先下载再执行
wget https://raw.githubusercontent.com/119969788/polybot/main/install.sh
chmod +x install.sh
sudo bash install.sh
```

## 手动安装（5 分钟）

### 1. 连接到服务器

```bash
ssh root@your_server_ip
```

### 2. 安装 Node.js 和 Git

**Ubuntu/Debian:**
```bash
apt update
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs git
```

**CentOS/RHEL:**
```bash
yum update -y
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git
```

### 3. 克隆项目

```bash
cd /opt
git clone https://github.com/119969788/polybot.git
cd polybot
```

### 4. 安装依赖

```bash
# 使用淘宝镜像加速（推荐）
npm config set registry https://registry.npmmirror.com
npm install
```

### 5. 配置项目

```bash
cp config.example.js config.js
nano config.js  # 编辑配置文件，设置私钥等
```

### 6. 安装 PM2 并启动

```bash
# 安装 PM2
npm install -g pm2

# 启动应用
pm2 start index.js --name polybot

# 查看状态
pm2 status

# 查看日志
pm2 logs polybot

# 设置开机自启
pm2 save
pm2 startup  # 执行显示的命令
```

## 常用命令

```bash
# 查看运行状态
pm2 status

# 查看日志
pm2 logs polybot
pm2 logs polybot --lines 100  # 最后 100 行

# 重启应用
pm2 restart polybot

# 停止应用
pm2 stop polybot

# 实时监控
pm2 monit
```

## 更新代码

```bash
cd /opt/polybot
git pull
npm install  # 如果有新依赖
pm2 restart polybot
```

## 故障排除

### 问题：npm install 很慢

```bash
# 使用国内镜像
npm config set registry https://registry.npmmirror.com
```

### 问题：连接 GitHub 失败

```bash
# 使用代理（如果有）
git config --global http.proxy http://127.0.0.1:7890
```

### 问题：PM2 启动失败

```bash
# 查看详细错误
pm2 logs polybot --err
```

### 问题：端口被占用

```bash
# 检查端口占用（通常不需要）
netstat -tulpn | grep :端口号
```

## 安全提示

1. ✅ 使用环境变量存储私钥：`export POLYMARKET_PRIVATE_KEY=0x...`
2. ✅ 设置文件权限：`chmod 600 config.js`
3. ✅ 定期更新代码和依赖
4. ✅ 查看日志监控运行状态

## 完整文档

查看 [DEPLOY.md](DEPLOY.md) 获取详细的部署说明和故障排除指南。

---

**部署完成后，您的 PolyBot 将在服务器上 7x24 小时运行！** 🚀
