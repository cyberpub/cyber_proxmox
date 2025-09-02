#!/bin/bash

# Aliases Configuration Function
# Compatible with Ubuntu 24.04 Server

configure_aliases() {
    local alias_type="${1:-standard}"
    local log_prefix="[ALIASES]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Adding useful aliases..."
    
    # Standard aliases for all VMs
    local standard_aliases="
# Network and system aliases
alias myip='function _myip(){ ip a | grep \${1:-10}; }; _myip'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'
alias h='htop'
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ports='ss -tulpn'
alias psg='ps aux | grep'
alias hg='history | grep'
"

    # Tailscale specific aliases
    local tailscale_aliases="
# Tailscale aliases
alias ts='tailscale'
alias tsstatus='tailscale status'
alias tsip='tailscale ip'
alias tsroutes='tailscale status --peers'
alias netstat-listen='netstat -tlnp'
"

    # Docker specific aliases
    local docker_aliases="
# Docker aliases
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dex='docker exec -it'
"

    # Choose aliases based on type
    local aliases_to_add="$standard_aliases"
    
    case "$alias_type" in
        "tailscale")
            aliases_to_add="$standard_aliases$tailscale_aliases"
            ;;
        "django"|"docker")
            aliases_to_add="$standard_aliases$docker_aliases"
            ;;
        "all")
            aliases_to_add="$standard_aliases$tailscale_aliases$docker_aliases"
            ;;
    esac
    
    # Add to .bashrc if not already present
    if ! grep -q "alias myip=" ~/.bashrc; then
        echo "" >> ~/.bashrc
        echo "# Custom aliases - Added by cyber_proxmox" >> ~/.bashrc
        echo "$aliases_to_add" >> ~/.bashrc
        echo -e "\033[0;32m${log_prefix}\033[0m Aliases added to ~/.bashrc"
    else
        echo -e "\033[1;33m${log_prefix}\033[0m Aliases already exist in ~/.bashrc"
    fi
    
    # Add to current session
    eval "alias myip='function _myip(){ ip a | grep \${1:-10}; }; _myip'"
    
    return 0
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_aliases "$@"
fi
