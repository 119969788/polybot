# GitHub 上传指南

## ✅ 已完成

- ✅ Git 仓库已初始化
- ✅ 所有文件已添加
- ✅ 初始提交已创建

## 📋 下一步：上传到 GitHub

### 方法一：使用 GitHub CLI（推荐）

如果您已安装 GitHub CLI：

```bash
# 1. 登录 GitHub
gh auth login

# 2. 创建仓库并推送
gh repo create polybot --public --source=. --remote=origin --push
```

### 方法二：手动创建仓库（标准方法）

#### 1. 在 GitHub 上创建新仓库

1. 访问 https://github.com/new
2. 仓库名称：`polybot`（或您喜欢的名称）
3. 描述：`PolyBot - Polymarket 钱包跟单机器人`
4. 选择 **Public** 或 **Private**
5. ⚠️ **不要**勾选 "Initialize this repository with a README"（因为我们已有代码）
6. 点击 "Create repository"

#### 2. 添加远程仓库并推送

复制 GitHub 提供的命令（类似下面的，但使用您的实际仓库 URL）：

```bash
# 添加远程仓库（请替换为您的实际仓库 URL）
git remote add origin https://github.com/YOUR_USERNAME/polybot.git

# 或者使用 SSH（如果您配置了 SSH 密钥）
# git remote add origin git@github.com:YOUR_USERNAME/polybot.git

# 推送代码到 GitHub
git branch -M main
git push -u origin main
```

如果您的默认分支是 `master` 而不是 `main`：

```bash
# 方式1：推送 master 分支
git push -u origin master

# 方式2：重命名为 main 并推送（推荐，符合 GitHub 标准）
git branch -M main
git push -u origin main
```

### 方法三：使用 GitHub Desktop

1. 安装 [GitHub Desktop](https://desktop.github.com/)
2. 打开 GitHub Desktop
3. File > Add Local Repository > 选择 `J:\polybot`
4. Publish repository > 填写仓库信息 > Publish

## 🔧 配置 Git 用户信息（可选）

如果您想修改 Git 提交时显示的用户信息：

```bash
# 全局配置（所有仓库）
git config --global user.name "您的名字"
git config --global user.email "your.email@example.com"

# 仅当前仓库
git config user.name "您的名字"
git config user.email "your.email@example.com"
```

查看当前配置：

```bash
git config user.name
git config user.email
```

## ✅ 验证

推送成功后，访问您的 GitHub 仓库页面，应该能看到所有文件。

## 📝 后续更新

推送代码后，您可以使用以下命令更新 GitHub：

```bash
# 添加更改的文件
git add .

# 创建提交
git commit -m "描述您的更改"

# 推送到 GitHub
git push
```

## ⚠️ 注意事项

1. **私钥安全**：
   - 确认 `.gitignore` 已正确配置（已包含 `config.js`）
   - 永远不要提交包含私钥的 `config.js` 文件
   - 使用 `config.example.js` 作为配置模板

2. **环境变量**：
   - `.env` 文件已在 `.gitignore` 中，不会被提交
   - 如果需要，可以创建一个 `.env.example` 文件作为模板

3. **敏感信息检查**：
   推送前确认没有包含任何敏感信息：
   ```bash
   git log --all --full-history -- source/
   git log --all --full-history -- config.js  # 应该找不到这个文件
   ```

## 🎉 完成！

推送成功后，您的项目就已经在 GitHub 上了！
