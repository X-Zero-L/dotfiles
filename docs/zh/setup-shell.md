# setup-shell.sh

安装 zsh、Oh My Zsh、插件和 Starship 提示符（Catppuccin 主题）。

## 操作系统支持

适用于所有支持的平台。脚本自动使用相应的包管理器：

| 操作系统 | 包管理器 | 需要 sudo |
|---------|---------|----------|
| Debian/Ubuntu | `apt` | ✓ |
| CentOS/RHEL | `yum`/`dnf` | ✓ |
| Fedora | `dnf` | ✓ |
| Arch Linux | `pacman` | ✓ |
| macOS | `brew` | 仅 Homebrew 操作 |

## 安装内容

| 工具 | 来源 | 说明 |
|------|------|------|
| zsh | 包管理器 | Z shell |
| git, curl, wget, vim | 包管理器 | 常用工具 |
| Oh My Zsh | [ohmyzsh/ohmyzsh](https://github.com/ohmyzsh/ohmyzsh) | Zsh 框架 |
| zsh-autosuggestions | [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | 类似 Fish 的自动补全建议 |
| zsh-syntax-highlighting | [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | 命令语法高亮 |
| z | Oh My Zsh 内置插件 | 按频率/最近访问跳转目录 |
| Starship | [starship.rs](https://starship.rs/) | 跨 Shell 提示符 |

## 执行步骤

| 步骤 | 操作 |
|------|------|
| 1/6 | 通过包管理器安装 zsh、git、curl、wget、vim (apt/yum/dnf/pacman/brew) |
| 2/6 | 无人值守安装 Oh My Zsh（`RUNZSH=no CHSH=no`） |
| 3/6 | 克隆 autosuggestions 和 syntax-highlighting 插件到 `$ZSH_CUSTOM/plugins/` |
| 4/6 | 编辑 `~/.zshrc` — 在 `plugins=(...)` 行中添加插件 |
| 5/6 | 安装 Starship 二进制文件，在 `~/.zshrc` 中添加 `eval "$(starship init zsh)"` |
| 6/6 | 应用 Catppuccin Powerline 预设到 `~/.config/starship.toml` |
| 最后 | 设置 zsh 为默认 Shell (Linux: `sudo chsh`, macOS: `chsh`) |

## 创建/修改的文件

| 文件 | 操作 |
|------|------|
| `~/.oh-my-zsh/` | Oh My Zsh 安装目录 |
| `~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/` | 插件克隆 |
| `~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting/` | 插件克隆 |
| `~/.zshrc` | 修改：插件列表、starship 初始化 |
| `~/.config/starship.toml` | 创建：Catppuccin Powerline 预设 |
| `/etc/passwd` | 修改：用户默认 Shell 改为 zsh |

## 重复运行行为

- apt 包：已安装则跳过（apt 自行处理）。
- Oh My Zsh：`~/.oh-my-zsh/oh-my-zsh.sh` 存在则跳过。
- 插件：插件目录及 `.plugin.zsh` 文件存在则跳过。
- `.zshrc` 插件：`zsh-autosuggestions` 已在文件中则跳过。
- Starship：`starship` 命令存在则跳过。
- Starship init：`starship init zsh` 已在 `.zshrc` 中则跳过。
- 预设：每次运行都重新应用（覆盖 `starship.toml`）。
- 默认 Shell：`$SHELL` 已是 zsh 则跳过。

## 依赖

- `sudo` 权限。
- 网络访问 GitHub（Oh My Zsh、插件）和 starship.rs。

## 安装后

运行 `exec zsh` 或打开新终端开始使用 zsh。终端需要支持 [Nerd Font](https://www.nerdfonts.com/) 才能正常显示 Starship 图标。
