# setup-codex.sh

安装 [Codex CLI](https://github.com/openai/codex)，可选配置 API 凭据。别名：`cx`。

## 操作系统支持

通过 npm 在所有平台上运行（需要 Node.js）：

| 操作系统 | 状态 |
|---------|------|
| Debian/Ubuntu | ✓ |
| CentOS/RHEL | ✓ |
| Fedora | ✓ |
| Arch Linux | ✓ |
| macOS | ✓ |

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| Codex CLI | `npm install -g @openai/codex` | OpenAI 编码代理 CLI |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/4 | 通过 npm 全局安装 Codex（`codex` 命令存在则跳过） |
| 2/4 | 如提供 API 密钥：合并写入 `~/.codex/config.toml`（模型、provider、特性开关） |
| 3/4 | 如提供 API 密钥：写入 `~/.codex/auth.json`（API 密钥） |
| 4/4 | 在 rc 文件中添加 `alias cx='codex --dangerously-bypass-approvals-and-sandbox'` |

### 配置写入

单个 Node.js 脚本同时处理 `config.toml` 和 `auth.json`：

1. 将现有 `config.toml` 按 TOML section 解析。
2. 独立合并托管的 section（顶层、`[model_providers.*]`、`[features]`）。
3. 保留非托管 section（`[projects.*]`、`[notice.*]` 等）不变。
4. 仅在内容不同时写入（幂等）。

各 section 独立幂等——更新某个 section 不会影响其他 section。

API 密钥通过环境变量（`_CODEX_URL`、`_CODEX_KEY` 等）传递，而非命令行参数。

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.codex/config.toml` | 模型、provider 及特性开关配置 |
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

# 仅在设置 CODEX_FEATURES 时写入；否则保留现有 [features] 不变
[features]
steer = false
collab = true
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
| `CODEX_FEATURES` | _（空）_ | 逗号分隔的特性开关（如 `steer=false,collab=true`） |

### 可用特性

特性为 `[features]` 下的布尔开关。常用项：

| 特性 | 说明 |
|------|------|
| `steer` | 设为 false 时，Enter 逐条排队执行而非立即提交 |
| `collab` | 启用子代理并行工作 |
| `use_linux_sandbox_bwrap` | Bubblewrap 沙箱，更强的文件系统/网络控制（仅 Linux） |
| `apps` | 使用已连接的 ChatGPT App |
| `undo` | 每轮创建 ghost commit 以支持撤销 |
| `js_repl` | 基于持久 Node 内核的 JavaScript REPL |
| `memory_tool` | 基于文件的记忆提取与整合 |

完整列表见 [Codex features 源码](https://github.com/openai/codex/blob/main/codex-rs/core/src/features.rs)。

## 重复运行行为

- 安装：`codex` 命令存在则跳过。
- 配置：按 section 合并。各托管 section 独立比较和更新。非托管 section 保留不变。
- 别名：rc 文件中已存在则跳过。

## 依赖

- Node.js（先运行 `setup-node.sh`）。

## 安装后

```bash
source ~/.zshrc    # 加载别名
cx                 # 启动 Codex（带 --dangerously-bypass-approvals-and-sandbox）
codex              # 启动 Codex（标准模式）
```
