source ./util.sh
source ./config.sh
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
source ./osx-settings.sh

brew tap AdoptOpenJDK/openjdk
brew cask install adoptopenjdk11

brew install ${binaries[@]}
brew cask install ${apps[@]}
brew cask install ${fonts[@]}


###############################################################################
# 		Downloading mirakl repos
###############################################################################

bot "Downloading mirakl repos..."
mkdir ~/workspace
IFS=' ' read -r -a array <<< "$repositories"
for element in "${array[@]}"
do
    git clone git@github.com:mirakl/$element.git
    mv $element ~/workspace
done