# setup-ssh.sh

配置 OpenSSH 服务器：自定义端口、密钥登录和 GitHub SSH 代理。

## 配置内容

| 项目 | 说明 |
|------|------|
| openssh-server | 缺失时自动安装 |
| 端口 | 自定义 SSH 端口（可选） |
| 私钥 | 导入到 `~/.ssh/`，用于对外 SSH（如 GitHub） |
| 公钥 | 添加到 `~/.ssh/authorized_keys`，用于被连入 |
| 密码登录 | 提供公钥时自动禁用 |
| GitHub SSH 代理 | `~/.ssh/config` 配置 443 端口 + corkscrew 代理（可选） |

## 执行流程

| 步骤 | 操作 |
|------|------|
| 1/6 | 确保 `sshd` 已安装并运行 |
| 2/6 | 导入私钥到 `~/.ssh/`（如设置了 `SSH_PRIVATE_KEY`），自动生成 `.pub` |
| 3/6 | 设置自定义端口（如设置了 `SSH_PORT`） |
| 4/6 | 添加公钥到 `~/.ssh/authorized_keys`（如设置了 `SSH_PUBKEY`） |
| 5/6 | 禁用密码登录，启用密钥登录（仅在提供了 `SSH_PUBKEY` 时） |
| 6/6 | 配置 GitHub SSH 代理到 `~/.ssh/config`（如设置了 `SSH_PROXY_PORT`） |

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `/etc/ssh/sshd_config` | SSH 服务端配置（修改前自动备份） |
| `~/.ssh/authorized_keys` | 授权公钥文件（被连入） |
| `~/.ssh/id_ed25519` | 导入的私钥（自动检测 RSA/ECDSA） |
| `~/.ssh/id_ed25519.pub` | 自动派生的公钥 |
| `~/.ssh/config` | SSH 客户端配置，含 GitHub 代理设置 |
| `~/.ssh/` | 目录不存在时创建，权限 `700` |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SSH_PORT` | _（空）_ | 自定义 SSH 端口。留空则不修改。 |
| `SSH_PUBKEY` | _（空）_ | 公钥字符串（如 `ssh-ed25519 AAAA...`）。设置后添加密钥并禁用密码登录。 |
| `SSH_PRIVATE_KEY` | _（空）_ | 私钥内容。设置后写入 `~/.ssh/` 并自动派生公钥。密钥类型自动检测。 |
| `SSH_PROXY_HOST` | `127.0.0.1` | 代理主机地址。仅在设置了 `SSH_PROXY_PORT` 时生效。 |
| `SSH_PROXY_PORT` | _（空）_ | 代理端口（如 `7890`）。设置后配置 `~/.ssh/config`，通过 `ssh.github.com:443` + corkscrew 代理连接 GitHub。适用于 22 端口被封或需要代理的场景。 |

## 重复运行行为

- openssh-server：已安装则跳过。
- 端口：已设为目标端口则跳过。
- 私钥：密钥文件已存在则跳过。
- 公钥：已在 `authorized_keys` 中则跳过。
- 密码登录：提供 `SSH_PUBKEY` 时始终重新配置。
- GitHub SSH 配置：`~/.ssh/config` 中已有 `Host github.com` 则跳过。
- 修改 `sshd_config` 前会自动备份。

## 依赖

- 需要 `sudo`。
- `openssh-server`（缺失时自动安装）。
- `corkscrew`（设置 `SSH_PROXY_PORT` 时自动安装）。

## 安装后

如果修改了 SSH 端口，请注意：

1. 更新防火墙规则：`sudo ufw allow <端口>/tcp`
2. 使用新端口连接：`ssh -p <端口> user@host`

**警告：** 启用密钥登录后，请确保密钥可以正常使用再关闭当前会话。

测试 GitHub SSH 连接：`ssh -T git@github.com`
