#!/bin/bash
set -o errexit

if [ $# -lt 1 ]; then
	echo "error parameters $#"
	exit 1
fi

export PROJECT=${1}
export KOPS_STATE_STORE=gs://kops_state_store_${PROJECT}/

kops validate cluster --wait 20m