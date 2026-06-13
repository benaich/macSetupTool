#!/usr/bin/env bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/util.sh"
source "$SCRIPT_DIR/config.sh"

function cleanup() {
    if [[ -n "${SUDO_KEEPALIVE_PID:-}" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
    fi
}

function on_error() {
    local line_number="$1"
    error "Install failed near line ${line_number}."
}

function ensure_homebrew() {
    if command -v brew >/dev/null 2>&1; then
        return
    fi

    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        return
    fi

    if [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
        return
    fi

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    else
        error "Homebrew installation finished, but brew is not available in PATH."
        exit 1
    fi
}

function append_to_zshrc_once() {
    local needle="$1"
    local label="$2"
    local line="$3"
    local zshrc="$HOME/.zshrc"

    touch "$zshrc"
    if grep -Fq "$needle" "$zshrc"; then
        ok "$label already configured in .zshrc"
        return
    fi

    {
        printf '\n# %s\n' "$label"
        printf '%s\n' "$line"
    } >> "$zshrc"
    ok "$label added to .zshrc"
}

function clone_or_update_repo() {
    local repo_url="$1"
    local target_dir="$2"
    local label="$3"

    if [[ -d "$target_dir/.git" ]]; then
        ok "$label already cloned"
        git -C "$target_dir" pull --ff-only || warn "Could not update $label, continuing with existing checkout."
        return
    fi

    if [[ -e "$target_dir" ]]; then
        warn "$target_dir already exists but is not a git checkout. Skipping $label clone."
        return
    fi

    git clone "$repo_url" "$target_dir"
}

trap cleanup EXIT
trap 'on_error "$LINENO"' ERR

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."

# ###############################################################################
# # 		sudo
# ###############################################################################

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
SUDO_KEEPALIVE_PID="$!"

# ###############################################################################
# # 		Git config
# ###############################################################################

bot "OK, now I am going to update the .gitconfig for your user info:"
current_git_name="$(git config --global --get user.name 2>/dev/null || true)"
current_git_email="$(git config --global --get user.email 2>/dev/null || true)"
read -r -p "What is your git username${current_git_name:+ [$current_git_name]}? " username
read -r -p "What is your email${current_git_email:+ [$current_git_email]}? " email
read -r -p "What is your dotfile repository url (exp: git@github.com:username/dotfiles.git)? " dotfile
username="${username:-$current_git_name}"
email="${email:-$current_git_email}"

# ###############################################################################
# # 		Generating a new SSH key
# ###############################################################################

ssh_key="$HOME/.ssh/id_ed25519"
generated_ssh_key=false

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -f "$ssh_key" ]]; then
    ok "SSH key already exists at $ssh_key"
else
    ssh-keygen -o -a 100 -t ed25519 -C "$email" -f "$ssh_key"
    generated_ssh_key=true
fi

eval "$(ssh-agent -s)"
if ssh-add --apple-use-keychain "$ssh_key" 2>/dev/null; then
    ok "SSH key added to agent and Apple keychain"
elif ssh-add -K "$ssh_key" 2>/dev/null; then
    ok "SSH key added to agent and Apple keychain"
else
    ssh-add "$ssh_key"
fi

pbcopy < "${ssh_key}.pub"
if [[ "$generated_ssh_key" == true ]]; then
    bot "Go to https://github.com/settings/ssh"
    read -r -p "SSH public key was copied to the clipboard. Please add it to github and press ENTER to continue..."
else
    ok "Existing SSH public key copied to clipboard"
fi

# # ###########################################################
# # 		Install XCode Dev Tools
# # ###########################################################

bot "ensuring build/install tools are available"
if xcode-select -p >/dev/null 2>&1; then
    ok "Xcode Command Line Tools are already available"
else
    xcode-select --install >/dev/null 2>&1 || warn "Xcode Command Line Tools installation prompt may already be open."
fi

if [[ -d /Applications/Xcode.app/Contents/Developer ]]; then
    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer >/dev/null 2>&1 || warn "Could not select full Xcode developer directory."
fi

if command -v xcodebuild >/dev/null 2>&1; then
    sudo xcodebuild -license accept >/dev/null 2>&1 || warn "Could not accept Xcode license automatically."
fi

# ###############################################################################
# # 		Install HomeBrew and Cask
# ###############################################################################

ensure_homebrew
brew update

###############################################################################
# 		Install binaries
###############################################################################

bot "Installing binaries..."
brew install "${binaries[@]}"

# ###############################################################################
# # 		Install apps
# ###############################################################################

bot "Installing apps to /Applications..."
brew install --cask "${apps[@]}"


# ###############################################################################
# # 		Git config
# ###############################################################################

running "replacing items in .gitconfig with your info ($username $email)"

if [[ -f "$HOME/.gitconfig" && ! -f "$HOME/.gitconfig.macSetupTool.bak" ]]; then
    cp "$HOME/.gitconfig" "$HOME/.gitconfig.macSetupTool.bak"
    ok "Existing .gitconfig backed up to ~/.gitconfig.macSetupTool.bak"
fi

cp "$SCRIPT_DIR/config/gitconfig" "$HOME/.gitconfig"
if [[ -n "$username" ]]; then
    git config --global user.name "$username"
fi
if [[ -n "$email" ]]; then
    git config --global user.email "$email"
fi
ok "Git config updated"

###############################################################################
# 		Install oh-my-zsh
###############################################################################

zsh_path="$(command -v zsh || true)"
if [[ -n "$zsh_path" && "${SHELL:-}" != "$zsh_path" ]]; then
    if grep -qxF "$zsh_path" /etc/shells; then
        chsh -s "$zsh_path" || warn "Could not change default shell to $zsh_path."
    else
        warn "$zsh_path is not listed in /etc/shells. Skipping shell change."
    fi
fi

if [[ -d "$HOME/.oh-my-zsh" ]]; then
    ok "oh-my-zsh already installed"
else
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

zsh_autosuggestions_dir="$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
mkdir -p "$(dirname "$zsh_autosuggestions_dir")"
clone_or_update_repo "https://github.com/zsh-users/zsh-autosuggestions.git" "$zsh_autosuggestions_dir" "zsh-autosuggestions"

###############################################################################
# 		Install and configure Starship prompt
###############################################################################

bot "Installing Starship prompt..."
# Starship is installed via Homebrew in the binaries section

append_to_zshrc_once 'eval "$(starship init zsh)"' "Initialize Starship prompt" 'eval "$(starship init zsh)"'

###############################################################################
# 		Dotfiles Setup
###############################################################################

if [[ -n "$dotfile" ]];
then
    clone_or_update_repo "$dotfile" "$HOME/.dotfiles" "dotfiles"
    bot "creating symlinks for dotfiles..."
    rcup -v
else
    bot "no dotfiles for you :/"
fi

# ###############################################################################
# # 		Install Fonts
# ###############################################################################

bot "installing fonts"
brew install --cask "${fonts[@]}"

###############################################################################
# 		Installing global node packages with fnm
###############################################################################

bot "Installing global node packages with fnm..."
# fnm is installed via Homebrew in the binaries section

# Setup fnm environment
eval "$(fnm env --use-on-cd)"

# Install latest LTS Node.js version
fnm install --lts
ok "Node.js LTS installed via fnm"

# Install global npm packages
if (( ${#node_packages[@]} > 0 )); then
    npm install -g "${node_packages[@]}"
    ok "Global npm packages installed"
fi

append_to_zshrc_once 'fnm env' "Initialize fnm (Fast Node Manager)" 'eval "$(fnm env --use-on-cd)"'

brew cleanup

###############################################################################
# 		Installing VScode extensions
###############################################################################

bot "Installing vscode extensions..."
if command -v code >/dev/null 2>&1; then
    installed_extensions="$(code --list-extensions | tr '[:upper:]' '[:lower:]')"
    for element in "${vscode_extensions[@]}"
    do
        if grep -qxF "$(printf '%s' "$element" | tr '[:upper:]' '[:lower:]')" <<< "$installed_extensions"; then
            ok "VS Code extension already installed: $element"
        else
            code --install-extension "$element"
        fi
    done
else
    warn "VS Code CLI is not available. Skipping extension installation."
fi

###############################################################################
# 		Setup Colima (Docker Desktop replacement)
###############################################################################

bot "Setting up Colima..."
# Colima, docker, and docker-compose are installed via Homebrew in the binaries section

# Start Colima with reasonable defaults (4 CPUs, 8GB RAM, 100GB disk)
if colima status >/dev/null 2>&1; then
    ok "Colima is already running"
else
    colima start --cpu 4 --memory 8 --disk 100 --arch "$(uname -m)" 2>/dev/null || {
        warn "Colima may already be running or needs manual configuration"
    }
fi

# Verify Docker is working
if docker ps > /dev/null 2>&1; then
    ok "Docker is running via Colima"
else
    warn "Colima setup may need manual configuration. Run 'colima start' after installation."
fi

###############################################################################
# 		Setup OS X defaults and other useful tweaks.
###############################################################################

source "$SCRIPT_DIR/osx-settings.sh"
