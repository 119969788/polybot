# 🔧 解决 PM2 进程不存在问题

## 问题描述

```
[PM2][ERROR] Process or Namespace polybot not found
```

说明：PM2 中没有名为 "polybot" 的进程。

## 解决方法

### 方法一：检查 PM2 进程列表

```bash
# 查看所有 PM2 进程
pm2 list

# 查看进程状态
pm2 status
```

如果列表为空，说明程序没有使用 PM2 运行。

### 方法二：使用 PM2 启动程序

```bash
cd /opt/polybot  # 或你的项目目录

# 启动程序
pm2 start index.js --name polybot

# 查看状态
pm2 list

# 查看日志
pm2 logs polybot

# 保存进程列表（开机自启）
pm2 save

# 设置开机自启（执行输出的命令）
pm2 startup
```

### 方法三：检查是否直接运行

如果程序不是使用 PM2 运行的，可能正在直接运行：

```bash
# 查看 Node.js 进程
ps aux | grep "node index.js"

# 或
ps aux | grep node

# 查看进程树
pstree -p | grep node
```

如果找到进程，说明程序正在直接运行（不是 PM2）。

### 方法四：直接运行（不使用 PM2）

如果不想使用 PM2，可以直接运行：

```bash
cd /opt/polybot

# 直接运行
node index.js

# 或使用 npm
npm start

# 后台运行（使用 nohup）
nohup node index.js > output.log 2>&1 &

# 查看后台进程
ps aux | grep "node index.js"
```

### 方法五：使用 npm 脚本（如果已配置）

```bash
cd /opt/polybot

# 查看可用的脚本
npm run

# 如果 package.json 中有 pm2:start 脚本
npm run pm2:start

# 查看日志
npm run pm2:logs
```

## 完整启动流程

### 首次使用 PM2 启动

```bash
cd /opt/polybot

# 1. 确保依赖已安装
npm install

# 2. 启动程序
pm2 start index.js --name polybot

# 3. 查看状态
pm2 list

# 4. 查看日志
pm2 logs polybot

# 5. 保存进程列表
pm2 save

# 6. 设置开机自启（执行输出的命令）
pm2 startup
# 然后执行输出的命令（类似：sudo env PATH=... pm2 startup ...）
```

## 常用 PM2 命令

```bash
# 查看所有进程
pm2 list

# 查看进程详细信息
pm2 show polybot

# 启动进程
pm2 start polybot

# 停止进程
pm2 stop polybot

# 重启进程
pm2 restart polybot

# 删除进程
pm2 delete polybot

# 查看日志
pm2 logs polybot

# 查看实时监控
pm2 monit

# 查看统计
pm2 stats
```

## 检查程序运行状态

### 检查是否在运行

```bash
# 方法 1: 使用 PM2
pm2 list

# 方法 2: 查看进程
ps aux | grep "node index.js"

# 方法 3: 查看端口（如果有）
netstat -tulpn | grep node
```

### 如果程序正在运行

如果程序正在运行（但不是 PM2），你可以：

1. **继续使用当前运行方式**（如果稳定）
2. **停止当前进程，改用 PM2**：
   ```bash
   # 找到进程 ID
   ps aux | grep "node index.js"
   
   # 停止进程
   kill <PID>
   
   # 使用 PM2 启动
   pm2 start index.js --name polybot
   ```

## 推荐方案

### 方案 1: 使用 PM2（推荐，生产环境）

优点：
- 自动重启崩溃的程序
- 日志管理
- 监控功能
- 开机自启

```bash
cd /opt/polybot
pm2 start index.js --name polybot
pm2 save
pm2 startup
```

### 方案 2: 使用 nohup（简单，临时）

优点：
- 简单快速
- 不需要额外安装

```bash
cd /opt/polybot
nohup node index.js > output.log 2>&1 &
```

### 方案 3: 使用 systemd（系统服务）

优点：
- 系统级服务管理
- 更稳定

（需要创建 systemd service 文件）

## 故障排除

### 问题 1: PM2 未安装

```bash
# 安装 PM2
npm install -g pm2

# 验证安装
pm2 --version
```

### 问题 2: 进程名冲突

```bash
# 查看所有进程
pm2 list

# 如果名称冲突，使用其他名称
pm2 start index.js --name polybot-copy

# 或删除旧进程
pm2 delete polybot
pm2 start index.js --name polybot
```

### 问题 3: 程序启动失败

```bash
# 查看错误日志
pm2 logs polybot --err

# 直接运行查看错误
cd /opt/polybot
node index.js
```

## 快速检查命令

```bash
# 1. 检查 PM2 进程
pm2 list

# 2. 检查直接运行的进程
ps aux | grep "node index.js"

# 3. 检查 PM2 是否安装
pm2 --version

# 4. 检查程序目录
ls -la /opt/polybot

# 5. 检查配置文件
cat /opt/polybot/config.js | head -20
```
