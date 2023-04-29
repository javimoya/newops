#!/bin/bash
set -o errexit

kubectl delete -f monitoring/kubernetes-node-exporter/
kubectl delete -f monitoring/kubernetes-grafana/
kubectl delete -f monitoring/kubernetes-alert-manager/
kubectl delete -f monitoring/kube-state-metrics-configs/
kubectl delete -f monitoring/prometheus/
kubectl delete all --all -n monitoring
kubectl delete namespaces monitoring
