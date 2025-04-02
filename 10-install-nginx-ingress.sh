#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 10-install-nginx-ingress.sh
# Objectif : Installer l'Ingress Controller NGINX (namespace ingress-nginx)
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/10-install-nginx-ingress.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "Installation de l'Ingress Controller NGINX..."

# Créer le namespace dédié
kubectl create namespace ingress-nginx || true

# Appliquer le manifest officiel (stable)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/cloud/deploy.yaml

# Attente du déploiement complet
echo "Attente que l'Ingress Controller soit prêt..."
kubectl rollout status deployment ingress-nginx-controller -n ingress-nginx

echo ""
echo "Ingress NGINX installé avec succès."
echo "Prochaine étape : Cert-Manager pour gérer le HTTPS avec Let's Encrypt"
EOF