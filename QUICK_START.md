# 🚀 快速推送指南

## 步骤 1：在 GitHub 上创建仓库

1. 访问：https://github.com/new
2. 填写仓库信息：
   - **Repository name**: `polybot`
   - **Description**: `PolyBot - Polymarket 钱包跟单机器人`
   - 选择 **Public** 或 **Private**
   - ⚠️ **不要勾选** "Initialize this repository with a README"（我们已有代码）
   - ⚠️ **不要**添加 .gitignore 或 license（我们已有）
3. 点击 **"Create repository"** 按钮

## 步骤 2：推送代码

仓库创建后，运行以下命令：

```bash
git push -u origin main
```

## ✅ 已完成

- ✅ Git 仓库已初始化
- ✅ 所有文件已提交
- ✅ 远程仓库已配置：`https://github.com/119969788/polybot.git`
- ✅ 分支已重命名为 `main`

## 🔗 仓库地址

创建后，您的仓库将在：
https://github.com/119969788/polybot

---

**提示**：如果推送时遇到认证问题，请使用以下方式之一：

### 方式 1：使用 Personal Access Token（推荐）

1. 访问：https://github.com/settings/tokens
2. 生成新 token（选择 `repo` 权限）
3. 推送时使用 token 作为密码

### 方式 2：使用 SSH（需要先配置 SSH 密钥）

```bash
git remote set-url origin git@github.com:119969788/polybot.git
git push -u origin main
```
