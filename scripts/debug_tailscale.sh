#!/bin/bash

# Script de diagnostic pour Tailscale
echo "🔍 Diagnostic du script Tailscale"
echo "================================="
echo ""

echo "📄 Vérification du script téléchargé..."
if [ -f "tailscale.sh" ]; then
    echo "✅ Fichier tailscale.sh trouvé"
    echo "📊 Taille du fichier: $(wc -c < tailscale.sh) bytes"
    echo "📏 Nombre de lignes: $(wc -l < tailscale.sh)"
    echo ""
    
    echo "🔍 Recherche de la fonction install_tailscale..."
    if grep -n "install_tailscale()" tailscale.sh; then
        echo "✅ Fonction install_tailscale trouvée"
    else
        echo "❌ Fonction install_tailscale NON trouvée"
    fi
    echo ""
    
    echo "🔍 Recherche de l'appel install_tailscale..."
    grep -n "install_tailscale$" tailscale.sh || echo "❌ Appel install_tailscale non trouvé"
    echo ""
    
    echo "📋 Contenu autour de la ligne 277..."
    sed -n '275,280p' tailscale.sh
    echo ""
    
    echo "📋 Dernières lignes du fichier..."
    tail -5 tailscale.sh
    echo ""
    
else
    echo "❌ Fichier tailscale.sh non trouvé dans le répertoire courant"
fi

echo "🌐 Vérification de la version en ligne..."
echo "URL: https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/tailscale.sh"
echo ""

echo "💡 Solution recommandée:"
echo "1. Supprimez le fichier local: rm tailscale.sh"
echo "2. Retéléchargez: wget https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/tailscale.sh"
echo "3. Rendez-le exécutable: chmod +x tailscale.sh"
echo "4. Relancez: ./tailscale.sh"
