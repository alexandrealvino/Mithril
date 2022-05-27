#!/bin/bash

export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
export SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export INGRESS_HOST=$(kubectl get po -l istio=ingressgateway -n istio-system -o jsonpath='{.items[0].status.hostIP}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
URL="http://$GATEWAY_URL/productpage"
echo $URL

for i in $(seq 1 100); do curl -s -o /dev/null $URL; done

for ((i=1;i<100;i++)) do
	#curl -v localhost:8000/productpage
	curl -sIk $URL | grep HTTP/1.1
	#curl --cert client.pem --key key.pem -sk https://localhost:8000/productpage
#	sleep 0.05
  sleep 2
done