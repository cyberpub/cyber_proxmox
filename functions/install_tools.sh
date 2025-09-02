#!/bin/bash

# System Tools Installation Function
# Compatible with Ubuntu 24.04 Server

install_essential_tools() {
    local log_prefix="[TOOLS]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Installing essential tools..."
    
    # Essential system tools
    local tools=(
        "htop"          # System monitoring
        "curl"          # HTTP client
        "wget"          # File downloader
        "net-tools"     # Network utilities
        "tree"          # Directory tree viewer
        "ncdu"          # Disk usage analyzer
        "git"           # Version control
        "nano"          # Text editor
        "vim"           # Advanced text editor
        "unzip"         # Archive extractor
        "jq"            # JSON processor
    )
    
    # Install tools
    sudo apt install -y "${tools[@]}"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[0;32m${log_prefix}\033[0m Essential tools installed successfully"
        return 0
    else
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to install some tools"
        return 1
    fi
}

install_network_tools() {
    local log_prefix="[NET-TOOLS]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Installing network diagnostic tools..."
    
    # Network diagnostic tools
    local tools=(
        "tcpdump"       # Network packet analyzer
        "nmap"          # Network scanner
        "traceroute"    # Network path tracer
        "dnsutils"      # DNS utilities
        "iotop"         # I/O monitoring
        "nethogs"       # Network bandwidth monitor
        "iftop"         # Network interface monitor
        "vnstat"        # Network statistics
    )
    
    # Install tools
    sudo apt install -y "${tools[@]}"
    
    if [ $? -eq 0 ]; then
        echo -e "\033[0;32m${log_prefix}\033[0m Network tools installed successfully"
        return 0
    else
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to install some network tools"
        return 1
    fi
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-essential}" in
        "essential")
            install_essential_tools
            ;;
        "network")
            install_network_tools
            ;;
        "all")
            install_essential_tools
            install_network_tools
            ;;
        *)
            echo "Usage: $0 [essential|network|all]"
            exit 1
            ;;
    esac
fi
