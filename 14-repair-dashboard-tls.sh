#!/bin/bash

# -----------------------------------------------------------------------------
# Script : 14-repair-dashboard-tls.sh
# Objectif : Réparer le blocage de certificat Let's Encrypt (TLS)
# Auteur : YUCELSAN
# -----------------------------------------------------------------------------

echo "Suppression de l'ancien certificat pour forcer la régénération..."

kubectl delete certificate kubernetes-dashboard-tls -n kubernetes-dashboard --ignore-not-found

echo "Recréation automatique par cert-manager..."
sleep 5

echo "Attente que le certificat soit prêt..."
while true; do
  STATUS=$(kubectl get certificate kubernetes-dashboard-tls -n kubernetes-dashboard -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)
  if [[ "$STATUS" == "True" ]]; then
    echo "Certificat TLS prêt !"
    break
  else
    echo "En attente du certificat (status: $STATUS)..."
    sleep 5
  fi
done

echo "Secret TLS généré :"
kubectl get secret kubernetes-dashboard-tls -n kubernetes-dashboard

echo "Tu peux maintenant accéder à https://kubernetes.yucelsan.fr"
