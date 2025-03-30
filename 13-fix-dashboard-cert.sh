#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 13-fix-dashboard-cert.sh
# Objectif : Réparer le blocage de certificat Let's Encrypt (HTTP-01)
# Crée un Ingress spécifique pour les challenges
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/13-fix-dashboard-cert.sh root@$SCW_IP:/opt/k8s/

echo "🚀 Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "🧼 Suppression du certificat et de l'ingress actuel..."
kubectl delete certificate kubernetes-dashboard-tls -n kubernetes-dashboard || true
kubectl delete ingress kubernetes-dashboard-ingress -n kubernetes-dashboard || true

echo "📦 Création d'un Ingress pour la validation HTTP-01 des challenges..."
cat <<KUB_EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dashboard-challenge-ingress
  namespace: kubernetes-dashboard
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    cert-manager.io/acme-challenge-type: http01
    cert-manager.io/http01-edit-in-place: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: kubernetes.yucelsan.fr
    http:
      paths:
      - path: /.well-known/acme-challenge/
        pathType: Prefix
        backend:
          service:
            name: dummy-service
            port:
              number: 80
KUB_EOF

echo "🔧 Création d'un service fictif (dummy) pour Ingress challenge..."
kubectl apply -f - <<CTL_EOF
apiVersion: v1
kind: Service
metadata:
  name: dummy-service
  namespace: kubernetes-dashboard
spec:
  selector:
    app: dummy
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
CTL_EOF

echo "🛠️ Re-création de l'Ingress du Dashboard avec certificat..."
cat <<CAT_EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kubernetes-dashboard-ingress
  namespace: kubernetes-dashboard
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-staging
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
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
echo "✅ Challenge corrigé. Cert-Manager va maintenant pouvoir générer le certificat."
echo "⏳ Tu peux suivre l’évolution avec :"
echo "   kubectl describe certificate kubernetes-dashboard-tls -n kubernetes-dashboard"
EOF
