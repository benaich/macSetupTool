## About macSetupTool

A script to automate macOS setup with modern development tools via Homebrew. This tool configures a fresh Mac for development by installing tools, setting up git with SSH keys, configuring system settings, and optionally setting up dotfiles.

## Modern Tools (2026)

This setup uses current best-in-class tools optimized for Apple Silicon:

- **Raycast**: Modern productivity launcher with extensions and AI features
- **Ghostty**: GPU-accelerated native terminal written in Zig
- **Arc**: AI-powered Chromium-based browser with vertical tabs
- **Colima**: Lightweight Docker runtime (90% less memory than Docker Desktop)
- **Rectangle**: Apple Silicon native window manager (replaces deprecated Spectacle)
- **Starship**: Fast cross-shell prompt written in Rust
- **fnm**: Fast Node Manager (20-40x faster than nvm)

## Architecture

The tool is organized into four main scripts:

- **install.sh**: Main orchestration script that runs all setup steps in sequence
- **config.sh**: Configuration file containing arrays of packages, apps, fonts, and VS Code extensions
- **osx-settings.sh**: macOS system preferences (Safari, Finder, Dock, trackpad, etc.)
- **util.sh**: Shared utility functions for colored console output

## Files

- `install.sh` - Main installation script
- `config.sh` - Package lists (apps, binaries, fonts, VS Code extensions)
- `osx-settings.sh` - System preferences (Safari, Finder, Dock, etc.)
- `util.sh` - Colored console output utilities

## How to run

```bash
git clone https://github.com/benaich/macSetupTool
cd macSetupTool
sh install.sh
```

You will be prompted for:
- **Git username and email** - for git configuration
- **Dotfile repository URL** (optional) - see [dotfiles.github.io](https://dotfiles.github.io/)
- **Administrator password** - for sudo operations (kept alive during installation)

## What Gets Installed

### Development Tools
- Languages: Java, Ruby, Go, Node.js (via fnm)
- Tools: Git, Maven, Docker (via Colima), Kubernetes CLI
- Utilities: httpie, jq, fzf, bat, tree, ctop, tldr

### Applications
- Editors: VS Code, IntelliJ IDEA
- Browsers: Arc
- Productivity: Raycast, Rectangle, Slack
- Terminal: Ghostty
- DevOps: VirtualBox, Vagrant
- Utilities: The Unarchiver

### Shell Setup
- oh-my-zsh with plugins (zsh-autosuggestions)
- Starship prompt
- Powerline fonts for terminal

### VS Code Extensions
16 essential extensions including GitLens, Docker, Python, Go, Prettier, and more.

## Post-Installation

### Colima (Docker)
Already started during installation. Useful commands:

```bash
colima start         # Start Docker runtime
colima stop          # Stop Docker runtime
colima status        # Check status
colima restart       # Restart with current settings
docker ps            # Works just like Docker Desktop
docker-compose up    # Multi-container orchestration
```

To adjust resources:
```bash
colima stop
colima start --cpu 8 --memory 16 --disk 200
```

### Starship (Shell Prompt)
Customize your prompt at `~/.config/starship.toml`. Example:

```toml
# Get editor completions based on the config schema
"$schema" = 'https://starship.rs/config-schema.json'

# Timeout for starship to scan files (in milliseconds)
scan_timeout = 10

# Add a newline before the prompt
add_newline = true
```

See [starship.rs/config](https://starship.rs/config/) for all options.

### Ghostty (Terminal)
Configuration at `~/.config/ghostty/config` or via dotfiles. Example config:

```
font-family = "JetBrains Mono"
font-size = 14
theme = "Catppuccin Mocha"
window-padding-x = 10
window-padding-y = 10
```

### fnm (Node Manager)
Manage Node.js versions:

```bash
fnm list             # List installed versions
fnm install 20       # Install Node 20
fnm install --lts    # Install latest LTS
fnm use 20           # Switch to Node 20
fnm default 20       # Set Node 20 as default
fnm current          # Show current version
```

Auto-switching via `.node-version` or `.nvmrc` files works automatically with `--use-on-cd`.

### Rectangle (Window Manager)
Keyboard shortcuts (same as Spectacle):
- `⌘ + ⌥ + ←/→` - Left/Right half
- `⌘ + ⌥ + ↑/↓` - Top/Bottom half
- `⌘ + ⌥ + F` - Fullscreen
- `⌘ + ⌥ + C` - Center

Grant accessibility permissions when prompted on first launch.

### Raycast (Productivity Launcher)
- Replace Spotlight with Raycast in System Preferences
- Browse extensions at raycast.com/store
- Use `⌘ + Space` to launch (after changing from Spotlight)

## Customization

### Modifying Installed Packages

Edit arrays in `config.sh`:

- **binaries**: Homebrew formulae (CLI tools)
- **apps**: Homebrew casks (GUI applications)
- **fonts**: Font packages from homebrew/cask-fonts
- **node_packages**: Global npm packages
- **vscode_extensions**: VS Code extension IDs

### macOS System Settings

Edit `osx-settings.sh` to customize:
- Safari preferences (privacy, search, homepage)
- Finder behavior (show hidden files, column view)
- Dock configuration (autohide, indicators)
- Trackpad and keyboard settings (tap to click, repeat rate)
- Screenshot location and format
- Activity Monitor defaults

### Dotfiles Integration

If you provide a dotfile repository URL, the script:
1. Clones it to `~/.dotfiles`
2. Uses `rcup` (from thoughtbot/rcm) to create symlinks
3. Your dotfiles can override any default configurations

## SSH Key Setup

The script automatically:
1. Generates an ed25519 SSH key with 100 KDF rounds (`-a 100`)
2. Adds it to the ssh-agent
3. Copies the public key to your clipboard
4. Pauses for you to add it to GitHub

This ensures secure git operations for all subsequent steps.

## Troubleshooting

### Colima won't start
```bash
colima delete          # Remove existing VM
colima start           # Create fresh VM
```

### fnm not found after installation
```bash
# Reload shell configuration
source ~/.zshrc
# Or restart your terminal
```

### VS Code extensions fail to install
Ensure VS Code command line tools are installed:
```bash
# Open VS Code
# Press Cmd+Shift+P
# Type "shell command"
# Select "Install 'code' command in PATH"
```

### Homebrew permissions issues
```bash
sudo chown -R $(whoami) /usr/local/Homebrew
```

## Migration from Old Tools

### From nvm to fnm
```bash
# Install Node versions you need
fnm install 18
fnm install 20
fnm default 20

# Remove nvm
rm -rf ~/.nvm
# Remove nvm lines from .zshrc
```

### From Docker Desktop to Colima
```bash
# Uninstall Docker Desktop (optional)
# Colima uses the same docker CLI commands
colima start
docker ps  # Should work immediately
```

### From iTerm2 to Ghostty
```bash
# Export iTerm2 preferences first (optional)
# Ghostty uses a simple text config file
# See ~/.config/ghostty/config
```

## Requirements

- macOS (tested on macOS 13+)
- Administrator access (for sudo operations)
- Active internet connection
- GitHub account (for SSH key setup)

## License

Feel free to use and modify for your own setup needs.
