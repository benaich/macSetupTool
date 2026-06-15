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

function start_sudo_keepalive() {
    (
        trap - ERR
        set +e
        while true; do
            sudo -n true >/dev/null 2>&1
            sleep 60
            kill -0 "$$" >/dev/null 2>&1 || exit 0
        done
    ) &
    SUDO_KEEPALIVE_PID="$!"
}

function ensure_native_shell_architecture() {
    if [[ "$(sysctl -in sysctl.proc_translated 2>/dev/null || true)" == "1" ]]; then
        error "This terminal is running under Rosetta. Open a native terminal and rerun install.sh so Homebrew installs Apple Silicon packages."
        exit 1
    fi
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

function allow_login_shell() {
    local shell_path="$1"

    if [[ -z "$shell_path" ]]; then
        return 1
    fi

    if grep -qxF "$shell_path" /etc/shells; then
        return 0
    fi

    bot "Adding $shell_path to /etc/shells..."
    if printf '%s\n' "$shell_path" | sudo tee -a /etc/shells >/dev/null; then
        ok "$shell_path added to /etc/shells"
        return 0
    fi

    warn "Could not add $shell_path to /etc/shells. Skipping shell change."
    return 1
}

function secure_ssh_key_permissions() {
    local private_key="$1"
    local public_key="${private_key}.pub"

    chmod 700 "$(dirname "$private_key")"
    if [[ -f "$private_key" ]]; then
        chmod 600 "$private_key"
    fi
    if [[ -f "$public_key" ]]; then
        chmod 644 "$public_key"
    fi
}

function install_brewfile() {
    local brewfile="$1"
    local label="$2"

    if [[ ! -f "$brewfile" ]]; then
        warn "Skipping missing Brewfile: $brewfile"
        return
    fi

    bot "Installing $label with Homebrew Bundle..."
    if brew bundle check --file "$brewfile" >/dev/null 2>&1; then
        ok "$label is already satisfied"
        return
    fi

    brew bundle install --file "$brewfile"
}

function print_optional_profiles() {
    local entry profile description

    bot "Optional profiles available:"
    for entry in "${optional_brewfiles[@]}"; do
        IFS=: read -r profile _ description <<< "$entry"
        printf '  %s - %s\n' "$profile" "$description"
    done
}

function install_optional_profiles() {
    local selection="$1"
    local entry profile file description requested matched

    selection="${selection//,/ }"
    if [[ -z "$selection" || "$selection" == "none" ]]; then
        ok "No optional profiles selected"
        return
    fi

    if [[ "$selection" == "all" ]]; then
        for entry in "${optional_brewfiles[@]}"; do
            IFS=: read -r profile file description <<< "$entry"
            install_brewfile "$SCRIPT_DIR/$file" "$profile profile"
        done
        return
    fi

    for requested in $selection; do
        matched=false
        for entry in "${optional_brewfiles[@]}"; do
            IFS=: read -r profile file description <<< "$entry"
            if [[ "$requested" == "$profile" ]]; then
                install_brewfile "$SCRIPT_DIR/$file" "$profile profile"
                matched=true
                break
            fi
        done

        if [[ "$matched" == false ]]; then
            warn "Unknown optional profile: $requested"
        fi
    done
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
start_sudo_keepalive

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

secure_ssh_key_permissions "$ssh_key"

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

ensure_native_shell_architecture
ensure_homebrew
brew update

###############################################################################
# 		Install Homebrew packages
###############################################################################

install_brewfile "$SCRIPT_DIR/$core_brewfile" "core tools"

print_optional_profiles
if [[ -n "${MACSETUP_PROFILES:-}" ]]; then
    optional_profile_selection="$MACSETUP_PROFILES"
    ok "Using optional profiles from MACSETUP_PROFILES=$MACSETUP_PROFILES"
else
    read -r -p "Optional profiles to install (space-separated, all, or none) [none]: " optional_profile_selection
fi
install_optional_profiles "${optional_profile_selection:-none}"


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
    if allow_login_shell "$zsh_path"; then
        chsh -s "$zsh_path" || warn "Could not change default shell to $zsh_path."
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
# Starship is installed via Homebrew Bundle

append_to_zshrc_once 'eval "$(starship init zsh)"' "Initialize Starship prompt" 'eval "$(starship init zsh)"'

###############################################################################
# 		Dotfiles Setup
###############################################################################

if [[ -n "$dotfile" ]];
then
    if command -v chezmoi >/dev/null 2>&1; then
        bot "applying dotfiles with chezmoi..."
        chezmoi init --apply "$dotfile" || warn "Could not apply dotfiles with chezmoi."
    elif command -v rcup >/dev/null 2>&1; then
        clone_or_update_repo "$dotfile" "$HOME/.dotfiles" "dotfiles"
        bot "creating symlinks for dotfiles with rcup..."
        rcup -v
    else
        warn "Neither chezmoi nor rcup is available. Skipping dotfiles."
    fi
else
    bot "no dotfiles for you :/"
fi

###############################################################################
# 		Install Node.js with fnm
###############################################################################

bot "Installing Node.js LTS with fnm..."
# fnm is installed via Homebrew Bundle

# Setup fnm environment
eval "$(fnm env --use-on-cd)"

# Install latest LTS Node.js version
fnm install --lts
ok "Node.js LTS installed via fnm"

if command -v corepack >/dev/null 2>&1; then
    corepack enable || warn "Could not enable Corepack. Configure pnpm/yarn per project if needed."
else
    warn "Corepack is not available with this Node installation. Configure pnpm/yarn per project if needed."
fi

append_to_zshrc_once 'fnm env' "Initialize fnm (Fast Node Manager)" 'eval "$(fnm env --use-on-cd)"'

brew cleanup

###############################################################################
# 		Setup Colima (Docker Desktop replacement)
###############################################################################

bot "Setting up Colima..."
# Colima, docker, and docker-compose are installed via Homebrew Bundle

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

bot "Applying macOS defaults..."
(
    set +e
    source "$SCRIPT_DIR/osx-settings.sh"
)
