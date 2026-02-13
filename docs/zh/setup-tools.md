# setup-tools.sh

安装编码代理日常依赖的核心 CLI 工具 — 快速代码搜索、JSON 处理、GitHub CLI、编译工具等。

## 安装内容

| 包名 | 二进制 | 用途 |
|------|--------|------|
| `ripgrep` | `rg` | 快速代码搜索（Claude Code 内部使用） |
| `jq` | `jq` | JSON 处理 |
| `fd-find` | `fdfind` → `fd` | 快速文件查找 |
| `bat` | `batcat` → `bat` | 语法高亮的 cat |
| `tree` | `tree` | 目录结构可视化 |
| `gh` | `gh` | GitHub CLI（PR、Issue、API） |
| `shellcheck` | `shellcheck` | Shell 脚本静态检查 |
| `build-essential` | `gcc`、`g++`、`make` | 原生 npm 模块编译 |
| `wget` | `wget` | HTTP 下载 |
| `unzip` | `unzip` | 解压缩 |
| `xclip` | `xclip` | 剪贴板（tmux 集成） |

## 执行方式

### 步骤 1：apt 包

通过 `apt-get install -y` 安装所有包。apt 天然幂等 — 已安装的包会自动跳过。

### 步骤 2：GitHub CLI

`gh` CLI 需要添加 GitHub 官方 apt 仓库：

```bash
# 添加 GitHub apt 仓库密钥和源列表
wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/...
echo "deb [...] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/...
sudo apt-get install -y gh
```

如果 `gh` 已安装，此步骤完全跳过。

### 步骤 3：便捷符号链接

在 Debian/Ubuntu 上，`fd-find` 安装为 `fdfind`，`bat` 安装为 `batcat`（避免名称冲突）。脚本在 `~/.local/bin/` 创建符号链接：

- `~/.local/bin/fd` → `/usr/bin/fdfind`
- `~/.local/bin/bat` → `/usr/bin/batcat`

仅在规范名称（`fd`、`bat`）尚不可用时才创建符号链接。

## 重复运行行为

脚本完全幂等：

- `apt-get install` 对已安装的包天然幂等。
- 如果 `gh` 命令已存在，跳过安装。
- 仅在目标名称尚不可用时才创建符号链接。

## 依赖

无。此组件不依赖其他 rig 组件。

## 环境变量

无需配置。脚本仅使用系统 apt 仓库和 GitHub 官方 apt 仓库。

## 创建的文件

| 文件 | 说明 |
|------|------|
| `~/.local/bin/bat` | 指向 `batcat` 的符号链接（如需要） |
| `~/.local/bin/fd` | 指向 `fdfind` 的符号链接（如需要） |
| `/etc/apt/keyrings/githubcli-archive-keyring.gpg` | GitHub CLI apt 签名密钥 |
| `/etc/apt/sources.list.d/github-cli.list` | GitHub CLI apt 仓库 |

## 安装后

验证所有工具可用：

```bash
command -v rg jq fd bat tree gh shellcheck gcc wget unzip xclip
```
