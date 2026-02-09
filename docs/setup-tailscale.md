# setup-tailscale.sh

Installs [Tailscale](https://tailscale.com/) VPN mesh network, optionally connects to a tailnet.

## What Gets Installed

| Tool | Source | Description |
|------|--------|-------------|
| Tailscale | [tailscale.com/install.sh](https://tailscale.com/install.sh) | VPN mesh network client |

## How It Works

| Step | Action |
|------|--------|
| 1/2 | Install Tailscale via official install script. Skip if `tailscale` command exists. |
| 2/2 | If `TAILSCALE_AUTH_KEY` is set, run `tailscale up --auth-key=KEY --advertise-exit-node`. Otherwise print hint. |

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `TAILSCALE_AUTH_KEY` | _(empty)_ | Auth key for automatic `tailscale up`. Leave empty to install only. Create one at [Tailscale Admin Console](https://login.tailscale.com/admin/machines/new-linux). |

## Re-run Behavior

- Installation: skipped if `tailscale` command exists.
- Connection: `tailscale up` runs again with the provided auth key (Tailscale handles reconnection).

## Dependencies

- `curl`, `sudo`.

## Post-Install

```bash
# If no auth key was provided:
sudo tailscale up                              # interactive login
sudo tailscale up --auth-key=tskey-auth-xxxxx  # non-interactive

# Check status
tailscale status
tailscale ip
```
