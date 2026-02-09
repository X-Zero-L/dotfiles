# setup-codex.sh

安装 [Codex CLI](https://github.com/openai/codex)，可选配置 API 凭据。别名：`cx`。

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| Codex CLI | `npm install -g @openai/codex` | OpenAI 编码代理 CLI |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/4 | 通过 npm 全局安装 Codex（`codex` 命令存在则跳过） |
| 2/4 | 如提供 API 密钥：写入 `~/.codex/config.toml`（模型、provider、推理强度） |
| 3/4 | 如提供 API 密钥：写入 `~/.codex/auth.json`（API 密钥） |
| 4/4 | 在 rc 文件中添加 `alias cx='codex --dangerously-bypass-approvals-and-sandbox'` |

### 配置写入

单个 Node.js 脚本同时处理 `config.toml` 和 `auth.json`：

1. 构建两个文件的期望内容。
2. 与现有内容进行全文比较。
3. 仅在内容不同时写入。

API 密钥通过环境变量（`_CODEX_URL`、`_CODEX_KEY` 等）传递，而非命令行参数。

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.codex/config.toml` | 模型和 provider 配置 |
| `~/.codex/auth.json` | API 密钥（权限 `0600`） |
| `~/.bashrc` | 添加别名 `cx` |
| `~/.zshrc` | 添加别名 `cx` |

### config.toml 结构

```toml
disable_response_storage = true
model = "gpt-5.2"
model_provider = "ellyecode"
model_reasoning_effort = "xhigh"
personality = "pragmatic"

[model_providers.ellyecode]
base_url = "https://your-api-url"
name = "ellyecode"
requires_openai_auth = true
wire_api = "responses"
```

### auth.json 结构

```json
{
  "OPENAI_API_KEY": "your-key"
}
```

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CODEX_API_URL` | _（空）_ | API 基础地址（留空则只安装不配置） |
| `CODEX_API_KEY` | _（空）_ | API 密钥（留空则只安装不配置） |
| `CODEX_MODEL` | `gpt-5.2` | 模型名称 |
| `CODEX_EFFORT` | `xhigh` | 推理强度 |
| `CODEX_NPM_MIRROR` | _（空）_ | npm 镜像源。设置 `GH_PROXY` 时自动启用。 |

## 重复运行行为

- 安装：`codex` 命令存在则跳过。
- 配置：两个文件均进行全文比较。仅在内容不同时写入。
- 别名：rc 文件中已存在则跳过。

## 依赖

- Node.js（先运行 `setup-node.sh`）。

## 安装后

```bash
source ~/.zshrc    # 加载别名
cx                 # 启动 Codex（带 --dangerously-bypass-approvals-and-sandbox）
codex              # 启动 Codex（标准模式）
```
