#!/bin/bash
set -o errexit

PROMETHEUS_POD=$(kubectl get pod --namespace=monitoring -l app=prometheus-server -o jsonpath="{.items[0].metadata.name}")
ALERT_MANAGER_POD=$(kubectl get pod --namespace=monitoring -l app=alertmanager -o jsonpath="{.items[0].metadata.name}")
GRAFANA_POD=$(kubectl get pod --namespace=monitoring -l app=grafana -o jsonpath="{.items[0].metadata.name}")
KIBANA_POD=$(kubectl get pod --namespace=kube-logging -l app=kibana -o jsonpath="{.items[0].metadata.name}")

kubectl port-forward ${PROMETHEUS_POD} 8080:9090 -n monitoring &
kubectl port-forward ${ALERT_MANAGER_POD} 8081:9093 -n monitoring &
kubectl port-forward ${GRAFANA_POD} 8082:3000 -n monitoring &
kubectl port-forward ${KIBANA_POD} 8083:5601 -n kube-logging &

echo 
echo 
echo 
echo "**************************************************************"
echo 
echo "*** PROMETHEUS ***"
echo "In your browser: http://localhost:8080"
echo "Example: http://localhost:8080/graph?g0.expr=container_cpu_usage_seconds_total&g0.tab=0&g0.stacked=0&g0.show_exemplars=0&g0.range_input=1h"
echo
echo "*** ALERT MANAGER ***"
echo "In your browser: http://localhost:8081"
echo
echo "*** GRAFANA ***"
echo "In your browser: http://localhost:8082"
echo "User: admin Pass: admin. Once you log in with default credentials, it will prompt you to change the default password."
echo
echo "*** KIBANA ***"
echo "In your browser: http://localhost:8083"
echo "User: elastic Pass: mypass."
echo "Example: There is a test pod creating logs."
echo "kubectl get pods log-generator -n default"
echo "On Kibana: create an index pattern logstash-*"
echo
echo "*** STOP ALL TOOLS ***"
echo "pgrep kubectl | xargs kill -9"
echo 
echo 
echo 
echo "**************************************************************"
echo 


# kubectl get pods --namespace=monitoring
# kubectl port-forward prometheus-deployment-67cf879cc4-zrhgc 8080:9090 -n monitoring

