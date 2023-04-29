#!/bin/bash
set -o errexit

# PROMETHEUS

cd ./monitoring/prometheus

kubectl create namespace monitoring
kubectl create -f clusterRole.yaml
kubectl create -f config-map.yaml
kubectl create  -f prometheus-deployment.yaml 

kubectl wait deployment --namespace=monitoring prometheus-deployment --for condition=Available=True --timeout=90s

# Kube State Metrics

cd ..
kubectl apply -f kube-state-metrics-configs/
kubectl wait deployment --namespace=kube-system kube-state-metrics --for condition=Available=True --timeout=90s

# Alert Manager

cd ./kubernetes-alert-manager
kubectl create -f AlertManagerConfigmap.yaml
kubectl create -f AlertTemplateConfigMap.yaml
kubectl create -f Deployment.yaml
kubectl wait deployment --namespace=monitoring alertmanager --for condition=Available=True --timeout=90s

# Grafana

cd ../kubernetes-grafana
kubectl create -f grafana-datasource-config.yaml
kubectl create -f deployment.yaml
kubectl wait deployment --namespace=monitoring grafana --for condition=Available=True --timeout=90s

# Node Exporter

cd ../kubernetes-node-exporter
kubectl create -f daemonset.yaml
kubectl rollout status daemonset node-exporter -n monitoring --timeout=90s
kubectl create -f service.yaml

# ECHOS

cd ..
PROMETHEUS_POD=$(kubectl get pod --namespace=monitoring -l app=prometheus-server -o jsonpath="{.items[0].metadata.name}")
ALERT_MANAGER_POD=$(kubectl get pod --namespace=monitoring -l app=alertmanager -o jsonpath="{.items[0].metadata.name}")
GRAFANA_POD=$(kubectl get pod --namespace=monitoring -l app=grafana -o jsonpath="{.items[0].metadata.name}")

echo 
echo 
echo 
echo "**************************************************************"
echo 
echo "*** PROMETHEUS ***"
echo "kubectl port-forward ${PROMETHEUS_POD} 8080:9090 -n monitoring"
echo "In your browser: http://localhost:8080"
echo "Example: http://localhost:8080/graph?g0.expr=container_cpu_usage_seconds_total&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=1h"
echo
echo "*** ALERT MANAGER ***"
echo "kubectl port-forward ${ALERT_MANAGER_POD} 8080:9093 -n monitoring"
echo "In your browser: http://localhost:8080"
echo
echo "*** GRAFANA ***"
echo "kubectl port-forward ${GRAFANA_POD} 8080:3000 -n monitoring"
echo "In your browser: http://localhost:8080"
echo "User: admin Pass: admin. Once you log in with default credentials, it will prompt you to change the default password."
echo

# kubectl get pods --namespace=monitoring
# kubectl port-forward prometheus-deployment-67cf879cc4-zrhgc 8080:9090 -n monitoring

cd ..
