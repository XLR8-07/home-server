#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  Terminal Colors & Styling                                    ║
# ╚══════════════════════════════════════════════════════════════╝

# Reset
export NC='\033[0m'

# Regular Colors
export BLACK='\033[0;30m'
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[0;33m'
export BLUE='\033[0;34m'
export PURPLE='\033[0;35m'
export CYAN='\033[0;36m'
export WHITE='\033[0;37m'

# Bold
export BOLD='\033[1m'
export DIM='\033[2m'
export ITALIC='\033[3m'
export UNDERLINE='\033[4m'

# Bold Colors
export BOLD_RED='\033[1;31m'
export BOLD_GREEN='\033[1;32m'
export BOLD_YELLOW='\033[1;33m'
export BOLD_BLUE='\033[1;34m'
export BOLD_PURPLE='\033[1;35m'
export BOLD_CYAN='\033[1;36m'

# Background Colors
export BG_RED='\033[41m'
export BG_GREEN='\033[42m'
export BG_YELLOW='\033[43m'
export BG_BLUE='\033[44m'

# Check if terminal supports colors
supports_colors() {
    if [ -t 1 ] && [ -n "$TERM" ] && [ "$TERM" != "dumb" ]; then
        return 0
    fi
    return 1
}

# Disable colors if not supported
if ! supports_colors; then
    NC=''
    BLACK='' RED='' GREEN='' YELLOW='' BLUE='' PURPLE='' CYAN='' WHITE=''
    BOLD='' DIM='' ITALIC='' UNDERLINE=''
    BOLD_RED='' BOLD_GREEN='' BOLD_YELLOW='' BOLD_BLUE='' BOLD_PURPLE='' BOLD_CYAN=''
    BG_RED='' BG_GREEN='' BG_YELLOW='' BG_BLUE=''
fi
