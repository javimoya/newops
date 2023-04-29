#!/bin/bash
set -o errexit

if [ $# -lt 1 ]; then
	echo "error parameters $#"
	exit 1
fi

export PROJECT=${1}
export KOPS_STATE_STORE=gs://kops_state_store_${PROJECT}/
export NAME=${PROJECT}.k8s.local

# generate kube config
kops export kubeconfig $NAME --admin=87600h --kubeconfig ./mykubeconfig

echo
echo
echo
echo "*** FINISHED ***"
echo "Create a secret KUBE_CONFIG in the github repo with the content of mykubeconfig file."
echo "Create a secret SAC_KEY in the github repo with the content of gcpsac.json file (convert to one line first https://codebeautify.org/json-to-one-line?utm_content=cmp-true)."
