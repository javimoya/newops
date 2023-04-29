#!/bin/bash
set -o errexit

if [ $# -lt 1 ]; then
	echo "error parameters $#"
	exit 1
fi

export KIBANA_PASSWORD=${1}

cd ./logging
kubectl apply -f namespace.yaml
kubectl create secret generic kibana-password --from-literal=password="${KIBANA_PASSWORD}" --namespace kube-logging
kubectl apply -f es-svc.yaml
kubectl apply -f es-sts.yaml
kubectl apply -f kibana-svc.yaml
kubectl apply -f kibana-deployment.yaml
kubectl wait deployment --namespace=kube-logging kibana --for condition=Available=True --timeout=90s
kubectl apply -f fluent-bit-sa.yaml 
kubectl apply -f fluent-bit-role.yaml 
kubectl apply -f fluent-bit-rb.yaml
kubectl apply -f fluent-bit-configmap.yaml
kubectl apply -f fluent-bit-ds.yaml
kubectl rollout status daemonset f-bit-pod -n kube-logging --timeout=90s
kubectl apply -f test-pod.yaml

# ECHOS

cd ..
KIBANA_POD=$(kubectl get pod --namespace=kube-logging -l app=kibana -o jsonpath="{.items[0].metadata.name}")

echo 
echo 
echo 
echo "**************************************************************"
echo 
echo "*** KIBANA ***"
echo "kubectl port-forward ${KIBANA_POD} 8080:5601 -n kube-logging"
echo "In your browser: http://localhost:8080"
echo "User: elastic Pass: ${KIBANA_PASSWORD}."
echo "Example: There is a test pod creating logs."
echo "kubectl get pods log-generator -n default"
echo "On Kibana: create an index pattern logstash-*"
echo

cd ..
