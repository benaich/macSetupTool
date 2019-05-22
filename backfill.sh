source ./util.sh
source ./config.sh


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