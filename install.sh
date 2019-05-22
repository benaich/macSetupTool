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

running "replacing items in .gitconfig with your info ($username $email)"

cp config/gitconfig ~/.gitconfig
git config --global user.name $username
git config --global user.email $email

# ###############################################################################
# # 		Generating a new SSH key
# ###############################################################################

ssh-keygen -t rsa -b 4096 -C $email
eval "$(ssh-agent -s)"
ssh-add -K ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub | pbcopy
bot "Go to https://github.com/settings/ssh"
read -p "SSH public key was copied to the clipboard. Please add it to github and press ENTER to continue..."

# ###########################################################
# 		/etc/hosts -- spyware/ad blocking
# ###########################################################

action "Overwriting /etc/hosts with the ad-blocking hosts file from someonewhocares.org? (from ./configs/hosts file)"
sudo cp /etc/hosts /etc/hosts.backup
sudo cp ./configs/hosts /etc/hosts
bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup"

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

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew update

bot "Installing GNU core utils (those that come with OS X are outdated)..."
brew install coreutils

bot "Adding nightly/beta Cask versions..."
brew tap homebrew/cask-versions

###############################################################################
# 		Install binaries
###############################################################################

bot "Installing java..."
brew cask install java

bot "Installing binaries..."
brew install ${binaries[@]}

# ###############################################################################
# # 		Install apps
# ###############################################################################

bot "Installing apps to /Applications..."
brew cask install ${apps[@]}

###############################################################################
# 		Install oh-my-zsh
###############################################################################

bot "setting zsh (/usr/local/bin/zsh) as your shell (password required)"
sh -c "$(curl -fsSL https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed '/\s*env\s\s*zsh\s*/d')"
mkdir ~/.oh-my-zsh/plugins/zsh-autosuggestions
git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
curl https://raw.githubusercontent.com/caiogondim/bullet-train.zsh/master/bullet-train.zsh-theme --output ~/.oh-my-zsh/themes/bullet-train.zsh-theme

###############################################################################
# 		Dotfiles Setup
###############################################################################
# git clone git@github.com:benaich/dotfiles.git ~/.dotfiles

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
brew cask install ${fonts[@]}

###############################################################################
# 		Installing global node packages
###############################################################################

bot "Installing global node packages..."
brew install nvm
nvm install node
npm install -g ${node_packages[@]}
brew cleanup

###############################################################################
# 		Installing VScode extensions
###############################################################################
ln -s ~/.dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -s ~/.dotfiles/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -s ~/.dotfiles/vscode/snippets/ ~/Library/Application\ Support/Code/User/snippets

bot "Installing vscode extensions..."
for element in "${vscode_extensions[@]}"
do
    code --install-extension $element
done

# ###############################################################################
# # 		Sublime Text
# ###############################################################################

# bot "Installing global node packages..."
# mv ~/.dotfiles/sublime ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User

# cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Default\ (OSX).sublime-keymap ~/.dotfiles/sublime
# cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Package\ Control.sublime-settings ~/.dotfiles/sublime
# cp ~/Library/Application\ Support/Sublime\ Text\ 3/Packages/User/Preferences.sublime-settings ~/.dotfiles/sublime
###############################################################################
# 		Setup OS X defaults and other useful tweaks.
###############################################################################

source ./osx-settings.sh
