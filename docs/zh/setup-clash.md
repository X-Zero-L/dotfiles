# setup-clash.sh

安装 [clash-for-linux](https://github.com/nelvko/clash-for-linux-install) 代理，支持订阅管理。

## 概述

配置本地代理（默认 mihomo 内核），可通过 `clashon`/`clashoff` Shell 函数切换。代理监听 `localhost:7890`，支持 HTTP/HTTPS/SOCKS5。

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| clash-for-linux | [nelvko/clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install) | Clash 管理封装 |
| mihomo（默认） | 由安装器下载 | 代理内核 |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1 | 克隆 `clash-for-linux-install` 到临时目录（使用 `CLASH_GH_PROXY` 加速） |
| 2 | 修补安装脚本，移除交互提示 |
| 3 | 运行 `install.sh mihomo` 安装内核，创建 `~/clashctl/` |
| 4 | 如提供 `CLASH_SUB_URL`，添加订阅并激活 |

## 创建的文件

| 文件 | 说明 |
|------|------|
| `~/clashctl/` | 安装目录 |
| `~/clashctl/scripts/cmd/clashctl.sh` | 管理脚本（由 Shell 源加载） |
| `~/.bashrc` / `~/.zshrc` | 由 clash 安装器修改，添加 clashctl 加载 |

## Shell 函数

安装后可用的函数（通过源加载的 `clashctl.sh`）：

| 函数 | 说明 |
|------|------|
| `clashon` | 启动代理，设置 `http_proxy`/`https_proxy` 环境变量 |
| `clashoff` | 停止代理，取消设置环境变量 |
| `clashsub add <url>` | 添加订阅链接 |
| `clashsub use <n>` | 切换到第 `n` 个订阅 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `CLASH_SUB_URL` | _（空）_ | 订阅链接（也可作为第一个参数传入） |
| `CLASH_KERNEL` | `mihomo` | 代理内核：`mihomo` 或 `clash` |
| `CLASH_GH_PROXY` | `https://gh-proxy.org` | GitHub 加速代理（设为空字符串可禁用） |

## 重复运行行为

- 安装：`~/clashctl/` 存在且含 `clashctl.sh` 则跳过。
- 订阅：提供 `CLASH_SUB_URL` 时会重新添加并激活。

## 依赖

- `git`、`curl`。
- 不需要 `sudo`。

## 安装后

```bash
source ~/.bashrc   # 或 ~/.zshrc
clashon             # 启动代理
```
