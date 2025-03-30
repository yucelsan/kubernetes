#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 05-install-cni-calico.sh
# Objectif : Installer le réseau CNI Calico dans le cluster Kubernetes
# Pourquoi : Kubernetes a besoin d’un plugin CNI pour que les pods puissent communiquer
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/05-install-cni-calico.sh root@$SCW_IP:/opt/k8s/

echo "🚀 Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "🌐 Déploiement du réseau CNI : Calico..."

# URL officielle du manifest Calico (version stable à jour)
CALICO_URL="https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml"

# Appliquer le manifest Calico
kubectl apply -f "$CALICO_URL"
sleep 5
echo "✅ Calico a été déployé."

# Vérification en continu
echo "🔍 Surveillance des pods..."
sleep 5
echo "Appuie sur Ctrl+C quand tous les pods sont en Running"
watch kubectl get pods -A
EOF


