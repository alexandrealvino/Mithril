#!/bin/bash

kubectl apply -f spire/spiffe-ids.yaml > /dev/null

kubectl label pods -l app=productpage spireSpiffeid=workloads --overwrite=true > /dev/null && \
kubectl label pods -l app=details spireSpiffeid=workloads --overwrite=true > /dev/null && \
kubectl label pods -l app=ratings spireSpiffeid=workloads --overwrite=true > /dev/null  && \
kubectl label pods -l app=reviews spireSpiffeid=workloads --overwrite=true > /dev/null

kubectl exec -i -t spire-server-0 -n spire -c spire-server -- /bin/sh -c "bin/spire-server entry show -socketPath /run/spire/sockets/api.sock"
