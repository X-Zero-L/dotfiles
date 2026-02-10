# install.sh

一站式交互或非交互安装器。下载并按依赖顺序执行各个安装脚本。

## 概述

`install.sh` 是一个调度器，提供 TUI 复选框菜单选择组件、解析依赖、收集 API 密钥、从 GitHub 下载所需的 `setup-*.sh` 脚本并按序执行。它本身不包含安装逻辑 — 每个组件的逻辑在各自的脚本中。

## 模式

### 交互式 TUI

有终端且未使用 `--all`/`--components` 时，显示复选框菜单：

```
  > [x] Shell Environment        zsh, Oh My Zsh, plugins, Starship           [sudo]
    [ ] Tmux                     tmux + Catppuccin + TPM plugins              [sudo]
    [x] Node.js (nvm)            nvm + Node.js 24
    ...
```

操作：`↑↓` 导航、`Space` 切换、`a` 全选/全不选、`Enter` 确认、`q` 退出。

### 非交互式

- `--all` — 选择全部组件。
- `--components shell,node,docker` — 按 ID 选择指定组件。

通过管道（`curl | bash`）且无标志时，脚本会退出并给出用法提示。

## 执行流程

1. **解析参数** — `--all`、`--components`、`--gh-proxy`、`--verbose`。
2. **显示 TUI**（交互）或验证选择（非交互）。
3. **解析依赖** — 自动添加缺失的依赖（如选择 Claude Code 会自动添加 Node.js）。
4. **展示计划** — 按安装顺序列出组件，带标签（`sudo`、`key`、`install only`）。
5. **收集 API 密钥** — 交互模式下提示输入 API URL/Key（密钥用 `*` 遮掩）；非交互模式下读取环境变量。缺失密钥则标记为「仅安装」。
6. **缓存 sudo** — 如有组件需要 sudo，预先认证并在后台保持活跃。
7. **下载脚本** — 将所需的 `setup-*.sh` 下载到临时目录（快速失败：所有下载必须成功才开始执行）。
8. **执行** — 按序运行。默认显示 spinner，`--verbose` 模式显示原始输出。
9. **汇总** — 带颜色的通过/失败报告，附安装后提示。

## 依赖解析

| 组件 | 依赖 |
|------|------|
| Claude Code | Node.js |
| Codex CLI | Node.js |
| Gemini CLI | Node.js |
| Agent Skills | Node.js |

依赖会自动添加并优先安装。安装顺序按组件注册表的数组索引排列。

## API 密钥处理

针对 AI 代理组件（Claude Code、Codex、Gemini）：

- **有环境变量**（`CLAUDE_API_URL` + `CLAUDE_API_KEY`）— 安装工具并写入配置。
- **无环境变量** — 交互模式下提示输入（留空则标记「仅安装」）。
- **仅安装** — 安装工具但不配置。汇总中会提示需要设置的环境变量。

## 错误处理

- `install.sh` 使用 `set -uo pipefail`（**没有** `-e`），某个组件失败不会中断其余组件。
- 每个子脚本在独立的 `bash` 子进程中运行，使用 `set -euo pipefail`。
- 失败时显示日志最后 15 行，并给出完整日志路径。

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GH_PROXY` | _（空）_ | GitHub 代理 URL 前缀 |
| `CLAUDE_API_URL` | _（空）_ | Claude Code 的 API 基础地址 |
| `CLAUDE_API_KEY` | _（空）_ | Claude Code 的 API 密钥 |
| `CODEX_API_URL` | _（空）_ | Codex CLI 的 API 基础地址 |
| `CODEX_API_KEY` | _（空）_ | Codex CLI 的 API 密钥 |
| `GEMINI_API_URL` | _（空）_ | Gemini CLI 的 API 基础地址 |
| `GEMINI_API_KEY` | _（空）_ | Gemini CLI 的 API 密钥 |

各脚本自身的环境变量同样生效（如 `NODE_VERSION`、`DOCKER_MIRROR`）。

## 创建的文件

| 文件 | 说明 |
|------|------|
| `/tmp/rig-install-*` | 下载脚本的临时目录（退出时清理） |
| `/tmp/rig-install-*.component` | 各组件的日志文件（失败时保留） |
