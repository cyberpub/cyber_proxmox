#!/bin/bash

# Tailscale Installation Function
# Compatible with Ubuntu 24.04 Server

install_tailscale() {
    local log_prefix="[TAILSCALE]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Installing Tailscale..."
    
    # Add Tailscale's package signing key and repository
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    
    # Update package list and install Tailscale
    sudo apt update
    sudo apt install -y tailscale
    
    # Enable Tailscale service
    sudo systemctl enable tailscaled
    sudo systemctl start tailscaled
    
    if [ $? -eq 0 ]; then
        echo -e "\033[0;32m${log_prefix}\033[0m Tailscale installed successfully!"
        echo -e "\033[0;32m${log_prefix}\033[0m Service status:"
        sudo systemctl status tailscaled --no-pager -l
        echo ""
        echo -e "\033[1;33m${log_prefix}\033[0m Next steps:"
        echo "  1. Run: sudo tailscale up"
        echo "  2. Visit the authentication URL provided"
        echo "  3. For subnet routing: sudo tailscale up --advertise-routes=YOUR_SUBNET"
        echo "  4. For exit node: sudo tailscale up --advertise-exit-node"
        return 0
    else
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to install Tailscale"
        return 1
    fi
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    install_tailscale
fi
