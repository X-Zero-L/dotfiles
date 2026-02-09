# setup-node.sh

安装 nvm（Node 版本管理器）和 Node.js。

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| nvm | [nvm-sh/nvm](https://github.com/nvm-sh/nvm) | Node.js 版本管理器 |
| Node.js | 通过 nvm | JavaScript 运行时（默认 v24） |
| npm | Node.js 自带 | 包管理器 |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/3 | 从 GitHub 下载并运行 nvm 安装脚本 |
| 2/3 | `nvm install <version>` + `nvm alias default <version>` |
| 3/3 | 配置 npm registry（如设置了镜像） |

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.nvm/` | nvm 安装目录 |
| `~/.nvm/nvm.sh` | nvm Shell 函数（由 Shell rc 文件加载） |
| `~/.bashrc` / `~/.zshrc` | 由 nvm 安装器修改，添加 nvm 加载 |
| `~/.nvm/versions/node/` | 已安装的 Node.js 版本 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `NODE_VERSION` | `24` | 要安装的 Node.js 主版本号（也可作为第一个参数传入） |
| `NVM_NODEJS_ORG_MIRROR` | _（空）_ | Node.js 二进制下载镜像。设置 `GH_PROXY` 时自动使用 `https://npmmirror.com/mirrors/node`。 |
| `NPM_REGISTRY` | _（空）_ | npm registry 地址。设置 `GH_PROXY` 时自动使用 `https://registry.npmmirror.com`。 |

## 重复运行行为

- nvm：`~/.nvm/nvm.sh` 存在则跳过安装。
- Node.js：始终运行 `nvm install`（nvm 内部处理缓存；版本已安装时为空操作）。

## 依赖

- `curl`。
- 不需要 `sudo`。

## 安装后

运行 `source ~/.zshrc` 或打开新终端即可使用 `node`、`npm` 和 `nvm`。

注意：依赖 Node.js 的脚本（Claude Code、Codex、Gemini、Skills）会在需要时自动加载 nvm。
