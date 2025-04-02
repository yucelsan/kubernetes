#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 11-install-cert-manager.sh
# Objectif : Installer cert-manager + ClusterIssuer (Let's Encrypt)
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/11-install-cert-manager.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "Installation de Cert-Manager..."

# Créer le namespace dédié
kubectl create namespace cert-manager || true

# Appliquer le manifest officiel
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml

echo "Attente que Cert-Manager soit prêt..."
kubectl rollout status deployment cert-manager -n cert-manager
kubectl rollout status deployment cert-manager-webhook -n cert-manager
kubectl rollout status deployment cert-manager-cainjector -n cert-manager

# Créer un ClusterIssuer (Let's Encrypt - STAGING pour test)
echo "Création du ClusterIssuer (Let's Encrypt Staging)..."

cat <<CAT_EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-staging
spec:
  acme:
    email: contact@yucelsan.fr
    server: https://acme-staging-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-staging-key
    solvers:
    - http01:
        ingress:
          class: nginx
CAT_EOF

echo "Cert-Manager installé + ClusterIssuer Let's Encrypt (Staging) prêt."
echo "Prochaine étape : créer l'Ingress HTTPS pour https://kubernetes.yucelsan.fr"
EOF
