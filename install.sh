#! /bin/sh

source ./util.sh
source ./config.sh

bot "Hi! I'm going to install tooling and tweak your system settings. Here I go..."

# ###############################################################################
# # 		sudo
# ###############################################################################

# Ask for the administrator password upfront
sudo -v

# Keep-alive: update existing sudo time stamp if set, otherwise do nothing.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ###############################################################################
# # 		Git config
# ###############################################################################

bot "OK, now I am going to update the .gitconfig for your user info:"
read -r -p "What is your git username? " username
read -r -p "What is your email? " email
read -r -p "What is your dotfile repository url (exp: git@github.com:username/dotfiles.git)? " dotfile

# ###############################################################################
# # 		Generating a new SSH key
# ###############################################################################

ssh-keygen -o -a 100 -t ed25519 -C $email
eval "$(ssh-agent -s)"
ssh-add -K ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub | pbcopy
bot "Go to https://github.com/settings/ssh"
read -p "SSH public key was copied to the clipboard. Please add it to github and press ENTER to continue..."

# # ###########################################################
# # 		Install XCode Dev Tools
# # ###########################################################

bot "ensuring build/install tools are available"
xcode-select --install 2>&1 > /dev/null
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer 2>&1 > /dev/null
sudo xcodebuild -license accept 2>&1 > /dev/null

# ###############################################################################
# # 		Install HomeBrew and Cask
# ###############################################################################

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew update

bot "Installing GNU core utils (those that come with OS X are outdated)..."
brew install coreutils

bot "Adding nightly/beta Cask versions..."
brew tap homebrew/cask-versions

###############################################################################
# 		Install binaries
###############################################################################

bot "Installing binaries..."
brew install ${binaries[@]}

# ###############################################################################
# # 		Install apps
# ###############################################################################

bot "Installing apps to /Applications..."
brew install --cask ${apps[@]}


# ###############################################################################
# # 		Git config
# ###############################################################################

running "replacing items in .gitconfig with your info ($username $email)"

cp config/gitconfig ~/.gitconfig
git config --global user.name $username
git config --global user.email $email

###############################################################################
# 		Install oh-my-zsh
###############################################################################

bot "setting zsh (/usr/local/bin/zsh) as your shell (password required)"
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed '/\s*env\s\s*zsh\s*/d')"
mkdir -p ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions

###############################################################################
# 		Install and configure Starship prompt
###############################################################################

bot "Installing Starship prompt..."
# Starship is installed via Homebrew in the binaries section

# Initialize Starship in .zshrc (will be overridden by dotfiles if present)
if ! grep -q 'eval "$(starship init zsh)"' ~/.zshrc 2>/dev/null; then
    echo '' >> ~/.zshrc
    echo '# Initialize Starship prompt' >> ~/.zshrc
    echo 'eval "$(starship init zsh)"' >> ~/.zshrc
    ok "Starship initialization added to .zshrc"
else
    ok "Starship already configured in .zshrc"
fi

###############################################################################
# 		Dotfiles Setup
###############################################################################

if [[ -n ${dotfile} ]];
then
    git clone $dotfile ~/.dotfiles
    bot "creating symlinks for dotfiles..."
    rcup -v
else
    bot "no dotfiles for you :/"
fi

# ###############################################################################
# # 		Install Fonts
# ###############################################################################

bot "installing fonts"
brew install fontconfig
brew tap homebrew/cask-fonts
brew install ${fonts[@]}

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
if [ ${#node_packages[@]} -gt 0 ]; then
    npm install -g ${node_packages[@]}
    ok "Global npm packages installed"
fi

# Add fnm initialization to .zshrc if not present
if ! grep -q 'fnm env' ~/.zshrc 2>/dev/null; then
    echo '' >> ~/.zshrc
    echo '# Initialize fnm (Fast Node Manager)' >> ~/.zshrc
    echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
    ok "fnm initialization added to .zshrc"
fi

brew cleanup

###############################################################################
# 		Installing VScode extensions
###############################################################################

bot "Installing vscode extensions..."
for element in "${vscode_extensions[@]}"
do
    code --install-extension $element
done

###############################################################################
# 		Setup Colima (Docker Desktop replacement)
###############################################################################

bot "Setting up Colima..."
# Colima, docker, and docker-compose are installed via Homebrew in the binaries section

# Start Colima with reasonable defaults (4 CPUs, 8GB RAM, 100GB disk)
colima start --cpu 4 --memory 8 --disk 100 --arch $(uname -m) 2>/dev/null || {
    warn "Colima may already be running or needs manual configuration"
}

# Verify Docker is working
if docker ps > /dev/null 2>&1; then
    ok "Docker is running via Colima"
else
    warn "Colima setup may need manual configuration. Run 'colima start' after installation."
fi

###############################################################################
# 		Setup OS X defaults and other useful tweaks.
###############################################################################

source ./osx-settings.sh
