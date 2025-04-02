#!/bin/bash

# -----------------------------------------------------------------------------
# Script : setup-k8s-project.sh
# Objectif : Génère l'arborescence de scripts pour l'installation distante
#            d'un cluster Kubernetes avec kubeadm.
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

echo "Connexion SSH dans notre instance Scaleway..."
ssh -i "$SSH_KEY_PATH" root@$SCW_IP << 'EOF'

cd /opt/

# Nom du dossier principal
PROJECT_DIR="k8s"

# Créer les dossiers et fichiers
echo "Création de la structure du projet Kubernetes..."
mkdir -p "$PROJECT_DIR"

# Liste des scripts à créer (vides pour l’instant)
SCRIPTS=(
  "01-disable-swap.sh"
  "02-install-containerd.sh"
  "03-install-kubernetes.sh"
  "04-init-k8s-cluster.sh"
  "05-install-cni-calico.sh"
  "06-configure-kubectl.sh"
  "07-enable-pods-on-master.sh"
  "remote-k8s-setup.sh"
)

# Création des fichiers scripts vides avec un shebang
for script in "${SCRIPTS[@]}"; do
  touch "$PROJECT_DIR/$script"
  chmod +x "$PROJECT_DIR/$script"
  echo "#!/bin/bash" > "$PROJECT_DIR/$script"
  echo "" >> "$PROJECT_DIR/$script"
done

# Création du README.md de base
cat << 'EOF_MD' > "$PROJECT_DIR/README.md"
# Kubernetes Remote Setup (via kubeadm)

Ce dossier contient les scripts shell pour installer un cluster Kubernetes 
(mononœud) à distance sur un serveur (Scaleway par exemple), en plusieurs étapes.

## Étapes des scripts

1. **01-disable-swap.sh** – Désactive le swap proprement (exigé par kubeadm)
2. **02-install-containerd.sh** – Installe et configure containerd
3. **03-install-kubernetes.sh** – Installe kubelet, kubeadm, kubectl
4. **04-init-k8s-cluster.sh** – Initialise le cluster avec kubeadm
5. **05-install-cni-calico.sh** – Déploie Calico comme CNI
6. **06-configure-kubectl.sh** – Configure kubectl pour l’utilisateur
7. **07-enable-pods-on-master.sh** – Permet de scheduler des pods sur le master
8. **remote-k8s-setup.sh** – Script maître pour tout exécuter à distance via SSH

## Lancement

À exécuter depuis ta machine d’administration (ex: ta VM Dedibox) :

bash remote-k8s-setup.sh

EOF_MD
EOF
