#!/bin/bash

# Timezone Configuration Function
# Compatible with Ubuntu 24.04 Server

configure_timezone() {
    local timezone="${1:-America/Montreal}"
    local log_prefix="[TIMEZONE]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Configuring timezone to ${timezone}..."
    
    # Set timezone
    sudo timedatectl set-timezone "$timezone"
    
    # Verify timezone was set
    local current_timezone=$(timedatectl show --property=Timezone --value)
    
    if [[ "$current_timezone" == "$timezone" ]]; then
        echo -e "\033[0;32m${log_prefix}\033[0m Timezone successfully set to ${current_timezone}"
        echo -e "\033[0;32m${log_prefix}\033[0m Current time: $(date)"
        return 0
    else
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to set timezone"
        return 1
    fi
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_timezone "$@"
fi
