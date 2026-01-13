# 🔧 解决 .env 文件权限问题

## 问题描述

遇到错误：`Error writing .env: Permission denied`

这通常是因为文件权限或所有者不正确导致的。

## 快速解决方案

### 方法一：修复文件权限（推荐）

```bash
cd /opt/poly-copy-trading

# 修复权限（仅用户可读写）
chmod 600 .env

# 如果文件不存在，先创建
if [ ! -f .env ]; then
    cp env.example.txt .env
    chmod 600 .env
fi
```

### 方法二：修复文件所有者

如果文件所有者不是当前用户：

```bash
cd /opt/poly-copy-trading

# 查看文件所有者和权限
ls -l .env

# 修改文件所有者（替换 $USER 为你的用户名）
sudo chown $USER:$USER .env

# 设置权限
chmod 600 .env
```

### 方法三：删除并重新创建

```bash
cd /opt/poly-copy-trading

# 删除现有文件
rm -f .env

# 重新创建
cp env.example.txt .env
chmod 600 .env

# 编辑文件
nano .env
```

### 方法四：使用 sudo（如果必须）

```bash
cd /opt/poly-copy-trading

# 使用 sudo 创建或编辑
sudo nano .env

# 然后修改所有者
sudo chown $USER:$USER .env
sudo chmod 600 .env
```

## 完整修复步骤

### 步骤 1: 检查当前状态

```bash
cd /opt/poly-copy-trading

# 查看文件权限
ls -l .env

# 查看当前用户
whoami

# 查看目录权限
ls -ld .
```

### 步骤 2: 修复权限

```bash
# 如果文件存在
chmod 600 .env

# 如果文件不存在
if [ ! -f .env ]; then
    cp env.example.txt .env
    chmod 600 .env
fi
```

### 步骤 3: 修复所有者（如果需要）

```bash
# 查看文件所有者
stat .env  # 或 ls -l .env

# 修改所有者（替换 username 为你的用户名）
sudo chown username:username .env

# 或者使用当前用户
sudo chown $(whoami):$(whoami) .env
```

### 步骤 4: 修复目录权限（如果需要）

```bash
# 确保目录权限正确
chmod 755 /opt/poly-copy-trading

# 如果目录所有者不对
sudo chown -R $(whoami):$(whoami) /opt/poly-copy-trading
```

### 步骤 5: 验证权限

```bash
# 测试写入
echo "# Test" >> .env
sed -i '/^# Test$/d' .env

# 查看权限
ls -l .env
# 应该显示: -rw------- (600)
```

## 使用修复脚本

如果已上传修复脚本：

```bash
# 上传脚本（在本地执行）
scp 修复env权限问题.sh user@server:/tmp/

# 在服务器上执行
ssh user@server
bash /tmp/修复env权限问题.sh /opt/poly-copy-trading
```

## 一行命令修复

```bash
cd /opt/poly-copy-trading && \
([ -f .env ] && chmod 600 .env || (cp env.example.txt .env && chmod 600 .env)) && \
sudo chown $(whoami):$(whoami) .env 2>/dev/null && \
echo "✅ 权限修复完成"
```

## 权限说明

- **600**: 仅用户可读写（推荐）
  - `rw-------` (用户: 读写, 组: 无, 其他: 无)
  - 这是最安全的权限设置

- **644**: 用户可读写，其他只读
  - `rw-r--r--` (不推荐，因为 .env 包含敏感信息)

- **777**: 所有人可读写（❌ 绝对不要使用）
  - 安全风险极高

## 常见问题

### Q1: chmod: cannot access '.env': No such file or directory

**解决方案**:
```bash
# 文件不存在，先创建
cp env.example.txt .env
chmod 600 .env
```

### Q2: chmod: changing permissions of '.env': Operation not permitted

**解决方案**:
```bash
# 使用 sudo
sudo chmod 600 .env
sudo chown $(whoami):$(whoami) .env
```

### Q3: 文件所有者是 root

**解决方案**:
```bash
# 查看所有者
ls -l .env

# 修改所有者
sudo chown $(whoami):$(whoami) .env
chmod 600 .env
```

### Q4: 目录权限问题

**解决方案**:
```bash
# 检查目录权限
ls -ld /opt/poly-copy-trading

# 修复目录权限
sudo chmod 755 /opt/poly-copy-trading
sudo chown -R $(whoami):$(whoami) /opt/poly-copy-trading
```

## 验证修复

修复后验证：

```bash
cd /opt/poly-copy-trading

# 1. 查看权限（应该显示 -rw-------）
ls -l .env

# 2. 测试写入
echo "POLYMARKET_PRIVATE_KEY=test" >> .env
tail -1 .env  # 应该看到新添加的内容

# 3. 删除测试行
sed -i '$d' .env

# 4. 尝试编辑
nano .env  # 应该可以正常编辑和保存
```

## 最佳实践

1. ✅ 使用 `chmod 600 .env` 设置权限
2. ✅ 确保文件所有者是运行程序的用户
3. ✅ 不要在 .env 文件上使用 777 权限
4. ✅ 定期检查文件权限
5. ✅ 使用修复脚本自动化处理

## 预防措施

在创建 .env 文件时：

```bash
# 正确的方式
cp env.example.txt .env
chmod 600 .env
chown $(whoami):$(whoami) .env

# 使用脚本
cat > .env << 'EOF'
POLYMARKET_PRIVATE_KEY=your_key_here
DRY_RUN=true
EOF
chmod 600 .env
```

---

**修复后，应该可以正常编辑和保存 .env 文件了！**
