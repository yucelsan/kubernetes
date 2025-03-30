#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 09-check-dashboard-access.sh
# Objectif : Vérifie si le dashboard Kubernetes est accessible via HTTPS
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/09-check-dashboard-access.sh root@$SCW_IP:/opt/k8s/

echo "🚀 Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

DASHBOARD_URL="https://kubernetes.yucelsan.fr"

echo "🌐 Vérification de l'accès au Kubernetes Dashboard..."
curl -k -I "$DASHBOARD_URL"

echo "✅ Vérification terminée."
EOF
