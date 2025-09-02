#!/bin/bash

# Swap Configuration Function
# Compatible with Ubuntu 24.04 Server

configure_swap() {
    local swap_size="${1:-2G}"
    local swap_file="${2:-/swapfile}"
    local swappiness="${3:-10}"
    local log_prefix="[SWAP]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Configuring ${swap_size} swap file..."
    
    # Check if swap already exists
    if swapon --show | grep -q "$swap_file"; then
        echo -e "\033[1;33m${log_prefix}\033[0m Swap file already exists at $swap_file, skipping creation"
        return 0
    fi
    
    # Create swap file
    sudo fallocate -l "$swap_size" "$swap_file"
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to create swap file"
        return 1
    fi
    
    # Set permissions
    sudo chmod 600 "$swap_file"
    
    # Make swap
    sudo mkswap "$swap_file"
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to format swap file"
        return 1
    fi
    
    # Enable swap
    sudo swapon "$swap_file"
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to enable swap"
        return 1
    fi
    
    # Make swap permanent
    if ! grep -q "$swap_file" /etc/fstab; then
        echo "$swap_file none swap sw 0 0" | sudo tee -a /etc/fstab
    fi
    
    # Optimize swap usage
    echo "vm.swappiness=$swappiness" | sudo tee -a /etc/sysctl.conf
    echo 'vm.vfs_cache_pressure=50' | sudo tee -a /etc/sysctl.conf
    
    echo -e "\033[0;32m${log_prefix}\033[0m ${swap_size} swap file created and configured"
    echo -e "\033[0;32m${log_prefix}\033[0m Swappiness set to $swappiness"
    
    return 0
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_swap "$@"
fi
