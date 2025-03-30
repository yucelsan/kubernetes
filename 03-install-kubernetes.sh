#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 03-install-kubernetes.sh
# Objectif : Installer les composants de base de Kubernetes :
#            kubeadm (init cluster), kubelet (agent node), kubectl (CLI)
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/03-install-kubernetes.sh root@$SCW_IP:/opt/k8s/

echo "🚀 Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

# 1. Ajouter la clé GPG
echo "Ajouter la clé GPG"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo tee /etc/apt/keyrings/kubernetes-apt-keyring.asc > /dev/null

# 2. Ajouter le dépôt APT (officiel pour Kubernetes >=1.27)
echo "Ajouter le dépôt APT (officiel pour Kubernetes >=1.27)"
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.asc] https://pkgs.k8s.io/core:/stable:/v1.32/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "Update KUBERNETES en cours"
sudo apt update
sudo apt install -y kubelet kubeadm kubectl

# Marquer comme "hold" pour éviter upgrade accidentel
echo "Marquer comme hold pour éviter upgrade accidentel"
sudo apt-mark hold kubelet kubeadm kubectl

# Vérifications
echo "✅ kubelet version: $(kubelet --version)"
echo "✅ kubeadm version: $(kubeadm version -o short)"
echo "✅ kubectl version:$(kubectl version)"

EOF
