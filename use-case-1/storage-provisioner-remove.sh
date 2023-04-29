#!/bin/bash
set -o errexit

kubectl delete -f storage-provisioner/
