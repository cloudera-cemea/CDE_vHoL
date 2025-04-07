#!/bin/bash

set -e
cd "$(dirname "$0")"

N_VCLUSTERS=<number-participants>
CLUSTER_ID="<cde-cluster-id>"
CDP_PROFILE="<cdp-cli-profile>"

# create individual virtual clusters
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

# create shared virtual cluster for interactive sessions
cdp de create-vc \
    --name "hol-shared-vc" \
    --cpu-requests 80 \
    --memory-requests 160Gi \
    --spark-version SPARK3_5 \
    --vc-tier ALLP \
    --cluster-id $CLUSTER_ID \
    --profile $CDP_PROFILE \
    || true
