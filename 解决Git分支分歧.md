# 🔧 解决 Git 分支分歧问题

## 问题描述

服务器上的分支和远程分支有分歧，需要指定合并策略。

## 解决方案

### 方法一：使用 merge 策略（推荐）

```bash
# 在服务器上执行
cd /opt/polybot
git config pull.rebase false
git pull origin main
```

### 方法二：使用 rebase 策略

```bash
cd /opt/polybot
git config pull.rebase true
git pull origin main
```

### 方法三：一次性指定（不修改配置）

```bash
cd /opt/polybot
git pull origin main --no-rebase  # 使用 merge
# 或
git pull origin main --rebase      # 使用 rebase
```

### 方法四：强制拉取（如果确定要覆盖本地更改）

```bash
cd /opt/polybot
# 先备份本地更改（如果有）
git stash

# 拉取远程代码
git fetch origin
git reset --hard origin/main

# 如果需要恢复本地更改
git stash pop
```

## 完整步骤（推荐）

```bash
# SSH 连接到服务器
ssh user@your-server-ip

# 进入项目目录
cd /opt/polybot

# 设置合并策略（使用 merge）
git config pull.rebase false

# 拉取最新代码
git pull origin main

# 验证文件存在
ls -lh diagnose-failures.js

# 运行诊断工具
node diagnose-failures.js
```

## 如果本地有未提交的更改

```bash
cd /opt/polybot

# 查看状态
git status

# 如果有未提交的更改，先暂存
git stash

# 拉取代码
git config pull.rebase false
git pull origin main

# 恢复本地更改（如果需要）
git stash pop
```

## 一行命令（快速解决）

```bash
cd /opt/polybot && git config pull.rebase false && git pull origin main && node diagnose-failures.js
```
