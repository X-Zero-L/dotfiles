# update.sh

一站式交互或非交互更新器，更新已安装的 rig 组件。检测已安装内容、显示 TUI 复选框菜单、执行更新并展示版本差异摘要。

## 概述

`update.sh` 是独立脚本，与 `install.sh` 具有相同的 TUI 品质，但用于更新已安装的组件。所有更新逻辑内嵌于脚本中（无需下载 `setup-*.sh`）。它检测已安装组件、记录更新前后版本并展示差异摘要。

## 快速开始

```bash
# 交互式 — 仅显示已安装组件，默认全选
bash update.sh

# 非交互式 — 更新所有已安装组件
bash update.sh --all

# 选择性更新
bash update.sh --components codex,claude-code,node

# 通过 install.sh 调度
bash install.sh update
bash install.sh update --all
```

## 模式

### 交互式 TUI

有终端且未使用 `--all`/`--components` 时，显示复选框菜单，**仅显示已安装组件**（默认全选）：

```
  ● Shell Environment         zsh, Oh My Zsh, plugins, Starship
  ● Node.js (nvm)             nvm + Node.js 24
  ● Claude Code               Claude Code CLI
  ○ Codex CLI                 OpenAI Codex CLI           [sudo]
  ● Gemini CLI                Gemini CLI
```

操作：`↑↓` 导航、`Space` 切换、`a` 全选/全不选、`Enter` 确认、`q` 退出。

### 非交互式

- `--all` — 更新所有已安装组件。
- `--components codex,claude-code` — 按 ID 更新指定的已安装组件。

通过管道（`curl | bash`）且无标志时，脚本会退出并给出用法提示。

## 执行流程

1. **解析参数** — `--all`、`--components`、`--gh-proxy`、`--verbose`。
2. **加载环境** — 加载 nvm、goenv、uv PATH 以确保检测正常工作。
3. **检测已安装** — 检查每个组件是否存在。
4. **显示 TUI**（交互）或验证选择（非交互）。
5. **展示计划** — 按序列出选中组件，带 `sudo` 标签。
6. **缓存 sudo** — 如有组件需要 sudo，预先认证。
7. **记录更新前版本** — 记录每个选中组件的当前版本。
8. **执行更新** — 运行各组件的内嵌更新函数。默认显示 spinner，`--verbose` 模式显示原始输出。
9. **记录更新后版本** — 每个组件更新后记录新版本。
10. **汇总** — 带颜色的通过/失败报告，附版本差异（`v1.0 → v1.1` 或 `(no change)`）。

## 组件更新逻辑

| 组件 | 更新内容 | 需要 sudo |
|------|----------|-----------|
| Shell Environment | Oh My Zsh、自定义插件/主题（git pull）、Starship | 否 |
| Tmux | `apt-get --only-upgrade tmux`、TPM 插件 | 是 |
| Git | `apt-get --only-upgrade git` | 是 |
| Essential Tools | `apt-get --only-upgrade` rg、jq、fd、bat、tree、shellcheck、build-essential、gh | 是 |
| Clash Proxy | `git pull` + 重新运行安装器 | 是 |
| Node.js (nvm) | `nvm install node --reinstall-packages-from=current` | 否 |
| uv + Python | `uv self update` | 否 |
| Go (goenv) | `git pull` goenv，安装最新 Go 版本 | 否 |
| Docker | `apt-get --only-upgrade` docker 包 | 是 |
| Tailscale | `tailscale update`（回退：apt） | 是 |
| SSH | `apt-get --only-upgrade openssh-server` | 是 |
| Claude Code | `npm install -g @anthropic-ai/claude-code@latest` | 否 |
| Codex CLI | `npm install -g @openai/codex@latest` | 否 |
| Gemini CLI | `npm install -g @google/gemini-cli@latest` | 否 |
| Agent Skills | 为每个技能仓库重新运行 `npx skills add` | 否 |

## 检测逻辑

每个组件通过检查已安装工件来检测：

| 组件 | 检测方式 |
|------|----------|
| Shell | `~/.oh-my-zsh` 目录存在 |
| Tmux | `tmux` 命令可用 |
| Git | `git` 命令可用 |
| Essential Tools | `rg` 和 `jq` 命令可用 |
| Clash | `~/clash-for-linux` 目录存在 |
| Node.js | `nvm` 函数或 `~/.nvm/nvm.sh` 存在 |
| uv | `uv` 命令可用 |
| Go | `goenv` 命令或 `~/.goenv/bin` 存在 |
| Docker | `docker` 命令可用 |
| Tailscale | `tailscale` 命令可用 |
| SSH | `/etc/ssh/sshd_config` 存在 |
| Claude Code | `claude` 命令可用 |
| Codex CLI | `codex` 命令可用 |
| Gemini CLI | `gemini` 命令可用 |
| Skills | `~/.local/share/skills` 或 `~/.claude/skills` 存在 |

## install.sh 集成

`install.sh` 支持 `update` 子命令，下载并执行 `update.sh`：

```bash
bash install.sh update              # 交互式
bash install.sh update --all        # 非交互式
bash install.sh update --components codex,claude-code
```

在 `update` 之前设置的 `--gh-proxy` 标志会应用于下载 URL：

```bash
bash install.sh --gh-proxy https://gh-proxy.org update --all
```

## 与 install.sh 的差异

| 方面 | install.sh | update.sh |
|------|-----------|-----------|
| 横幅 | "Rig Installer" | "Rig Updater" |
| 菜单 | 全部 15 个组件 | 仅已安装组件 |
| 默认选择 | 无 | 全部已安装 |
| API 密钥收集 | 是 | 否 |
| 依赖解析 | 是 | 否 |
| 脚本下载 | 下载 `setup-*.sh` | 否（逻辑内嵌） |
| 汇总 | 通过/失败 | 通过/失败 + 版本差异 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GH_PROXY` | _（空）_ | GitHub 代理 URL 前缀（用于 Starship 下载、技能镜像） |
| `NODE_VERSION` | _（空）_ | 指定 Node.js 更新版本（默认：最新） |
| `SKILLS_NPM_MIRROR` | _（空）_ | 技能的 npm 注册表镜像（设置 `GH_PROXY` 时自动配置） |

## 错误处理

- `update.sh` 使用 `set -uo pipefail`（**没有** `-e`），某个组件失败不会中断其余组件。
- 失败时显示日志最后 15 行，并给出完整日志路径。
- 失败的组件在汇总中标记为 ✘。

## 创建的文件

| 文件 | 说明 |
|------|------|
| `/tmp/rig-update-*` | 日志文件的基础名称 |
| `/tmp/rig-update-*.component` | 各组件的日志文件（失败时保留） |
