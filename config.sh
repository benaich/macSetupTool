#!/usr/bin/env bash

binaries=(
	java
	maven
	git
	zsh
	zsh-completions
	zsh-syntax-highlighting
	# for generating dotfile symlinks
	thoughtbot/formulae/rcm
	ruby
	go
	httpie
	# a command-line fuzzy finder
	fzf
	bash-completion
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
	tree
	watch
	# like top for containers
	ctop
	# fast tldr client
	tealdeer
	kubernetes-cli
	# Docker runtime replacement
	colima
	docker
	docker-compose
	# Fast Node Manager (replaces nvm)
	fnm
	# Modern shell prompt
	starship
)

apps=(
	visual-studio-code
	intellij-idea
	virtualbox
	vagrant
	slack
	arc
	raycast
	rectangle
	ghostty
	# flycut
	# flux
	the-unarchiver
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
	font-meslo-lg-nerd-font
	font-hack-nerd-font
	font-jetbrains-mono
	font-roboto-mono
	font-source-code-pro
	font-fontawesome
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
	golang.Go
	PKief.material-icon-theme
	wesbos.theme-cobalt2
	wholroyd.jinja
)
