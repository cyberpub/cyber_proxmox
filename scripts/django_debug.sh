#!/bin/bash

# Django Debug Script - Pour diagnostiquer les problèmes

echo "🔍 Django Installation Debug Script"
echo "=================================="
echo "Timestamp: $(date)"
echo "User: $(whoami)"
echo "Working directory: $(pwd)"
echo "Arguments: $@"
echo ""

# Test basic commands
echo "📋 Testing basic commands..."
echo "Bash version: $BASH_VERSION"
echo "Curl available: $(command -v curl > /dev/null && echo "YES" || echo "NO")"
echo "Wget available: $(command -v wget > /dev/null && echo "YES" || echo "NO")"
echo "Sudo available: $(command -v sudo > /dev/null && echo "YES" || echo "NO")"

# Test sudo access
echo ""
echo "🔐 Testing sudo access..."
if sudo -n true 2>/dev/null; then
    echo "✅ Sudo access: YES (no password required)"
elif sudo -v 2>/dev/null; then
    echo "✅ Sudo access: YES (password may be required)"
else
    echo "❌ Sudo access: NO"
fi

# Test internet connectivity
echo ""
echo "🌐 Testing internet connectivity..."
if curl -s --max-time 5 https://httpbin.org/ip > /dev/null 2>&1; then
    echo "✅ Internet connectivity: YES"
else
    echo "❌ Internet connectivity: NO"
fi

# Test GitHub access
echo ""
echo "📡 Testing GitHub access..."
if curl -s --max-time 5 https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/readme.md | head -1 > /dev/null 2>&1; then
    echo "✅ GitHub access: YES"
else
    echo "❌ GitHub access: NO"
fi

# Test function download
echo ""
echo "📥 Testing function download..."
mkdir -p /tmp/test_functions
if curl -fsSL "https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/functions/install_docker.sh" -o "/tmp/test_functions/install_docker.sh" 2>/dev/null; then
    echo "✅ Function download: YES"
    echo "File size: $(ls -lh /tmp/test_functions/install_docker.sh | awk '{print $5}')"
    rm -rf /tmp/test_functions
else
    echo "❌ Function download: NO"
fi

# Test script execution step by step
echo ""
echo "🔧 Testing script execution..."

# Simulate the main script start
echo "Step 1: Script initialization..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" 2>/dev/null || SCRIPT_DIR="/tmp"
FUNCTIONS_DIR="$(dirname "$SCRIPT_DIR")/functions"
echo "SCRIPT_DIR: $SCRIPT_DIR"
echo "FUNCTIONS_DIR: $FUNCTIONS_DIR"

# Test colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}✅ Colors work${NC}"

# Test log functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

log_info "Log functions work"

# Test the problematic part
echo ""
echo "🧪 Testing the exact failing part..."

# This is where it probably fails
echo "Testing BASH_SOURCE detection..."
echo "BASH_SOURCE[0]: ${BASH_SOURCE[0]}"
echo "Comparison result: $([[ "${BASH_SOURCE[0]}" == "${0}" ]] && echo "MATCH" || echo "NO MATCH")"

echo ""
echo "🎯 Attempting to run main function simulation..."

# Simulate what the main function should do
log_step "Loading function modules..."

functions=(
    "install_docker.sh"
    "configure_timezone.sh"
    "generate_ssh_key.sh"
    "configure_swap.sh"
    "extend_lvm.sh"
    "install_tools.sh"
    "configure_aliases.sh"
)

mkdir -p /tmp/cyber_proxmox_functions

for func in "${functions[@]}"; do
    func_path="/tmp/cyber_proxmox_functions/$func"
    
    if [ ! -f "$FUNCTIONS_DIR/$func" ] && [ ! -f "$func_path" ]; then
        log_info "Would download function: $func"
        # Don't actually download in debug mode
        echo "  URL: https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/functions/$func"
    else
        echo "  Function exists locally: $func"
    fi
done

echo ""
echo "🏁 Debug completed!"
echo ""
echo "If you see this message, the basic script structure works."
echo "The issue might be in the actual function downloads or execution."
