scripts := "install.sh config.sh util.sh osx-settings.sh"

check:
    bash -n {{scripts}}
    shellcheck {{scripts}}
    shfmt -d {{scripts}}

format:
    shfmt -w {{scripts}}
