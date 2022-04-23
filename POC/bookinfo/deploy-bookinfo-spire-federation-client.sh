#!/bin/bash

../istioctl kube-inject --filename sleep.yaml | kubectl apply -f -

kubectl apply -f ../../usecases/common/networking/service-entry.yaml
