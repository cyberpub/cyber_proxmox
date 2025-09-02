# Cyber Proxmox

🚀 Collection de scripts d'installation spécialisés pour machines virtuelles Ubuntu 24.04 sur Proxmox

## 📋 Description

Ce projet fournit une collection de scripts d'installation modulaires qui configurent automatiquement des VMs Ubuntu 24.04 selon différents cas d'usage. Chaque script est optimisé pour un rôle spécifique dans votre infrastructure.

## 🎯 Scripts disponibles

### 🐍 Django VM (`scripts/django.sh`)
**Parfait pour :** Applications web Django avec Docker Compose

**Fonctionnalités :**
- ✅ **Base système** - Mise à jour complète Ubuntu 24.04
- ✅ **Docker & Docker Compose** - Installation complète (plugin + binaire)
- ✅ **Extension de disque** - Détection et extension automatique LVM
- ✅ **Clés SSH** - Génération RSA 4096 bits sécurisées
- ✅ **Répertoire Docker** - Dossier `~/docker/` pour vos projets Django
- ✅ **Alias réseau** - Commande `myip` pour diagnostics réseau

### 🔒 Tailscale VM (`scripts/tailscale.sh`)
**Parfait pour :** VPN mesh, subnet routing et proxy réseau

**Fonctionnalités :**
- ✅ **Base système** - Mise à jour complète Ubuntu 24.04
- ✅ **Tailscale** - Installation et configuration VPN mesh
- ✅ **Subnet Router** - Configuration pour router les subnets
- ✅ **Exit Node** - Capacité de servir de proxy/exit node
- ✅ **Firewall UFW** - Règles de sécurité optimisées
- ✅ **Outils réseau** - Diagnostics et surveillance réseau
- ✅ **Scripts helper** - Commandes simplifiées (ts-setup, net-diag)

## 🚀 Installation rapide

### 🐍 Pour une VM Django

**Méthode 1 : Installation directe (recommandée)**
```bash
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/django.sh | bash
```

**Méthode 2 : Téléchargement puis exécution**
```bash
wget https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/django.sh
chmod +x django.sh
./django.sh
```

### 🔒 Pour une VM Tailscale

**Méthode 1 : Installation directe (recommandée)**
```bash
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/tailscale.sh | bash
```

**Méthode 2 : Téléchargement puis exécution**
```bash
wget https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/tailscale.sh
chmod +x tailscale.sh
./tailscale.sh
```

## 🔧 Prérequis

### Communs à toutes les VMs
- **OS** : Ubuntu 24.04 Server (fraîchement installé)
- **Accès** : Utilisateur avec privilèges sudo
- **Réseau** : Connexion Internet active
- **Proxmox** : VM avec espace disque étendu si nécessaire

### Spécifiques Django VM
- **RAM** : Minimum 2GB (4GB recommandés)
- **Stockage** : 20GB minimum pour les conteneurs
- **Ports** : 80, 443, 8000 (selon vos projets)

### Spécifiques Tailscale VM
- **RAM** : Minimum 1GB (2GB recommandés pour subnet routing)
- **Réseau** : Accès aux subnets à router
- **Ports** : 41641 (UDP) pour Tailscale
- **Permissions** : Accès admin pour configuration firewall

## 📖 Utilisation

### 🐍 Django VM - Après installation

1. **Redémarrez votre session** pour activer Docker sans sudo :
   ```bash
   logout
   # Puis reconnectez-vous
   ```

2. **Testez votre installation** :
   ```bash
   docker --version
   docker compose version
   docker-compose --version
   myip
   df -h
   ```

3. **Créez votre premier projet Django** :
   ```bash
   cd ~/docker
   mkdir mon-projet-django
   cd mon-projet-django
   # Créez votre docker-compose.yml ici
   ```

4. **Récupérez votre clé SSH publique** :
   ```bash
   cat ~/.ssh/id_rsa.pub
   ```

### 🔒 Tailscale VM - Après installation

1. **Redémarrez votre session** pour activer les alias :
   ```bash
   logout
   # Puis reconnectez-vous
   ```

2. **Configuration initiale Tailscale** :
   ```bash
   # Aide à la configuration
   ts-setup
   
   # Démarrage basique
   sudo tailscale up
   # Suivez le lien d'authentification dans votre navigateur
   ```

3. **Configuration subnet router** (pour router votre réseau local) :
   ```bash
   # Remplacez par votre subnet réel
   sudo tailscale up --advertise-routes=192.168.1.0/24
   ```

4. **Configuration exit node** (pour servir de proxy) :
   ```bash
   sudo tailscale up --advertise-exit-node
   ```

5. **Vérifiez votre installation** :
   ```bash
   tsstatus        # Statut Tailscale
   tsip            # Votre IP Tailscale
   net-diag        # Diagnostics réseau complets
   ```

### Commandes utiles communes

- **myip** : Affiche les adresses IP (par défaut filtre sur "10")
  ```bash
  myip        # Affiche les IPs contenant "10"
  myip 192    # Affiche les IPs contenant "192"
  ```

- **Docker** (Django VM) : Utilisable sans sudo après reconnexion
  ```bash
  docker run hello-world
  docker compose up -d
  ```

- **Tailscale** (Tailscale VM) : Commandes spécialisées
  ```bash
  ts-setup        # Guide de configuration
  tsstatus        # Statut du réseau Tailscale
  tsip            # Votre IP Tailscale
  tsroutes        # Routes annoncées
  net-diag        # Diagnostics réseau complets
  ports           # Ports en écoute
  ```

## 🛠️ Détails techniques

### Structure du projet

```
cyber_proxmox/
├── scripts/
│   ├── django.sh       # Script pour VMs Django
│   └── tailscale.sh    # Script pour VMs Tailscale
└── readme.md          # Cette documentation
```

### Composants installés

#### 🐍 Django VM (`django.sh`)
| Composant | Version | Description |
|-----------|---------|-------------|
| Docker Engine | Latest | Moteur de conteneurisation |
| Docker Compose Plugin | Latest | Orchestration de conteneurs (commande `docker compose`) |
| Docker Compose Binary | Latest | Version standalone (commande `docker-compose`) |
| SSH Keys | RSA 4096 | Clés de sécurité pour connexions distantes |
| Répertoire Docker | ~/docker/ | Espace de travail pour projets Django |

#### 🔒 Tailscale VM (`tailscale.sh`)
| Composant | Version | Description |
|-----------|---------|-------------|
| Tailscale | Latest | Client VPN mesh avec subnet routing |
| UFW Firewall | Default | Pare-feu configuré pour Tailscale |
| SSH Keys | RSA 4096 | Clés de sécurité pour connexions distantes |
| Network Tools | Various | net-tools, iptables, htop, ncdu, jq |
| Helper Scripts | Custom | ts-setup, net-diag pour gestion simplifiée |
| IP Forwarding | Enabled | Configuration pour subnet router/exit node |

### Extension de disque

Le script détecte automatiquement si votre VM utilise LVM (Logical Volume Manager) et procède à l'extension :

1. **Détection** du volume logique Ubuntu (`/dev/mapper/ubuntu--vg-ubuntu--lv`)
2. **Extension** de la partition principale
3. **Redimensionnement** du volume physique (`pvresize`)
4. **Extension** du volume logique (`lvextend`)
5. **Redimensionnement** du système de fichiers (`resize2fs`)

## 🔍 Dépannage

### Problèmes courants - Django VM

**Docker : permission denied**
```bash
# Solution : Ajoutez votre utilisateur au groupe docker
sudo usermod -aG docker $USER
# Puis déconnectez-vous et reconnectez-vous
```

**Extension de disque échouée**
```bash
# Vérifiez votre configuration LVM
lsblk
sudo pvdisplay
sudo lvdisplay
```

**Docker Compose ne trouve pas les fichiers**
```bash
# Vérifiez que vous êtes dans le bon répertoire
pwd
ls -la
# Le docker-compose.yml doit être dans le répertoire courant
```

### Problèmes courants - Tailscale VM

**Tailscale ne se connecte pas**
```bash
# Vérifiez le statut
sudo tailscale status
# Redémarrez le service
sudo systemctl restart tailscaled
# Vérifiez les logs
sudo journalctl -u tailscaled -f
```

**Subnet routing ne fonctionne pas**
```bash
# Vérifiez les routes annoncées
sudo tailscale status --peers
# Vérifiez le forwarding IP (déjà configuré par le script)
cat /proc/sys/net/ipv4/ip_forward
# Redémarrez Tailscale avec les routes
sudo tailscale up --advertise-routes=192.168.1.0/24
```

**Exit node ne fonctionne pas**
```bash
# Vérifiez la configuration exit node
sudo tailscale up --advertise-exit-node
# Vérifiez le firewall
sudo ufw status
# Testez la connectivité
curl -4 ifconfig.me
```

**Problème de firewall**
```bash
# Réinitialisez les règles UFW pour Tailscale
sudo ufw delete allow 41641/udp
sudo ufw allow 41641/udp
sudo ufw route allow in on tailscale0
sudo ufw route allow out on tailscale0
```

### Problèmes généraux

**Clé SSH non générée**
```bash
# Génération manuelle
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```

### Logs et débogage

Tous les scripts affichent des messages colorés :
- 🟢 **[INFO]** : Opérations réussies
- 🟡 **[WARN]** : Avertissements non critiques  
- 🔴 **[ERROR]** : Erreurs critiques

## 🏗️ Roadmap

### ✅ Terminé
- [x] Script Django VM avec Docker
- [x] Script Tailscale VM avec subnet routing
- [x] Documentation modulaire complète
- [x] Extension automatique LVM
- [x] Scripts helper pour Tailscale

### 🔄 En cours
- [ ] Tests sur différentes configurations Proxmox
- [ ] Optimisations performances réseau

### 📋 Prévu
- [ ] Script pour VM de monitoring (Prometheus/Grafana)
- [ ] Script pour VM de base de données (PostgreSQL/MySQL)
- [ ] Script pour VM de reverse proxy (Nginx/Traefik)
- [ ] Templates Terraform pour Proxmox

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Forker le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/nouvelle-vm`)
3. Commiter vos changements (`git commit -am 'Ajout VM XYZ'`)
4. Pousser vers la branche (`git push origin feature/nouvelle-vm`)
5. Ouvrir une Pull Request

### Ajouter un nouveau script VM

Pour ajouter un nouveau type de VM :

1. Créez `scripts/nom-vm.sh` basé sur `django.sh`
2. Adaptez les installations spécifiques
3. Mettez à jour cette documentation
4. Ajoutez les commandes de test appropriées

## 📝 Licence

Ce projet est sous licence libre. Utilisez-le comme bon vous semble !

## 🔗 Liens utiles

- [Documentation Docker](https://docs.docker.com/)
- [Documentation Proxmox](https://pve.proxmox.com/wiki/Main_Page)
- [Ubuntu 24.04 LTS](https://ubuntu.com/download/server)

---

**Développé avec ❤️ pour simplifier vos déploiements Proxmox**
