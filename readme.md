# Cyber Proxmox

🚀 Framework modulaire d'installation et de gestion pour machines virtuelles Ubuntu 24.04 sur Proxmox

## 📋 Description

Ce projet fournit un framework complet avec des scripts modulaires et des utilitaires de conteneurs pour automatiser le déploiement et la gestion d'infrastructure sur Proxmox. L'architecture modulaire permet une maintenance facile et une réutilisabilité maximale.

## 🏗️ Architecture modulaire

### 📁 **Structure du projet**

```
cyber_proxmox/
├── scripts/                    # Scripts d'installation principaux
│   ├── django.sh              # Installation VM Django (modulaire)
│   ├── tailscale.sh           # Installation VM Tailscale (modulaire)
│   └── proxmox.sh             # Installation Cloudflare Tunnel sur Proxmox
├── functions/                  # Modules fonctionnels réutilisables
│   ├── install_docker.sh      # Installation Docker
│   ├── configure_timezone.sh  # Configuration timezone
│   ├── generate_ssh_key.sh    # Génération clés SSH
│   ├── configure_swap.sh      # Configuration swap
│   ├── extend_lvm.sh          # Extension LVM
│   ├── install_tools.sh       # Installation outils système
│   └── configure_aliases.sh   # Configuration aliases
├── container_scripts/          # Générateurs de stacks Docker
│   ├── django_stack.sh        # Stack Django complète
│   ├── monitoring_stack.sh    # Stack Prometheus/Grafana
│   ├── database_stack.sh      # Stacks PostgreSQL/MySQL/Redis
│   ├── proxy_stack.sh         # Stacks Nginx/Traefik
│   └── cloudflared_stack.sh   # Stack Cloudflare Tunnel containerisé
└── readme.md                  # Cette documentation
```

## 🎯 Scripts d'installation VM

### 🐍 **Django VM** (`scripts/django.sh`)
**Parfait pour :** Applications web Django avec écosystème complet

**Fonctionnalités :**
- ✅ **Architecture modulaire** - Utilise les fonctions réutilisables
- ✅ **Base système** - Ubuntu 24.04 + timezone Montreal
- ✅ **Outils développement** - htop, git, nano, vim, curl, wget, tree, ncdu
- ✅ **Docker complet** - Engine + Compose (plugin + binaire)
- ✅ **Optimisations** - LVM extension + swap 2GB optimisé
- ✅ **Sécurité** - Clés SSH RSA 4096 + aliases pratiques
- ✅ **Intégration** - Accès direct aux container_scripts

### 🔒 **Tailscale VM** (`scripts/tailscale.sh`)
**Parfait pour :** VPN mesh, subnet routing et sécurité réseau

**Fonctionnalités :**
- ✅ **Architecture modulaire** - Fonctions réseau spécialisées
- ✅ **Tailscale complet** - VPN mesh + subnet router + exit node
- ✅ **Outils réseau** - tcpdump, nmap, iotop, nethogs, iftop, vnstat
- ✅ **Sécurité** - UFW configuré + IP forwarding + SSH
- ✅ **Helpers** - Scripts ts-setup et net-diag intégrés
- ✅ **Monitoring** - Diagnostics réseau avancés

### ☁️ **Proxmox Cloudflare** (`scripts/proxmox.sh`)
**Parfait pour :** Installation Cloudflare Tunnel directement sur l'OS Proxmox

**Fonctionnalités :**
- ✅ **Installation native** - Cloudflared installé sur l'OS Proxmox
- ✅ **Service systemd** - Gestion avec systemctl
- ✅ **Configuration automatique** - Token Cloudflare intégré
- ✅ **Validation** - Vérification du statut et de la santé
- ✅ **Documentation** - Aide et instructions complètes

## 🚀 Installation rapide

### 🐍 **Django VM**

```bash
# Installation directe
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/django.sh | bash

# Ou téléchargement puis exécution
wget https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/django.sh
chmod +x django.sh
./django.sh
```

### 🔒 **Tailscale VM**

```bash
# Installation directe
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/tailscale.sh | bash

# Ou téléchargement puis exécution
wget https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/scripts/tailscale.sh
chmod +x tailscale.sh
./tailscale.sh
```

### 🔧 **Utilisation des fonctions individuelles**

```bash
# Installer seulement Docker
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/functions/install_docker.sh | bash

# Configurer seulement le timezone
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/functions/configure_timezone.sh | bash

# Générer seulement les clés SSH
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/functions/generate_ssh_key.sh | bash
```

## 🐳 Container Scripts - Stacks prêtes à l'emploi

### 🐍 **Django Stack** - Environnement de développement complet

```bash
# Créer une stack Django complète
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/django_stack.sh | bash -s my-django-project

# Contenu généré :
# ├── docker-compose.yml    # Django + PostgreSQL + Redis + Nginx
# ├── Dockerfile           # Image Django optimisée
# ├── requirements.txt     # Dépendances Python
# ├── nginx.conf          # Configuration reverse proxy
# ├── manage.sh           # Script de gestion (start/stop/logs/migrate)
# └── .env.example        # Variables d'environnement
```

### 📊 **Monitoring Stack** - Prometheus + Grafana

```bash
# Créer une stack de monitoring
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/monitoring_stack.sh | bash -s monitoring

# Services inclus :
# - Prometheus (http://localhost:9090)
# - Grafana (http://localhost:3000 - admin/admin123)
# - Node Exporter (métriques système)
# - cAdvisor (métriques conteneurs)
```

### 🗄️ **Database Stacks** - PostgreSQL, MySQL, Redis

```bash
# PostgreSQL + pgAdmin
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/database_stack.sh | bash -s postgresql

# MySQL + phpMyAdmin
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/database_stack.sh | bash -s mysql

# Redis + Redis Commander
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/database_stack.sh | bash -s redis
```

### 🌐 **Proxy Stacks** - Nginx ou Traefik

```bash
# Nginx reverse proxy + Let's Encrypt
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/proxy_stack.sh | bash -s nginx

# Traefik avec dashboard et SSL automatique
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/proxy_stack.sh | bash -s traefik
```

### ☁️ **Cloudflare Tunnel** - Installation sur Proxmox

```bash
# Installation directe sur l'OS Proxmox (nécessite le token Cloudflare)
curl -fsSL https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/proxmox.sh | sudo bash -s YOUR_CLOUDFLARE_TOKEN

# Ou téléchargement puis exécution
wget https://raw.githubusercontent.com/cyberpub/cyber_proxmox/main/container_scripts/proxmox.sh
chmod +x proxmox.sh
sudo ./proxmox.sh YOUR_CLOUDFLARE_TOKEN
```

**Pour obtenir votre token Cloudflare :**
1. Allez sur https://one.dash.cloudflare.com/
2. Naviguez vers Zero Trust > Access > Tunnels
3. Créez un nouveau tunnel ou sélectionnez un existant
4. Copiez le token depuis la commande d'installation

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

3. **Vérifiez le timezone, swap et outils** :
   ```bash
   date                # Heure locale (Montreal)
   free -h             # Mémoire et swap
   swapon --show       # Configuration swap
   htop               # Monitoring système (alias: h)
   myip               # Adresses IP
   ```

4. **Créez votre premier projet Django** :
   ```bash
   cd ~/docker
   mkdir mon-projet-django
   cd mon-projet-django
   # Créez votre docker-compose.yml ici
   ```

5. **Récupérez votre clé SSH publique** :
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

- **Outils système** (Django VM) : Aliases pratiques
  ```bash
  h                   # htop (monitoring)
  ll                  # ls -alF (liste détaillée)
  df                  # df -h (espace disque)
  free                # free -h (mémoire)
  ports               # ss -tulpn (ports en écoute)
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

### Architecture détaillée

```
cyber_proxmox/
├── scripts/                    # Scripts d'installation VM
│   ├── django.sh              # Installation VM Django (modulaire)
│   └── tailscale.sh           # Installation VM Tailscale (modulaire)
├── functions/                  # Modules fonctionnels
│   ├── install_docker.sh      # Installation Docker complète
│   ├── configure_timezone.sh  # Configuration fuseau horaire
│   ├── generate_ssh_key.sh    # Génération clés SSH sécurisées
│   ├── configure_swap.sh      # Configuration swap optimisé
│   ├── extend_lvm.sh          # Extension volumes LVM
│   ├── install_tools.sh       # Outils système et réseau
│   └── configure_aliases.sh   # Aliases bash personnalisés
├── container_scripts/          # Générateurs de stacks
│   ├── django_stack.sh        # Stack Django + PostgreSQL + Redis + Nginx
│   ├── monitoring_stack.sh    # Stack Prometheus + Grafana + exporters
│   ├── database_stack.sh      # Stacks PostgreSQL/MySQL/Redis
│   ├── proxy_stack.sh         # Stacks Nginx/Traefik avec SSL
│   └── proxmox.sh            # Installation Cloudflare Tunnel sur Proxmox
└── readme.md                  # Documentation complète
```

### 🔧 Modules fonctionnels disponibles

| Module | Fonction | Description |
|--------|----------|-------------|
| `install_docker.sh` | `install_docker()` | Installation Docker Engine + Compose (plugin + binaire) |
| `configure_timezone.sh` | `configure_timezone(timezone)` | Configuration fuseau horaire (défaut: America/Montreal) |
| `generate_ssh_key.sh` | `generate_ssh_key(type, size, file)` | Génération clés SSH (défaut: RSA 4096) |
| `configure_swap.sh` | `configure_swap(size, file, swappiness)` | Configuration swap optimisé (défaut: 2GB) |
| `extend_lvm.sh` | `extend_lvm()` | Extension automatique volumes LVM |
| `install_tools.sh` | `install_essential_tools()` | Outils système (htop, git, curl, etc.) |
| `install_tools.sh` | `install_network_tools()` | Outils réseau (tcpdump, nmap, iftop, etc.) |
| `configure_aliases.sh` | `configure_aliases(type)` | Aliases bash (standard/django/tailscale/all) |

### 🐳 Container Scripts disponibles

| Script | Fonction | Description |
|--------|----------|-------------|
| `django_stack.sh` | `create_django_stack(name, db)` | Stack Django + PostgreSQL/MySQL + Redis + Nginx |
| `monitoring_stack.sh` | `create_monitoring_stack(name)` | Stack Prometheus + Grafana + Node Exporter + cAdvisor |
| `database_stack.sh` | `create_postgresql_stack(name)` | PostgreSQL + pgAdmin avec backup/restore |
| `database_stack.sh` | `create_mysql_stack(name)` | MySQL + phpMyAdmin avec scripts de gestion |
| `database_stack.sh` | `create_redis_stack(name)` | Redis + Redis Commander avec configuration |
| `proxy_stack.sh` | `create_nginx_stack(name)` | Nginx reverse proxy + Let's Encrypt SSL |
| `proxy_stack.sh` | `create_traefik_stack(name)` | Traefik avec dashboard + SSL automatique |
| `proxmox.sh` | `install_cloudflare_tunnel(token)` | Installation Cloudflare Tunnel sur Proxmox OS |

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
- [x] **Architecture modulaire** - Fonctions réutilisables et maintenables
- [x] **Scripts VM complets** - Django et Tailscale avec versions modulaires
- [x] **Container Scripts** - Stacks prêtes pour Django, monitoring, databases, proxy
- [x] **Documentation complète** - Guide d'utilisation et référence API
- [x] **Fonctions individuelles** - Utilisables indépendamment
- [x] **Optimisations système** - LVM, swap, timezone, sécurité

### 🔄 En cours
- [ ] Tests automatisés pour tous les modules
- [ ] CI/CD pour validation des scripts
- [ ] Métriques et monitoring des déploiements

### 📋 Prévu
- [ ] **Templates Terraform** - Infrastructure as Code pour Proxmox
- [ ] **Scripts Kubernetes** - Migration vers orchestration
- [ ] **Backup automatisé** - Sauvegarde et restauration
- [ ] **Monitoring centralisé** - Observabilité multi-VM
- [ ] **Interface web** - Dashboard de gestion
- [ ] **API REST** - Contrôle programmatique

## 🤝 Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :

1. Forker le projet
2. Créer une branche pour votre fonctionnalité (`git checkout -b feature/nouvelle-vm`)
3. Commiter vos changements (`git commit -am 'Ajout VM XYZ'`)
4. Pousser vers la branche (`git push origin feature/nouvelle-vm`)
5. Ouvrir une Pull Request

### 🔧 Ajouter de nouvelles fonctionnalités

**Créer un nouveau module fonctionnel :**

1. Créez `functions/ma_fonction.sh` avec la structure :
   ```bash
   #!/bin/bash
   ma_fonction() {
       local param1="${1:-default}"
       local log_prefix="[MA_FONCTION]"
       
       echo -e "\033[0;32m${log_prefix}\033[0m Description..."
       # Votre logique ici
       return 0
   }
   
   # Exécution directe
   if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
       ma_fonction "$@"
   fi
   ```

2. Testez individuellement : `./functions/ma_fonction.sh`
3. Intégrez dans les scripts VM principaux
4. Documentez dans le README

**Créer un nouveau container script :**

1. Créez `container_scripts/ma_stack.sh`
2. Implémentez les fonctions de génération
3. Ajoutez un script `manage.sh` pour la gestion
4. Testez la stack complète

**Créer un nouveau script VM :**

1. Créez `scripts/ma_vm.sh`
2. Sourcez les fonctions nécessaires depuis `functions/`
3. Composez votre workflow d'installation
4. Ajoutez les instructions d'installation au README

## 📝 Licence

Ce projet est sous licence libre. Utilisez-le comme bon vous semble !

## 🔗 Liens utiles

- [Documentation Docker](https://docs.docker.com/)
- [Documentation Proxmox](https://pve.proxmox.com/wiki/Main_Page)
- [Ubuntu 24.04 LTS](https://ubuntu.com/download/server)

---

**Développé avec ❤️ pour simplifier vos déploiements Proxmox**
