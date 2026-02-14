# setup-docker.sh

安装 Docker、Compose 插件，配置守护进程（镜像加速、日志轮转、地址池、代理）。

## 操作系统特定行为

| 操作系统 | Docker 版本 | 安装方式 | systemd |
|---------|------------|---------|---------|
| Debian/Ubuntu | Docker Engine | [get.docker.com](https://get.docker.com) + apt | ✓ |
| CentOS/RHEL | Docker Engine | [get.docker.com](https://get.docker.com) + yum/dnf | ✓ |
| Fedora | Docker Engine | [get.docker.com](https://get.docker.com) + dnf | ✓ |
| Arch Linux | Docker Engine | [get.docker.com](https://get.docker.com) + pacman | ✓ |
| macOS | Docker Desktop | Homebrew (`brew install --cask docker`) | ✗ |

**macOS 注意事项：**
- 通过 Homebrew Cask 安装 Docker Desktop 而非 Docker Engine
- 无 systemd 服务配置（macOS 不使用 systemd）
- Docker Desktop 管理 daemon.json 的方式不同 - 可能需要手动配置
- 初次安装需要 `sudo`，但 Homebrew 操作不需要

## 安装内容

### Linux (Docker Engine)

| 工具 | 来源 | 说明 |
|------|------|------|
| Docker Engine | [get.docker.com](https://get.docker.com) | 容器运行时 |
| docker-compose-plugin | 包管理器 | `docker compose` 命令 |

### macOS (Docker Desktop)

| 工具 | 来源 | 说明 |
|------|------|------|
| Docker Desktop | Homebrew Cask | 带 GUI 的容器运行时 |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/5 | 通过 `get.docker.com` 便捷脚本安装 Docker Engine |
| 2/5 | 通过 apt 安装 `docker-compose-plugin`（`DOCKER_COMPOSE=0` 时跳过） |
| 3/5 | 将当前用户添加到 `docker` 组 |
| 4/5 | 生成 `/etc/docker/daemon.json`（镜像加速、日志、地址池等） |
| 5/5 | 如设置 `DOCKER_PROXY`：创建 systemd drop-in 配置守护进程代理 + 写入 `~/.docker/config.json` 配置容器代理 |
| 最后 | 仅在配置实际变更时重启 Docker |

### daemon.json 生成

优先使用 `python3`（通过 JSON 合并保留未管理的键）。无 python3 时回退到手动 JSON 构建。

生成的 `daemon.json` 包含：

```json
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "20m", "max-file": "3" },
  "experimental": true,
  "default-address-pools": [
    { "base": "172.17.0.0/12", "size": 24 },
    { "base": "192.168.0.0/16", "size": 24 }
  ]
}
```

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `/etc/docker/daemon.json` | 守护进程配置（镜像、日志、地址池） |
| `/etc/systemd/system/docker.service.d/proxy.conf` | 守护进程代理（仅 `DOCKER_PROXY` 时） |
| `~/.docker/config.json` | 容器代理设置（仅 `DOCKER_PROXY` 时） |
| `/etc/group` | 用户添加到 `docker` 组 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DOCKER_MIRROR` | _（空）_ | 镜像加速地址，多个用逗号分隔。通过 `install.sh` 的 `--gh-proxy` 安装时自动设为 `https://docker.1ms.run` |
| `DOCKER_PROXY` | _（空）_ | 守护进程和容器的 HTTP/HTTPS 代理 |
| `DOCKER_NO_PROXY` | `localhost,127.0.0.0/8` | 不走代理的地址列表 |
| `DOCKER_DATA_ROOT` | _（空）_ | 数据存储目录（默认 `/var/lib/docker`） |
| `DOCKER_LOG_SIZE` | `20m` | 单个日志文件最大大小 |
| `DOCKER_LOG_FILES` | `3` | 最多保留日志文件数 |
| `DOCKER_EXPERIMENTAL` | `1` | 启用实验性功能（`0` 禁用） |
| `DOCKER_ADDR_POOLS` | `172.17.0.0/12:24,192.168.0.0/16:24` | 默认地址池（`base/cidr:size`） |
| `DOCKER_COMPOSE` | `1` | 安装 docker-compose-plugin（`0` 跳过） |

## 重复运行行为

- Docker Engine：`docker` 命令存在则跳过。
- Compose 插件：`docker compose version` 成功则跳过。
- 用户组：用户已在 `docker` 组则跳过。
- daemon.json：快照前后对比，仅配置变更时重启 Docker。
- 代理 drop-in：前后对比，仅变更时重启 Docker。

## 依赖

- `sudo` 权限。
- `curl`。
- 建议有 `python3`（实现干净的 JSON 合并）。无 python3 也能工作，但会完全替换 daemon.json。

## 安装后

运行 `newgrp docker` 或重新登录，即可免 `sudo` 使用 Docker。
