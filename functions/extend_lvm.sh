#!/bin/bash

# LVM Extension Function
# Compatible with Ubuntu 24.04 Server

extend_lvm() {
    local log_prefix="[LVM]"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Extending drive space..."
    
    # Check if we're using LVM
    if [ ! -e /dev/mapper/ubuntu--vg-ubuntu--lv ]; then
        echo -e "\033[1;33m${log_prefix}\033[0m LVM not detected, skipping drive extension"
        return 0
    fi
    
    echo -e "\033[0;32m${log_prefix}\033[0m LVM detected, extending logical volume..."
    
    # Get the main disk device (usually sda)
    MAIN_DISK=$(lsblk -no pkname /dev/mapper/ubuntu--vg-ubuntu--lv | head -1)
    PARTITION_NUM=$(lsblk -no name /dev/mapper/ubuntu--vg-ubuntu--lv | grep -o '[0-9]*$' | head -1)
    
    if [ -z "$PARTITION_NUM" ]; then
        PARTITION_NUM=3  # Default to partition 3 for Ubuntu LVM
    fi
    
    PARTITION="/dev/${MAIN_DISK}${PARTITION_NUM}"
    
    echo -e "\033[0;32m${log_prefix}\033[0m Extending partition ${PARTITION}..."
    
    # Extend the partition using parted
    sudo parted /dev/${MAIN_DISK} ---pretend-input-tty <<EOF
resizepart ${PARTITION_NUM}
100%
Yes
quit
EOF

    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to extend partition"
        return 1
    fi

    # Resize physical volume
    sudo pvresize ${PARTITION}
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to resize physical volume"
        return 1
    fi
    
    # Extend logical volume
    sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to extend logical volume"
        return 1
    fi
    
    # Resize filesystem
    sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
    if [ $? -ne 0 ]; then
        echo -e "\033[0;31m${log_prefix}\033[0m Failed to resize filesystem"
        return 1
    fi
    
    echo -e "\033[0;32m${log_prefix}\033[0m Drive extension completed successfully!"
    
    return 0
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    extend_lvm
fi
