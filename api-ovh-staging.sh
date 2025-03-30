#!/bin/bash

kubectl create secret generic ovh-api-credentials -n cert-manager \
  --from-literal=applicationKey='' \
  --from-literal=applicationSecret='' \
  --from-literal=consumerKey=''

echo "ovh-api-credentials terminé."
