#!/bin/bash
set -o errexit

if [ $# -lt 2 ]; then
	echo "error parameters $#"
	exit 1
fi

export PROJECT=${1}
export BILLING_ACCOUNT=${2}
export KOPS_STATE_STORE=gs://kops_state_store_${PROJECT}/
export REGION=us-central1
export ZONES=us-central1-a,us-central1-c,us-central1-b
export NAME=${PROJECT}.k8s.local
export NODE_COUNT=3

# create gcp project and link billing
gcloud projects create ${PROJECT} --set-as-default
gcloud beta billing projects link ${PROJECT} --billing-account ${BILLING_ACCOUNT}

# enable needed services
gcloud services enable compute.googleapis.com dns.googleapis.com artifactregistry.googleapis.com

# create state bucket
gsutil mb -p ${PROJECT} -c standard -l ${REGION} ${KOPS_STATE_STORE}

# create artifact registry
gcloud artifacts repositories create my-repo --project=${PROJECT} --repository-format=docker --location=${REGION} --quiet

# delete default vpc

gcloud compute firewall-rules list \
--project=${PROJECT} \
--filter="network:/projects/${PROJECT}/global/networks/default" \
--format="value(name)"  \
| xargs gcloud compute firewall-rules delete \
--project=${PROJECT} \
--quiet

gcloud compute networks delete default --project=${PROJECT} --quiet

# create cluster

kops create cluster $NAME --zones "${ZONES}" --control-plane-zones "${ZONES}" --state ${KOPS_STATE_STORE}/ --project=${PROJECT} --node-count ${NODE_COUNT} --node-size n1-standard-4 --master-size n1-standard-2
kops update cluster ${NAME} --yes --admin=87600h

echo "*** FINISHED ***"
