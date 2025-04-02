#!/bin/bash

echo "Déploiement du webhook OVH cert-manager..."

set -e

# Namespace pour le webhook
NAMESPACE=cert-manager

echo "Clonage du repo cert-manager-webhook-ovh..."
git clone https://github.com/k8s-at-home/cert-manager-webhook-ovh.git /tmp/cert-manager-webhook-ovh

cd /tmp/cert-manager-webhook-ovh

echo "Génération des manifests..."
./hack/generate-webhook-cert.sh
kubectl apply -f deploy/webhook.yaml

echo "Attente du déploiement..."
kubectl rollout status deployment cert-manager-webhook-ovh -n $NAMESPACE

echo "Webhook OVH installé avec succès !"
echo "Tu peux maintenant relancer ton certificat !"
