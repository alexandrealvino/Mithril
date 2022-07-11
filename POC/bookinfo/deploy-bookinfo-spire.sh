#!/bin/bash

istioctl kube-inject --filename bookinfo-spire.yaml | kubectl apply -f -
kubectl apply -f gateway.yaml
