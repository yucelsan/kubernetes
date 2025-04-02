#!/bin/bash

# -----------------------------------------------------------------------------
# Script : create-dashboard-admin.sh
# Objectif : Créer un accès administrateur au Kubernetes Dashboard
#            (ServiceAccount + ClusterRoleBinding + Token)
# Auteur : YUCELSAN
# -----------------------------------------------------------------------------

NAMESPACE="kubernetes-dashboard"
SA_NAME="admin-user"

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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/create-dashboard-admin.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "Création du ServiceAccount '$SA_NAME' dans le namespace '$NAMESPACE'..."
kubectl create serviceaccount $SA_NAME -n $NAMESPACE || echo "ServiceAccount déjà existant"

echo "Attribution du rôle cluster-admin à '$SA_NAME'..."
kubectl create clusterrolebinding ${SA_NAME}-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=${NAMESPACE}:${SA_NAME} || echo "ClusterRoleBinding déjà existant"

echo "Génération du token d'accès (compatible K8S v1.24+)..."
TOKEN=$(kubectl -n $NAMESPACE create token $SA_NAME)

echo ""
echo "Voici ton token pour te connecter au Dashboard :"
echo "-----------------------------------------------------"
echo "$TOKEN"
echo "-----------------------------------------------------"
echo ""
echo "Colle ce token dans le champ prévu sur : https://kubernetes.yucelsan.fr"
EOF
