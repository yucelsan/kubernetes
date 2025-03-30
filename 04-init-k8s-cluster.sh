#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 04-init-k8s-cluster.sh
# Objectif : Initialiser le cluster Kubernetes avec kubeadm
# - Configure le control-plane
# - Génère le fichier kubeconfig pour kubectl
# - Option : autoriser le master à scheduler des pods
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/04-init-k8s-cluster.sh root@$SCW_IP:/opt/k8s/

echo "🚀 Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

# CIDR pour le réseau pod (doit correspondre à Calico ensuite)
POD_CIDR="192.168.0.0/16"

echo "🚀 Initialisation du cluster Kubernetes avec kubeadm..."

# Initialiser le cluster
sudo kubeadm init --pod-network-cidr="$POD_CIDR" --kubernetes-version "$(kubeadm version -o short)"

echo "✅ kubeadm init terminé."

# Configurer kubectl pour l'utilisateur actuel
echo "📂 Configuration de kubectl (kubeconfig)..."
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# (Optionnel) Autoriser les pods à s'exécuter sur le master
echo "⚙️ Autorisation du scheduling de pods sur le master..."
kubectl taint nodes --all node-role.kubernetes.io/control-plane- || true

# Résumé
echo "✅ Cluster initialisé avec succès."
echo "🌐 Prochaine étape : déployer le CNI (Calico)"
echo "➡️ Tu peux exécuter ensuite 05-install-cni-calico.sh"
EOF