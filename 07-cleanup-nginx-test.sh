#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 07-cleanup-nginx-test.sh
# Objectif : Supprime le pod nginx-test et le service NodePort nginx-service
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/07-cleanup-nginx-test.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "Suppression du pod nginx-test..."
kubectl delete pod nginx-test --ignore-not-found

echo "Suppression du service nginx-service..."
kubectl delete service nginx-service --ignore-not-found

echo "Nettoyage terminé."
EOF
