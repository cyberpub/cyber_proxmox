#!/bin/bash

# SSH Key Generation Function
# Compatible with Ubuntu 24.04 Server

generate_ssh_key() {
    local key_type="${1:-rsa}"
    local key_size="${2:-4096}"
    local key_file="${3:-~/.ssh/id_rsa}"
    local log_prefix="[SSH]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Generating SSH key..."
    
    # Expand tilde to home directory
    key_file="${key_file/#\~/$HOME}"
    
    # Create .ssh directory if it doesn't exist
    mkdir -p "$(dirname "$key_file")"
    
    # Check if key already exists
    if [ -f "$key_file" ]; then
        echo -e "\033[1;33m${log_prefix}\033[0m SSH key already exists at $key_file, skipping generation"
        return 0
    fi
    
    # Generate SSH key
    ssh-keygen -t "$key_type" -b "$key_size" -f "$key_file" -N ""
    
    if [ $? -eq 0 ]; then
        echo -e "\033[0;32m${log_prefix}\033[0m SSH key generated successfully at $key_file"
        echo -e "\033[0;32m${log_prefix}\033[0m Public key:"
        cat "${key_file}.pub"
        return 0
    else
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to generate SSH key"
        return 1
    fi
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    generate_ssh_key "$@"
fi
