#!/bin/bash

../istioctl kube-inject --filename bookinfo-spire-federation.yaml | kubectl apply -f -
kubectl apply -f gateway.yaml
