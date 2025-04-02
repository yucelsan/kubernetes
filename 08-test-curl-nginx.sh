#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 08-test-curl-nginx.sh
# Objectif : Tester l'accès à nginx via NodePort depuis l'extérieur
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/08-test-curl-nginx.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

NODE_IP="163.172.189.81"           # IP publique de ton noeud Scaleway
NODE_PORT=30090                     # NodePort configuré dans le service nginx-service

URL="http://$NODE_IP:$NODE_PORT"

echo "Test de connexion à $URL ..."
curl -I "$URL"

echo "Test terminé."
EOF
