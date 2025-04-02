#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 06-deploy-nginx-test.sh
# Objectif : Déployer un pod NGINX et l’exposer via un Service NodePort
# But : Valider que le cluster fonctionne et est accessible de l’extérieur
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/06-deploy-nginx-test.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "Déploiement du pod NGINX..."

sleep 5

# Déploiement du pod

kubectl run nginx-test \
  --image=nginx \
  --port=80 \
  --restart=Never

sleep 5

# Création du service NodePort
echo "Création du service NodePort..."

kubectl expose pod nginx-test \
  --type=NodePort \
  --port=80 \
  --name=nginx-service \
  --overrides='
{
  "spec": {
    "ports": [
      {
        "port": 80,
        "targetPort": 80,
        "nodePort": 30080
      }
    ]
  }
}'

sleep 5

# Récupération des informations de service

echo "Récupération des infos de service..."

NODE_PORT=$(kubectl get svc nginx-service -o=jsonpath='{.spec.ports[0].nodePort}')

NODE_IP=$(curl -s ifconfig.me)

sleep 5

echo ""
echo "NGINX est déployé et exposé !"
echo "Accède à ton pod via l’URL suivante :"
echo "http://$NODE_IP:$NODE_PORT"
echo ""

# Affichage du statut du pod
kubectl get pod nginx-test -o wide
kubectl get svc nginx-service
EOF
