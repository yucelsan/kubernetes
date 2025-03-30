#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 61-deploy-nginx-stable.sh
# Objectif : Déployer une app NGINX via Deployment + Service NodePort
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/61-deploy-nginx-stable.sh root@$SCW_IP:/opt/k8s/

echo "🚀 Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

APP_NAME="nginx-devops"
NODE_PORT=30090

echo "📦 Création du Deployment NGINX..."

kubectl create deployment $APP_NAME --image=nginx

echo "⏳ Attente que le pod soit prêt..."
kubectl rollout status deployment/$APP_NAME

sleep 5

echo "🌐 Création du Service NodePort (port externe : $NODE_PORT)..."

kubectl expose deployment $APP_NAME \
  --type=NodePort \
  --port=80 \
  --name=${APP_NAME}-service \
  --overrides="
{
  \"spec\": {
    \"ports\": [
      {
        \"port\": 80,
        \"targetPort\": 80,
        \"nodePort\": $NODE_PORT
      }
    ]
  }
}"

echo "🔍 Récupération des informations..."

CLUSTER_IP=$(kubectl get svc ${APP_NAME}-service -o=jsonpath='{.spec.clusterIP}')
NODE_IP=$(curl -s ifconfig.me)

echo ""
echo "✅ NGINX est déployé avec succès !"
echo "🌍 Accès externe : http://$NODE_IP:$NODE_PORT"
echo "🔐 Accès interne ClusterIP : http://$CLUSTER_IP:80"
echo ""

kubectl get pods -l app=$APP_NAME -o wide
kubectl get svc ${APP_NAME}-service
EOF
