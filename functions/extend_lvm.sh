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
    
    # Get the main disk device and partition number
    # Find the physical volume backing the LVM
    PV_DEVICE=$(sudo pvs --noheadings -o pv_name | tr -d ' ' | head -1)
    
    if [ -z "$PV_DEVICE" ]; then
        echo -e "\033[1;33m${log_prefix}\033[0m Could not detect physical volume, trying default..."
        # Fallback: try to detect main disk
        MAIN_DISK=$(lsblk -no name,type | grep disk | head -1 | awk '{print $1}')
        PARTITION_NUM=3
        PARTITION="/dev/${MAIN_DISK}${PARTITION_NUM}"
    else
        # Extract disk name and partition number from PV device
        MAIN_DISK=$(echo "$PV_DEVICE" | sed 's/[0-9]*$//')
        PARTITION_NUM=$(echo "$PV_DEVICE" | grep -o '[0-9]*$')
        PARTITION="$PV_DEVICE"
    fi
    
    echo -e "\033[0;32m${log_prefix}\033[0m Extending partition ${PARTITION}..."
    
    # Extend the partition using parted
    echo -e "\033[0;32m${log_prefix}\033[0m Using disk: ${MAIN_DISK}, partition: ${PARTITION_NUM}"
    
    # Use growpart if available (more reliable)
    if command -v growpart >/dev/null 2>&1; then
        echo -e "\033[0;32m${log_prefix}\033[0m Using growpart to extend partition..."
        sudo growpart ${MAIN_DISK} ${PARTITION_NUM}
    else
        echo -e "\033[0;32m${log_prefix}\033[0m Using parted to extend partition..."
        sudo parted ${MAIN_DISK} ---pretend-input-tty <<EOF
resizepart ${PARTITION_NUM}
100%
Yes
quit
EOF
    fi

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
