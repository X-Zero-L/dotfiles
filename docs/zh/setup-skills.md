# setup-skills.sh

为所有编码代理（Claude Code、Codex、Gemini）全局安装常用 [agent skills](https://skills.sh/)。

## 操作系统支持

通过 npm 在所有平台上运行（需要 Node.js）：

| 操作系统 | 状态 |
|---------|------|
| Debian/Ubuntu | ✓ |
| CentOS/RHEL | ✓ |
| Fedora | ✓ |
| Arch Linux | ✓ |
| macOS | ✓ |

## 安装内容

| 技能 | 来源 | 说明 |
|------|------|------|
| `find-skills` | [vercel-labs/skills](https://github.com/vercel-labs/skills) | 发现和安装代理技能 |
| `pdf` | [anthropics/skills](https://github.com/anthropics/skills) | PDF 读取和处理 |
| `gemini-cli` | [X-Zero-L/agent-skills](https://github.com/X-Zero-L/agent-skills) | Gemini CLI 集成 |
| `context7` | [intellectronica/agent-skills](https://github.com/intellectronica/agent-skills) | 库文档查询 |
| `writing-plans` | [obra/superpowers](https://github.com/obra/superpowers) | 编写实现计划 |
| `executing-plans` | [obra/superpowers](https://github.com/obra/superpowers) | 带检查点的计划执行 |
| `codex` | [softaworks/agent-toolkit](https://github.com/softaworks/agent-toolkit) | Codex 代理技能 |

## 执行方式

对每个技能执行：

```bash
npx --registry="$SKILLS_NPM_MIRROR" skills add <repo> [--skill <name>] -g -a '*' -y
```

标志说明：
- `-g` — 全局安装（非项目级）。
- `-a '*'` — 对所有代理可用。
- `-y` — 跳过确认提示。

脚本跟踪每个技能的成功/失败状态，最后输出汇总。某个技能安装失败不会阻止其他技能的安装。

## 创建的文件

技能安装到 `skills` CLI 管理的全局技能目录（通常为 `~/.skills/` 或类似路径）。

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SKILLS_NPM_MIRROR` | _（空）_ | npx 使用的 npm 镜像源。设置 `GH_PROXY` 时自动启用。 |

## 重复运行行为

`skills add` 命令内部处理已有技能。重复运行脚本会尝试重新添加所有技能，已安装的由 skills CLI 处理。

## 依赖

- Node.js（先运行 `setup-node.sh`）。
- `skills` CLI 通过 `npx` 调用（无需全局安装）。

## 安装后

验证已安装的技能：

```bash
npx skills list -g
```

技能在 Claude Code、Codex 和 Gemini CLI 运行时自动可用。
