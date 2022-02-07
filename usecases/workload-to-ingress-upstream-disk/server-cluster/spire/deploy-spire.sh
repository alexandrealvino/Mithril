#!/bin/bash

set -e

# Create the k8s-workload-registrar crd, configmap and associated role bindingsspace
kubectl apply \
    -f ../../../../POC/spire/k8s-workload-registrar-crd-cluster-role.yaml \
    -f ../../../../POC/spire/k8s-workload-registrar-crd-configmap.yaml \
    -f ../../../../POC/spire/spiffeid.spiffe.io_spiffeids.yaml

# Create the server’s service account, configmap and associated role bindings
kubectl apply \
    -f ../../../../POC/spire/server-account.yaml \
    -f ../../../../POC/spire/spire-bundle-configmap.yaml \
    -f ../../../../POC/spire/server-cluster-role.yaml

# Deploy the server configmap and statefulset
kubectl apply \
    -f ../../common/spire/server-configmap.yaml \
    -f ../../common/spire/server-statefulset.yaml \
    -f ../../../../POC/spire/server-service.yaml

# Configuring and deploying the SPIRE Agent
kubectl apply \
    -f ../../../../POC/spire/agent-account.yaml \
    -f ../../../../POC/spire/agent-cluster-role.yaml

sleep 2

kubectl apply \
    -f ../../../../POC/spire/agent-configmap.yaml \
    -f ../../../../POC/spire/agent-daemonset.yaml

# Applying SPIFFE CSI Driver configuration
kubectl apply -f ../../../../POC/spire/spiffe-csi-driver.yaml