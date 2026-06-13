#!/usr/bin/env bash

binaries=(
	java
	maven
	jenv
	git
	gh
	zsh
	zsh-completions
	zsh-syntax-highlighting
	tmux
	# for generating dotfile symlinks
	thoughtbot/formulae/rcm
	ruby
	go
	httpie
	# a command-line fuzzy finder
	fzf
	# fast source search
	ripgrep
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
	# a command-line YAML, JSON, XML, CSV processor
	yq
	tree
	watch
	# like top for containers
	ctop
	htop
	# fast tldr client
	tealdeer
	# task runner for project-local commands
	just
	# local development certificates
	mkcert
	# Python environment and CLI tooling
	uv
	pyenv
	pipx
	awscli
	vault
	ansible
	# Docker runtime replacement
	colima
	docker
	docker-compose
	docker-credential-helper
	# file watching for development tools
	watchman
	# media and image utilities
	ffmpeg
	imagemagick
	yt-dlp
	# networking and macOS helpers
	websocat
	duti
	rename
	# Fast Node Manager (replaces nvm)
	fnm
	# Modern shell prompt
	starship
)

apps=(
	1password
	visual-studio-code
	intellij-idea
	fork
	virtualbox
	vagrant
	slack
	arc
	firefox
	google-chrome
	raycast
	rectangle
	karabiner-elements
	itsycal
	caffeine
	ghostty
	obsidian
	postman
	dbeaver-community
	figma
	zoom
	aws-vault-binary
	gcloud-cli
	tfswitch
	codex
	claude-code@latest
	# flycut
	# flux
	the-unarchiver
	# appcleaner
	# spotify
	# dropbox
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
	dbaeumer.vscode-eslint
	redhat.vscode-yaml
	redhat.vscode-xml
	yoavbls.pretty-ts-errors
	github.copilot-chat
	anthropic.claude-code
	PKief.material-icon-theme
	wesbos.theme-cobalt2
	wholroyd.jinja
)
