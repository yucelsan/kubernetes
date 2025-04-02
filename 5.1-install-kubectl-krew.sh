#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 5.1-install-kubectl-krew.sh
# Objectif : Installer krew (plugin manager pour kubectl)
# Source officielle : https://krew.sigs.k8s.io/docs/user-guide/setup/install/
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/5.1-install-kubectl-krew.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "Téléchargement de krew..."

# Dépendances nécessaires
sudo apt update
sudo apt install -y unzip curl git

# Se placer dans un dossier temporaire
cd "$(mktemp -d)"

# Télécharger krew
OS="$(uname | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"

# Convertir architecture pour krew
if [[ "$ARCH" == "x86_64" ]]; then
  ARCH="amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
fi

KREW="krew-${OS}_${ARCH}"

curl -LO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz"
tar zxvf "${KREW}.tar.gz"
./"${KREW}" install krew

# Ajouter krew au PATH
echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> ~/.bashrc
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

echo "krew est installé !"

# Tester avec un premier plugin sympa
kubectl krew update
kubectl krew install ctx

echo "Plugin 'ctx' installé. Teste avec : kubectl ctx"
EOF
