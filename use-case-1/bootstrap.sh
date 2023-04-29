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
export SAC=mygcpsac
export REPO=my-repo
export EMAIL="${SAC}@${PROJECT}.iam.gserviceaccount.com"


# create gcp project and link billing
gcloud projects create ${PROJECT} --set-as-default
gcloud beta billing projects link ${PROJECT} --billing-account ${BILLING_ACCOUNT}

# enable needed services
gcloud services enable compute.googleapis.com dns.googleapis.com artifactregistry.googleapis.com

# create state bucket
gsutil mb -p ${PROJECT} -c standard -l ${REGION} ${KOPS_STATE_STORE}

# create artifact registry
gcloud artifacts repositories create ${REPO} --project=${PROJECT} --repository-format=docker --location=${REGION} --quiet

# https://github.com/marketplace/actions/authenticate-to-google-cloud#setup
gcloud iam service-accounts create "${SAC}" --project "${PROJECT}" --quiet

gcloud artifacts repositories add-iam-policy-binding ${REPO} \
   --location ${REGION} \
   --member=serviceAccount:${SAC}@${PROJECT}.iam.gserviceaccount.com \
   --role=roles/artifactregistry.admin

gcloud iam service-accounts keys create gcpsac.json \
    --iam-account=${SAC}@${PROJECT}.iam.gserviceaccount.com

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

gcloud projects add-iam-policy-binding ${PROJECT} --member=serviceAccount:node-${PROJECT}-k8s-local@${PROJECT}.iam.gserviceaccount.com --role='roles/artifactregistry.admin'

echo
echo
echo
echo "*** FINISHED ***"
