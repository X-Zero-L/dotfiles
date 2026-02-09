# setup-gemini.sh

安装 [Gemini CLI](https://github.com/google-gemini/gemini-cli)，可选配置 API 凭据。别名：`gm`。

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| Gemini CLI | `npm install -g @google/gemini-cli` | Google 编码代理 CLI |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/3 | 通过 npm 全局安装 Gemini CLI（`gemini` 命令存在则跳过） |
| 2/3 | 如提供 API 密钥：写入 `~/.gemini/.env`（API URL、密钥、模型） |
| 3/3 | 在 `~/.bashrc` 和 `~/.zshrc` 中添加 `alias gm='gemini -y'` |

### 配置写入

使用全文字符串比较 — 构建期望的 `.env` 内容，通过 `cat` 与现有文件比较，仅在不同时写入。足够简单，无需使用 Node.js。

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.gemini/.env` | API 配置（权限 `0600`） |
| `~/.bashrc` | 添加别名 `gm` |
| `~/.zshrc` | 添加别名 `gm` |

### .env 结构

```env
GOOGLE_GEMINI_BASE_URL=https://your-api-url
GEMINI_API_KEY=your-key
GEMINI_MODEL=gemini-3-pro-preview
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GEMINI_API_URL` | _（空）_ | API 基础地址（留空则只安装不配置） |
| `GEMINI_API_KEY` | _（空）_ | API 密钥（留空则只安装不配置） |
| `GEMINI_MODEL` | `gemini-3-pro-preview` | 模型名称 |
| `GEMINI_NPM_MIRROR` | _（空）_ | npm 镜像源。设置 `GH_PROXY` 时自动启用。 |

## 重复运行行为

- 安装：`gemini` 命令存在则跳过。
- 配置：`.env` 全文比较。仅在内容不同时写入。
- 别名：rc 文件中已存在则跳过。

## 依赖

- Node.js（先运行 `setup-node.sh`）。

## 安装后

```bash
source ~/.zshrc    # 加载别名
gm                 # 启动 Gemini CLI（带 -y 自动确认）
gemini             # 启动 Gemini CLI（标准模式）
```
