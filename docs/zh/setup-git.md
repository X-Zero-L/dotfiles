# setup-git.sh

配置 Git 全局设置：用户身份和合理的默认值。

## 操作系统支持

适用于所有支持的平台。Git 缺失时通过系统包管理器安装：

| 操作系统 | 包管理器 |
|---------|---------|
| Debian/Ubuntu | `apt` |
| CentOS/RHEL | `yum`/`dnf` |
| Fedora | `dnf` |
| Arch Linux | `pacman` |
| macOS | `brew` (或 Xcode Command Line Tools) |

## 配置内容

| 项目 | 说明 |
|------|------|
| git | 缺失时自动安装 |
| `user.name` | 全局作者名称 |
| `user.email` | 全局作者邮箱 |
| 默认值 | `init.defaultBranch`、`pull.rebase`、`push.autoSetupRemote`、`core.autocrlf` |

## 执行流程

| 步骤 | 操作 |
|------|------|
| 1/2 | 设置 `user.name` 和 `user.email`（如提供了环境变量） |
| 2/2 | 设置合理的默认值 |

## 默认值

| 配置项 | 值 | 说明 |
|--------|-----|------|
| `init.defaultBranch` | `main` | 新仓库默认分支名 |
| `pull.rebase` | `true` | pull 时 rebase 而非 merge |
| `push.autoSetupRemote` | `true` | 首次 push 自动设置上游 |
| `core.autocrlf` | `input` | 提交时将 CRLF 转为 LF |

## 创建/修改的文件

| 文件 | 说明 |
|------|------|
| `~/.gitconfig` | Git 全局配置 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `GIT_USER_NAME` | _（空）_ | `git config --global user.name` 的值 |
| `GIT_USER_EMAIL` | _（空）_ | `git config --global user.email` 的值 |

## 重复运行行为

- 配置值始终以提供的值覆盖。
- 默认值始终应用。

## 依赖

- `git`（缺失时自动安装）。
- 不需要 `sudo`（除非需要安装 git）。
