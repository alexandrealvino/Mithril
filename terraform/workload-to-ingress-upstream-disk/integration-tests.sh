#!/bin/bash
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

apt update -y
apt install docker.io awscli -y

aws configure set aws_access_key_id ${access_key}
aws configure set aws_secret_access_key ${secret_access_key}

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${hub}

docker pull ${hub}:${tag}

# Tagging for easier use within the docker command below
docker tag ${hub}:${tag} mithril-testing:${tag}

# Creating kubernetes config to use kubectl inside the container
mkdir -p $HOME/.kube && touch $HOME/.kube/config

# Creating kind cluster
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c "find /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster/ -type f -iname "*.sh" -exec chmod +x {} \; && chmod +x /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster/create-kind-cluster.sh && /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster/create-kind-cluster.sh"

# Creating Docker secrets for ECR images
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c "HUB=${hub} AWS_ACCESS_KEY_ID=${access_key} AWS_SECRET_ACCESS_KEY=${secret_access_key} /mithril/POC/create-docker-registry-secret.sh"

# Deploying the PoC
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c "chmod +x /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster/deploy-all.sh && cd /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster && TAG=${tag} HUB=${hub} ./deploy-all.sh"

# Port Forwarding the POD
docker run -i -d --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c 'INGRESS_POD=$(kubectl get pod -l app=istio-ingressgateway -n istio-system -o jsonpath="{.items[0].metadata.name}") \
&& kubectl port-forward "$INGRESS_POD"  8000:8080 -n istio-system'

# Waiting for POD to be ready
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c 'kubectl rollout status deployment productpage-v1'

HOST_IP=$(hostname -I | awk '{print $1}')

# Request to productpage workload
curl localhost:8000/productpage > ${build_tag}.txt

# Creating kind cluster for the client
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c "find /mithril/usecases/workload-to-ingress-upstream-disk/server-cluster/ -type f -iname "*.sh" -exec chmod +x {} \; && chmod +x /mithril/usecases/workload-to-ingress-upstream-disk/client-cluster/create-kind-cluster.sh && chmod +x /mithril/usecases/workload-to-ingress-upstream-disk/client-cluster/deploy-all.sh && /mithril/usecases/workload-to-ingress-upstream-disk/client-cluster/create-kind-cluster.sh"

# Deploying the PoC
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c "cd /mithril/usecases/workload-to-ingress-upstream-disk/client-cluster && TAG=${tag} HUB=${hub} ./deploy-all.sh"

# Waiting for POD to be ready
docker run -i --rm \
-v "/var/run/docker.sock:/var/run/docker.sock:rw" \
-v "/.kube/config:/root/.kube/config:rw" \
--network host mithril-testing:${tag} \
bash -c 'kubectl rollout status deployment sleep'

CLIENT_POD=$(kubectl get pod -l app=sleep -n default -o jsonpath="{.items[0].metadata.name}")

echo $${HOST_IP}
echo $${HOST_IP}
kubectl exec -i -t pod/$CLIENT_POD -c sleep -- /bin/sh -c "curl -sSLk --cert /sleep-certs/sleep-svid.pem --key /sleep-certs/sleep-key.pem --cacert /sleep-certs/root-cert.pem https://$${HOST_IP}:8000/productpage"

# Copying response to S3 bucket
aws s3 cp /${build_tag}.txt s3://mithril-artifacts/ --region us-east-1

# Generate log files
cp /var/log/user-data.log ${build_tag}_log.txt

# Copying log to S3 bucket
aws s3 cp /${build_tag}_log.txt s3://mithril-artifacts/ --region us-east-1