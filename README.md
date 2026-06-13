## About macSetupTool

A reproducible macOS setup for software engineering work. The project installs a lean default toolchain with Homebrew Bundle, then lets you opt into heavier profiles for backend, cloud, media, personal, or VM-based workflows.

## Defaults

The default setup favors tools that are broadly useful on a fresh Apple Silicon Mac:

- **Homebrew Bundle** for declarative, idempotent package installs.
- **Ghostty** for a fast native terminal.
- **Raycast** for launcher and productivity workflows.
- **Colima** for Docker without Docker Desktop.
- **VS Code** as the default editor, with baseline development extensions.
- **fnm** for Node.js LTS.
- **uv** for modern Python package, tool, and environment workflows.
- **Starship** and **Nerd Fonts** for a fast shell prompt.
- **ShellCheck** and **shfmt** for maintaining this project’s shell scripts.

## Files

- `install.sh` - Main orchestration script.
- `Brewfile` - Core formulae, casks, fonts, and VS Code extensions.
- `Brewfile.personal` - Daily apps, productivity tools, and AI assistants.
- `Brewfile.backend` - Backend, API, database, and IDE tools.
- `Brewfile.cloud` - AWS, GCP, Vault, Terraform/OpenTofu switching, and Ansible.
- `Brewfile.media` - Media and image utilities.
- `Brewfile.vm` - VirtualBox and Vagrant workflows.
- `config.sh` - Brewfile profile registry used by `install.sh`.
- `osx-settings.sh` - macOS system preferences.
- `util.sh` - Colored console output utilities.
- `justfile` - Local check and format tasks.

## How to Run

```bash
git clone https://github.com/benaich/macSetupTool
cd macSetupTool
bash install.sh
```

The script installs the core `Brewfile`, then asks which optional profiles to install:

```text
personal backend cloud media vm
```

You can also run non-interactively:

```bash
MACSETUP_PROFILES="personal backend" bash install.sh
MACSETUP_PROFILES="all" bash install.sh
MACSETUP_PROFILES="none" bash install.sh
```

You will be prompted for:

- Git username and email, with current global values as defaults.
- Dotfile repository URL, optional.
- Administrator password for sudo operations.

## Core Install

### Languages And Runtimes

- Java, Maven
- Ruby
- Go
- Node.js LTS via `fnm`
- Python workflows via `uv`

### CLI Tools

- Git, GitHub CLI
- Docker CLI, Docker Compose, Colima
- `fzf`, `ripgrep`, `fd`, `eza`, `bat`
- `jq`, `yq`, `tree`, `watch`, `ctop`, `htop`
- `tealdeer`, `just`, `zoxide`, `tmux`
- `git-delta`, `lazygit`, `mkcert`
- `shellcheck`, `shfmt`

### Applications

- 1Password
- Visual Studio Code
- Ghostty
- Raycast
- Firefox
- Google Chrome
- The Unarchiver

## Optional Profiles

| Profile | Use when you need |
| --- | --- |
| `personal` | Slack, Zoom, Obsidian, Figma, Fork, Rectangle, Karabiner-Elements, Caffeine, Arc, Codex, Claude Code |
| `backend` | IntelliJ IDEA, Postman, DBeaver, PostgreSQL client libraries, Watchman, SQL/JQ/Jinja VS Code extensions |
| `cloud` | AWS CLI, AWS Vault, GCloud CLI, Vault, Terraform/OpenTofu switching with tenv, Ansible |
| `media` | FFmpeg, ImageMagick, yt-dlp |
| `vm` | VirtualBox, Vagrant, Vagrant VS Code extension |

## Post-Installation

### Colima

Colima is started during installation. Useful commands:

```bash
colima start
colima stop
colima status
colima restart
docker ps
docker compose up
```

To adjust resources:

```bash
colima stop
colima start --cpu 8 --memory 16 --disk 200
```

### Node.js

Node.js LTS is installed through `fnm`:

```bash
fnm list
fnm install --lts
fnm install 24
fnm use 24
fnm default 24
fnm current
```

The installer enables Corepack when available. Package managers such as `pnpm` and `yarn` should be selected per project through `packageManager` rather than installed globally by this setup.

### Starship

Customize your prompt at `~/.config/starship.toml`.

```toml
"$schema" = 'https://starship.rs/config-schema.json'
scan_timeout = 10
add_newline = true
```

See [starship.rs/config](https://starship.rs/config/) for all options.

### Ghostty

Configuration lives at `~/.config/ghostty/config` or in your dotfiles.

```text
font-family = "JetBrains Mono"
font-size = 14
theme = "Catppuccin Mocha"
window-padding-x = 10
window-padding-y = 10
```

## Customization

Edit the relevant Brewfile:

- `Brewfile` for the default install.
- `Brewfile.personal` for daily apps.
- `Brewfile.backend` for backend tools.
- `Brewfile.cloud` for cloud tools.
- `Brewfile.media` for media tools.
- `Brewfile.vm` for VM tools.

Use Homebrew Bundle directly when you only want packages:

```bash
brew bundle check --file Brewfile
brew bundle install --file Brewfile
brew bundle install --file Brewfile.personal
```

## Dotfiles Integration

If you provide a dotfile repository URL, the script:

1. Applies it with `chezmoi` when available.
2. Falls back to cloning it to `~/.dotfiles` and running `rcup` when `chezmoi` is unavailable and `rcup` is already installed.
3. Lets your dotfiles override default configurations.

## SSH Key Setup

The script:

1. Reuses `~/.ssh/id_ed25519` when present.
2. Generates an ed25519 key with 100 KDF rounds when missing.
3. Adds it to the ssh-agent and Apple keychain when possible.
4. Copies the public key to your clipboard.
5. Pauses for GitHub setup only when it generated a new key.

## Project Maintenance

```bash
just check
just format
```

`just check` runs Bash syntax checks, ShellCheck, and shfmt diff checks.

## Troubleshooting

### Colima Won't Start

```bash
colima delete
colima start
```

### fnm Not Found After Installation

```bash
source ~/.zshrc
```

Or restart your terminal.

### VS Code Extensions Fail To Install

Ensure the `code` command line tool is available:

```bash
# Open VS Code
# Press Cmd+Shift+P
# Type "shell command"
# Select "Install 'code' command in PATH"
```

## Migration Notes

### From nvm To fnm

```bash
fnm install --lts
fnm default 24
rm -rf ~/.nvm
```

Remove `nvm` lines from `.zshrc`.

### From Docker Desktop To Colima

```bash
colima start
docker ps
```

### From iTerm2 To Ghostty

Ghostty uses a plain text config file at `~/.config/ghostty/config`.

## Requirements

- macOS, tested on macOS 13+
- Administrator access
- Active internet connection
- GitHub account for SSH key setup

## License

Feel free to use and modify for your own setup needs.
