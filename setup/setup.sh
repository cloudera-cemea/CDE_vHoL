#!/bin/bash

set -e
cd "$(dirname "$0")"

# required
N_VCLUSTERS=<number-workshop-participants>

# defaults
CDP_PROFILE="default" # change if you are using non default cdp cli profile/credentials

# 1. create data engineering service
response=$(cdp de enable-service \
  --env "cde-hol-cdp-env" \
  --name "cde-hol-service-backup" \
  --enable-public-endpoint \
  --instance-type "r5.4xlarge" \
  --minimum-instances 1 \
  --maximum-instances 50)

CLUSTER_ID=$(echo "$response" | jq -r '.service.clusterId')
export CLUSTER_ID
echo "CLUSTER_ID=$CLUSTER_ID"

# Poll for cluster creation status to be completed
echo "Waiting for service to reach status 'FooBar'..."

while true; do
  status=$(cdp de describe-service --cluster-id "$CLUSTER_ID" | jq -r '.service.status')
  echo "Current status: $status"

  if [[ "$status" == "FooBar" ]]; then
    echo "Service reached status 'FooBar'. Continuing..."
    break
  fi

  sleep 15 # Wait before polling again
done

# 2. create individual virtual clusters
for i in $(seq 1 $N_VCLUSTERS)
do
    if [[ "$i" -lt "10" ]]
    then n=00$i
    else n=0$i
    fi

    vcluster="virtual-cluster-$n"
    user="user$n"
    echo "Deploying Virtual Cluster: $vcluster for user: $user"

    cdp de create-vc \
        --name $vcluster \
        --acl-users $user \
        --cpu-requests 20 \
        --memory-requests 80Gi \
        --spark-version SPARK3_5 \
        --vc-tier ALLP \
        --cluster-id $CLUSTER_ID \
        --profile $CDP_PROFILE \
        || true

    sleep 3

done

# 3. create shared virtual cluster for interactive sessions
cdp de create-vc \
    --name "hol-shared-vc" \
    --cpu-requests 80 \
    --memory-requests 160Gi \
    --spark-version SPARK3_5 \
    --vc-tier ALLP \
    --cluster-id $CLUSTER_ID \
    --profile $CDP_PROFILE \
    || true
