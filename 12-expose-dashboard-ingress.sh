#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 12-expose-dashboard-ingress.sh
# Objectif : Exposer Kubernetes Dashboard via Ingress + HTTPS (Let's Encrypt)
# Domaine : https://kubernetes.yucelsan.fr
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/12-expose-dashboard-ingress.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "Création de l'Ingress pour le Dashboard..."

cat <<CAT_EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubernetes-dashboard-ingress
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-dns-ovh-staging
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  rules:
  - host: kubernetes.yucelsan.fr
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kubernetes-dashboard
            port:
              number: 443
  tls:
  - hosts:
    - kubernetes.yucelsan.fr
    secretName: kubernetes-dashboard-tls
CAT_EOF

echo ""
echo "Ingress créé pour https://kubernetes.yucelsan.fr"
echo "Certificat Let's Encrypt (Staging) en cours de provisionnement..."
echo "Vérifie avec : kubectl describe certificate -n kubernetes-dashboard"

kubectl describe certificate -n kubernetes-dashboard

sleep 5

echo "kubectl describe certificate kubernetes-dashboard-tls -n kubernetes-dashboard"
kubectl describe certificate kubernetes-dashboard-tls -n kubernetes-dashboard
EOF
