#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 02-install-containerd.sh
# Objectif : Installer containerd (runtime de conteneurs léger) pour Kubernetes
# Pourquoi : Kubernetes utilise un container runtime (containerd recommandé)
# Auteur : YUCELSAN
# -----------------------------------------------------------------------------

# Répertoires
SCRIPT_DIR="$(dirname "$0")"
LOG_DIR="$SCRIPT_DIR/logs_copy_script"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/log-scaleway-$(date +%Y%m%d-%H%M%S).txt"

# Charger les variables d'environnement
source "$SCRIPT_DIR/.env"

# Logger stdout + stderr
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Copie du script en temps réel de dedibox vers scaleway"
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/02-install-containerd.sh root@$SCW_IP:/opt/k8s/

echo "🚀 Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "📦 Installation de containerd en cours..."

# Mettre à jour les paquets et installer les dépendances de base
echo "Mise à jour des paquets et installation des dépendances de base"
sudo apt update && sudo apt install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Ajout de la clé GPG du dépôt Docker (qui contient containerd)
echo "Ajout de la clé GPG du dépôt Docker (qui contient containerd)"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Ajout du dépôt Docker (pour containerd)
echo "Ajout du dépôt Docker (pour containerd)"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Mise à jour et installation de containerd
echo "Mise à jour et installation de containerd"
sudo apt update
sudo apt install -y containerd.io

# Configuration par défaut de containerd
echo "Configuration par défaut de containerd"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null

# Modification du driver cgroup pour utiliser systemd (recommandé par kubeadm)
echo "Modification du driver cgroup pour utiliser systemd (recommandé par kubeadm)"
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

# Redémarrer et activer containerd
echo "Redémarrage et activation containerd permanent"
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "✅ containerd est installé et configuré avec systemd comme driver cgroup."
EOF