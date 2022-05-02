#!/bin/bash

# Colors
BLUE="\033[0;34m"
BROWN="\033[0;33m"
CYAN="\033[1;36m"
PURPLE='\033[0;35m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Server cluster
#echo -e "\n${BROWN}Deploying server cluster...${NC}\n"
#./create-kind-cluster.sh
echo -e "\n${BROWN}Switching context to server cluster...${NC}\n"
kubectl config use-context kind-kind

echo -e "\n${PURPLE}Creating namespaces and configmaps...${NC}\n"
./create-namespaces.sh
kubectl apply -f ./configmaps.yaml

echo -e "\n${GREEN}Deploying Spire...${NC}\n"
(cd spire ; ./deploy-spire-federation-server.sh)

kubectl rollout status statefulset -n spire spire-server
kubectl -n spire rollout status daemonset spire-agent

bundle_server=$(kubectl exec --stdin spire-server-0 -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock)

kubectl port-forward --address 0.0.0.0 spire-server-0  4001:8443 -n spire &

# Client cluster
#echo -e "\n${BROWN}Deploying client cluster...${NC}\n"
#../usecases/common/utils/create-kind2-cluster.sh
echo -e "\n${BROWN}Switching context to client cluster...${NC}\n"
kubectl config use-context kind-kind2

echo -e "\n${PURPLE}Creating namespaces and configmaps...${NC}\n"
./create-namespaces.sh
kubectl apply -f ./configmaps.yaml

echo -e "\n${GREEN}Deploying Spire...${NC}\n"
(cd spire ; ./deploy-spire-federation-client.sh)

kubectl rollout status statefulset -n spire spire-server
kubectl -n spire rollout status daemonset spire-agent

bundle_client=$(kubectl exec --stdin spire-server-0 -c spire-server -n spire  -- /opt/spire/bin/spire-server bundle show -format spiffe -socketPath /run/spire/sockets/server.sock)

echo -e "\n${BROWN}Setting example.org bundle to the client cluster SPIRE server${NC}\n"
# Set example.org bundle to domain.test SPIRE bundle endpoint
kubectl exec --stdin spire-server-0 -c spire-server -n spire -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://example.org -socketPath /run/spire/sockets/server.sock <<< "$bundle_server"

kubectl port-forward --address 0.0.0.0 spire-server-0  4002:8443 -n spire &

echo -e "\n${BROWN}Switching context to server cluster...${NC}\n"
kubectl config use-context kind-kind

echo -e "\n${BROWN}Setting domain.test bundle to the server cluster SPIRE server${NC}\n"
# Set domain.test bundle to example.org SPIRE bundle endpoint
kubectl exec --stdin spire-server-0 -c spire-server -n spire -- /opt/spire/bin/spire-server bundle set -format spiffe -id spiffe://domain.test -socketPath /run/spire/sockets/server.sock <<< "$bundle_client"

echo -e "\n${BLUE}Deploying Istio with Spire SDS integration...${NC}\n"
(cd istio ; ./deploy-istio-spire-federation-server.sh)

echo -e "\n${CYAN}Deploying Bookinfo application...${NC}\n"
(cd bookinfo ; ./deploy-bookinfo-spire-federation-server.sh)

kubectl rollout status deployment productpage-v1

INGRESS_POD=$(kubectl get pod -l istio=ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --address 0.0.0.0 "$INGRESS_POD"  8000:7080 -n istio-system &

sleep 2

echo -e "\n${BROWN}Switching context to client cluster...${NC}\n"
kubectl config use-context kind-kind2

echo -e "\n${BLUE}Deploying Istio with Spire SDS integration...${NC}\n"
(cd istio ; ./deploy-istio-spire-federation-client.sh)

echo -e "\n${CYAN}Deploying Sleep application...${NC}\n"
(cd bookinfo ; ./deploy-bookinfo-spire-federation-client.sh)

kubectl rollout status deployment sleep

echo -e "\n${CYAN}Requesting product page application...${NC}\n"
CLIENT_POD=$(kubectl get pod -l app=sleep -n default -o jsonpath="{.items[0].metadata.name}")
export CLIENT_POD=${CLIENT_POD}
kubectl exec -i -t pod/$CLIENT_POD -c sleep -- /bin/sh -c "curl -v http://productpage.default.svc:8000/productpage"
