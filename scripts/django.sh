#!/bin/bash

# Cyber Proxmox Django VM Installation Script (Modular Version)
# Compatible with Ubuntu 24.04 Server
# Uses modular functions for better maintainability
# Version: 2.1.0

set -e  # Exit on any error

# Installation version and info
SCRIPT_VERSION="2.1.0"
SCRIPT_DATE="2025-09-02"

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FUNCTIONS_DIR="$(dirname "$SCRIPT_DIR")/functions"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

show_banner() {
    echo "🐍 =================================="
    echo "🐍  Cyber Proxmox Django VM Setup"
    echo "🐍  Version: $SCRIPT_VERSION ($SCRIPT_DATE)"
    echo "🐍 =================================="
    echo ""
    echo "📋 Ce script va installer :"
    echo "  ✅ Mise à jour du système"
    echo "  ✅ Configuration timezone (America/Montreal)"
    echo "  ✅ Outils essentiels (htop, curl, wget, etc.)"
    echo "  ✅ Docker & Docker Compose"
    echo "  ✅ Configuration swap (2GB)"
    echo "  ✅ Génération clé SSH"
    echo "  ✅ Répertoire ~/docker/"
    echo "  ✅ Aliases utiles (myip, ll, h, etc.)"
    echo "  ✅ Extension LVM (si disponible)"
    echo ""
}

confirm_installation() {
    # Check if we can read from terminal (not piped from curl)
    if [ -t 0 ]; then
        echo -n "🤔 Voulez-vous continuer avec l'installation ? (y/N): "
        read -r response
        case "$response" in
            [yY][eE][sS]|[yY]|[oO][uU][iI]|[oO])
                echo "✅ Installation confirmée !"
                return 0
                ;;
            *)
                echo "❌ Installation annulée."
                exit 0
                ;;
        esac
    else
        # When piped from curl, auto-confirm with a delay
        echo "🤔 Voulez-vous continuer avec l'installation ? (y/N): "
        echo "⏳ Exécution via curl détectée - démarrage automatique dans 5 secondes..."
        echo "   (Appuyez Ctrl+C pour annuler)"
        sleep 5
        echo "✅ Installation confirmée automatiquement !"
        return 0
    fi
}

init_sudo() {
    log_info "Initialisation des privilèges sudo..."
    if sudo ls /root >/dev/null 2>&1; then
        log_info "Privilèges sudo activés ✅"
    else
        log_error "Impossible d'obtenir les privilèges sudo"
        exit 1
    fi
}

# Source function modules
source_functions() {
    local functions=(
        "install_docker.sh"
        "configure_timezone.sh"
        "generate_ssh_key.sh"
        "configure_swap.sh"
        "extend_lvm.sh"
        "install_tools.sh"
        "configure_aliases.sh"
    )
    
    # Create temporary functions directory
    mkdir -p /tmp/cyber_proxmox_functions
    
    for func in "${functions[@]}"; do
        local func_path="/tmp/cyber_proxmox_functions/$func"
        
        # Download function if not already present locally
        if [ ! -f "$FUNCTIONS_DIR/$func" ] && [ ! -f "$func_path" ]; then
            log_info "Downloading function: $func"
            if curl -fsSL "https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/functions/$func" -o "$func_path"; then
                source "$func_path"
            else
                log_warn "Failed to download function: $func"
            fi
        elif [ -f "$FUNCTIONS_DIR/$func" ]; then
            # Use local version if available
            source "$FUNCTIONS_DIR/$func"
        elif [ -f "$func_path" ]; then
            # Use downloaded version
            source "$func_path"
        else
            log_warn "Function file not found: $func"
        fi
    done
}

# Main installation function
main() {
    # Show banner and get confirmation (unless --yes flag is used)
    show_banner
    
    # Check for --yes or -y flag to skip confirmation
    if [[ "$1" == "--yes" ]] || [[ "$1" == "-y" ]]; then
        echo "✅ Installation confirmée via paramètre --yes"
    else
        confirm_installation
    fi
    
    # Initialize sudo early
    init_sudo
    
    echo ""
    echo "🐍 Starting Cyber Proxmox Django VM setup (Modular)..."
    
    # Source all function modules
    log_step "Loading function modules..."
    source_functions
    
    # 1. System update and upgrade
    log_step "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    
    # 2. Configure timezone
    log_step "Configuring timezone..."
    configure_timezone "America/Montreal"
    
    # 3. Install essential tools
    log_step "Installing essential tools..."
    install_essential_tools
    
    # 4. Install Docker and Docker Compose
    log_step "Installing Docker..."
    install_docker
    
    # 5. Configure swap file
    log_step "Configuring swap..."
    configure_swap "2G" "/swapfile" "10"
    
    # 6. Generate SSH key
    log_step "Generating SSH key..."
    generate_ssh_key "rsa" "4096" "~/.ssh/id_rsa"
    
    # 7. Create Docker directory
    log_step "Creating Docker directory..."
    mkdir -p ~/docker
    log_info "Directory ~/docker/ created"
    
    # 8. Configure aliases
    log_step "Configuring aliases..."
    configure_aliases "django"
    
    # 9. Extend drive (LVM) - At the end, continue even if it fails
    log_step "Extending drive (optional)..."
    set +e  # Temporarily disable exit on error
    extend_lvm
    if [ $? -ne 0 ]; then
        log_warn "Drive extension failed or not needed, continuing..."
    fi
    set -e  # Re-enable exit on error
    
    # 10. Display installation summary
    display_summary
}

display_summary() {
    log_info "Django VM installation completed successfully! 🎉"
    echo ""
    echo "📋 Summary:"
    echo "  ✅ System updated and upgraded"
    echo "  ✅ Timezone set to America/Montreal"
    echo "  ✅ Essential tools installed (htop, curl, wget, net-tools, tree, ncdu, git, nano, vim)"
    echo "  ✅ Docker and Docker Compose installed"
    echo "  ✅ 2GB swap file configured"
    echo "  ✅ SSH key generated"
    echo "  ✅ ~/docker/ directory created"
    echo "  ✅ Useful aliases added"
    echo "  ✅ Drive extension attempted (if LVM detected)"
    echo ""
    echo "🕐 Current time: $(date)"
    echo "🌍 Timezone: $(timedatectl show --property=Timezone --value)"
    echo ""
    echo "🔑 Your SSH public key (pour GitHub Deploy Key):"
    echo "════════════════════════════════════════════════════════════════"
    cat ~/.ssh/id_rsa.pub
    echo "════════════════════════════════════════════════════════════════"
    echo ""
    echo "📋 Instructions pour GitHub Deploy Key :"
    echo "  1. Copiez la clé SSH ci-dessus"
    echo "  2. Allez sur GitHub → Settings → Deploy keys"
    echo "  3. Cliquez 'Add deploy key'"
    echo "  4. Collez la clé et donnez un nom (ex: 'Proxmox VM')"
    echo "  5. Cochez 'Allow write access' si nécessaire"
    echo ""
    echo "🔄 Please log out and log back in to use Docker without sudo and activate aliases"
    echo ""
    echo "💡 Test your installation:"
    echo "  docker --version"
    echo "  docker compose version"
    echo "  docker-compose --version"
    echo "  htop"
    echo "  myip"
    echo "  df -h"
    echo "  free -h"
    echo "  swapon --show"
    echo ""
    echo "🐍 Ready for Django development with Docker!"
    echo "  cd ~/docker"
    echo "  # Use container scripts to create stacks:"
    echo "  bash <(curl -s https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/django_stack.sh) my-project"
    echo ""
    echo "📚 Available container scripts:"
    echo "  - Django Stack: Full Django development environment"
    echo "  - Database Stack: PostgreSQL, MySQL, Redis"
    echo "  - Monitoring Stack: Prometheus + Grafana"
    echo "  - Proxy Stack: Nginx or Traefik reverse proxy"
}

# Run main function - always execute when script is run
main "$@"
