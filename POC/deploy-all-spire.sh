#!/bin/bash

# Colors
BLUE="\033[0;34m"
CYAN="\033[1;36m"
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "\n${PURPLE}Creating namespaces and configmaps...${NC}\n"
./create-namespaces.sh
kubectl apply -f ./configmaps.yaml

echo -e "\n${GREEN}Deploying Spire...${NC}\n"
(cd spire ; ./deploy-spire.sh)

kubectl rollout status statefulset -n spire spire-server
kubectl -n spire rollout status daemonset spire-agent

echo -e "\n${BLUE}Deploying Istio with Spire SDS integration...${NC}\n"
(cd istio ; ./deploy-istio-spire.sh)

echo -e "\n${CYAN}Deploying Bookinfo application...${NC}\n"
(cd bookinfo ; ./deploy-bookinfo-spire.sh)