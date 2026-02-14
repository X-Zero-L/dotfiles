# setup-tailscale.sh

安装 [Tailscale](https://tailscale.com/) VPN 组网，可选自动连接。

## 操作系统支持

Tailscale 官方安装器支持所有主流平台：

| 操作系统 | 安装方式 |
|---------|---------|
| Debian/Ubuntu | 官方脚本（添加 apt 仓库） |
| CentOS/RHEL | 官方脚本（添加 yum/dnf 仓库） |
| Fedora | 官方脚本（添加 dnf 仓库） |
| Arch Linux | 官方脚本（使用 pacman） |
| macOS | 官方脚本（使用 Homebrew 或 App Store） |

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| Tailscale | [tailscale.com/install.sh](https://tailscale.com/install.sh) | VPN 组网客户端 |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/2 | 通过官方安装脚本安装 Tailscale。`tailscale` 命令存在则跳过。 |
| 2/2 | 如设置 `TAILSCALE_AUTH_KEY`，执行 `tailscale up --auth-key=KEY --advertise-exit-node`。否则提示手动连接。 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `TAILSCALE_AUTH_KEY` | _（空）_ | 自动连接的 Auth Key。留空则仅安装。前往 [Tailscale 管理后台](https://login.tailscale.com/admin/machines/new-linux) 创建。 |

## 重复运行行为

- 安装：`tailscale` 命令存在则跳过。
- 连接：使用提供的 Auth Key 重新执行 `tailscale up`（Tailscale 内部处理重连）。

## 依赖

- `curl`、`sudo`。

## 安装后

```bash
# 如未提供 Auth Key：
sudo tailscale up                              # 交互式登录
sudo tailscale up --auth-key=tskey-auth-xxxxx  # 非交互式

# 查看状态
tailscale status
tailscale ip
```
