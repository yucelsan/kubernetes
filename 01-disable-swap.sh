#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 01-disable-swap.sh
# Objectif : Désactiver le swap temporairement et définitivement
# Pourquoi : kubeadm exige que le swap soit désactivé pour fonctionner correctement
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
scp -i "$SSH_KEY_PATH" -r /root/op-scaleway/k8s/01-disable-swap.sh root@$SCW_IP:/opt/k8s/

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/k8s/

# Nom du dossier principal
PROJECT_DIR="k8s"

set -e  # Arrêter le script en cas d'erreur

echo "Désactivation temporaire du swap..."
sudo swapoff -a

echo "Commentaire de la ligne de swap dans /etc/fstab..."
# Ce sed commente toute ligne contenant " swap " pour éviter qu’il soit réactivé au redémarrage
sudo sed -i.bak '/ swap / s/^/#/' /etc/fstab

echo "Le swap est maintenant désactivé (temporairement et au reboot)"
echo "Sauvegarde de /etc/fstab originale : /etc/fstab.bak"
EOF
