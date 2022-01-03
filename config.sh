#! /bin/sh

binaries=(
	java
	maven
	git
	zsh
	zsh-completions
	zsh-syntax-highlighting
	#for generating dotfile symlinks
	thoughtbot/formulae/rcm
	ruby
	go
	httpie
	# a command-line fuzzy finder
	fzf
	bash-completion
	# it corrects your previous console command
	thefuck
	# psql client
	libpq
	bat
	coreutils
	dos2unix
	findutils
	gnu-sed
	grep
	# a command-line JSON processor
	jq
	screen
	tmux
	tree
	watch
	# like top for containers
	ctop
	# simplifies the man page
	tldr
	kubernetes-cli
)

apps=(
	visual-studio-code
	intellij-idea
	docker
	virtualbox
	vagrant
	slack
	google-chrome
	alfred
	spectacle
	iterm2
	# flycut
	# flux
	# the-unarchiver
	# caffeine
	# appcleaner
	# spotify
	# dropbox
	# google-cloud-sdk
	# qbittorrent
)

node_packages=(
  yarn
)

fonts=(
	font-meslo-for-powerline
	font-fontawesome
	font-awesome-terminal-fonts
	font-hack
	font-inconsolata-dz-for-powerline
	font-inconsolata-g-for-powerline
	font-inconsolata-for-powerline
	font-roboto-mono
	font-roboto-mono-for-powerline
	font-source-code-pro
)

vscode_extensions=(
	766b.go-outliner
	adpyke.vscode-sql-formatter
	bbenoist.vagrant
	davidnussio.vscode-jq-playground
	eamodio.gitlens
	esbenp.prettier-vscode
	k--kato.intellij-idea-keybindings
	ms-azuretools.vscode-docker
	ms-python.python
	ms-vscode.Go
	PKief.material-icon-theme
	wesbos.theme-cobalt2
	wholroyd.jinja
)
