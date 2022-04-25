#!/bin/bash

#../istioctl kube-inject --filename bookinfo-file.yaml | kubectl apply -f -
../istioctl kube-inject --filename bookinfo-filev2.yaml | kubectl apply -f -
kubectl apply -f gateway.yaml
