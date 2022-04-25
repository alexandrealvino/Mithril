#!/bin/bash

./create-namespaces.sh
kubectl apply -f ./configmaps.yaml

(cd istio ; ./deploy-istio.sh)
(cd bookinfo ; ./deploy-bookinfo.sh)
