#!/usr/bin/env bash

# ###########################################################
# printing with colors
# ###########################################################

ESC_SEQ=$'\033['
COL_RESET=$ESC_SEQ"39;49;00m"
COL_RED=$ESC_SEQ"31;01m"
COL_GREEN=$ESC_SEQ"32;01m"
COL_YELLOW=$ESC_SEQ"33;01m"
COL_BLUE=$ESC_SEQ"34;01m"
COL_MAGENTA=$ESC_SEQ"35;01m"
COL_CYAN=$ESC_SEQ"36;01m"

function ok() {
    printf '%b[ok]%b %s\n' "$COL_GREEN" "$COL_RESET" "$*"
}

function bot() {
    printf '\n%b[._.]%b - %s\n' "$COL_GREEN" "$COL_RESET" "$*"
}

function running() {
    printf '%b=>%b %s: ' "$COL_YELLOW" "$COL_RESET" "$*"
}

function action() {
    printf '\n%b[action]:%b\n => %s...\n' "$COL_YELLOW" "$COL_RESET" "$*"
}

function warn() {
    printf '%b[warning]%b %s\n' "$COL_YELLOW" "$COL_RESET" "$*"
}

function error() {
    printf '%b[error]%b %s\n' "$COL_RED" "$COL_RESET" "$*"
}
