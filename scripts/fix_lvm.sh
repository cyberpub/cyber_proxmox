#!/bin/bash

# Script de diagnostic et correction LVM
# Pour étendre le disque de 40GB à 80GB

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

show_current_state() {
    echo "🔍 État actuel du système :"
    echo ""
    
    echo "📊 Espace disque :"
    df -h /
    echo ""
    
    echo "💾 Volumes physiques :"
    sudo pvs
    echo ""
    
    echo "📦 Groupes de volumes :"
    sudo vgs
    echo ""
    
    echo "📁 Volumes logiques :"
    sudo lvs
    echo ""
    
    echo "🔧 Partitions :"
    lsblk
    echo ""
}

extend_lvm_manual() {
    log_step "Extension manuelle du LVM..."
    
    # Détecter le disque principal
    MAIN_DISK=$(lsblk -no pkname $(df / | tail -1 | awk '{print $1}') | head -1)
    if [ -z "$MAIN_DISK" ]; then
        MAIN_DISK="sda"  # Fallback
    fi
    
    log_info "Disque principal détecté : /dev/$MAIN_DISK"
    
    # Détecter la partition LVM
    PV_DEVICE=$(sudo pvs --noheadings -o pv_name | tr -d ' ' | head -1)
    if [ -z "$PV_DEVICE" ]; then
        log_error "Impossible de détecter le volume physique"
        return 1
    fi
    
    log_info "Volume physique : $PV_DEVICE"
    
    # Extraire le numéro de partition
    PARTITION_NUM=$(echo "$PV_DEVICE" | grep -o '[0-9]*$')
    log_info "Numéro de partition : $PARTITION_NUM"
    
    # 1. Étendre la partition avec parted
    log_step "Extension de la partition $PARTITION_NUM sur /dev/$MAIN_DISK..."
    
    sudo parted /dev/$MAIN_DISK --script resizepart $PARTITION_NUM 100%
    
    if [ $? -eq 0 ]; then
        log_info "✅ Partition étendue avec succès"
    else
        log_warn "⚠️ Échec avec parted, essai avec growpart..."
        
        # Installer cloud-guest-utils si pas présent
        if ! command -v growpart >/dev/null 2>&1; then
            log_info "Installation de cloud-guest-utils..."
            sudo apt update && sudo apt install -y cloud-guest-utils
        fi
        
        sudo growpart /dev/$MAIN_DISK $PARTITION_NUM
    fi
    
    # 2. Redimensionner le volume physique
    log_step "Redimensionnement du volume physique..."
    sudo pvresize $PV_DEVICE
    
    # 3. Étendre le volume logique
    log_step "Extension du volume logique..."
    sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    
    # 4. Redimensionner le système de fichiers
    log_step "Redimensionnement du système de fichiers..."
    sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
    
    log_info "✅ Extension LVM terminée !"
}

main() {
    echo "🔧 =================================="
    echo "🔧  Correction Extension LVM"
    echo "🔧  Objectif: 40GB → 80GB"
    echo "🔧 =================================="
    echo ""
    
    show_current_state
    
    echo -n "🤔 Voulez-vous procéder à l'extension ? (y/N): "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])
            echo "✅ Extension confirmée !"
            ;;
        *)
            echo "❌ Extension annulée."
            exit 0
            ;;
    esac
    
    extend_lvm_manual
    
    echo ""
    echo "🎉 Extension terminée ! Nouvel état :"
    df -h /
    echo ""
    echo "💡 Vérifiez que vous avez maintenant ~80GB disponibles"
}

main "$@"
