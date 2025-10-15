#!/bin/bash

set -e
cd "$(dirname "$0")"

# Check required tools
command -v cdp >/dev/null 2>&1 || { echo "❌ CDP CLI not found. Please install and configure CDP CLI."; exit 1; }
command -v jq >/dev/null 2>&1 || { echo "❌ jq not found. Please install jq."; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI not found. Please install AWS CLI."; exit 1; }

# required
N_VCLUSTERS=20

# defaults
CDP_PROFILE="default" # change if you are using non default cdp cli profile/credentials
ENVIRONMENT_NAME="cde-hol-cdp-env"
CDE_SERVICE_NAME="cde-hol-de-service"
DATALAKE_NAME="cde-hol-aw-dl"

# 1. create data engineering service
response=$(cdp de enable-service \
  --env $ENVIRONMENT_NAME \
  --name $CDE_SERVICE_NAME \
  --enable-public-endpoint \
  --instance-type "r5.4xlarge" \
  --minimum-instances 1 \
  --maximum-instances 50)

CLUSTER_ID=$(echo "$response" | jq -r '.service.clusterId')
export CLUSTER_ID
echo "CLUSTER_ID=$CLUSTER_ID"

# Poll for cluster creation status to be completed
echo "Waiting for service to become available..."

while true; do
  status=$(cdp de describe-service --cluster-id "$CLUSTER_ID" --profile $CDP_PROFILE | jq -r '.service.status')
  echo "Current status: $status"

  # Check for common success statuses
  if [[ "$status" == "RUNNING" ]] || [[ "$status" == "AVAILABLE" ]] || [[ "$status" == "ClusterCreationCompleted" ]]; then
    echo "Service is ready (status: $status). Continuing..."
    break
  fi
  
  # Check for failure statuses
  if [[ "$status" == "FAILED" ]] || [[ "$status" == "ERROR" ]]; then
    echo "❌ Service creation failed with status: $status"
    exit 1
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

    sleep 10

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

# 4. upload workshop data
echo "Uploading workshop data..."

# retrieve bucket name from datalake
BUCKET_NAME=$(cdp datalake describe-datalake --datalake-name "$DATALAKE_NAME" --profile $CDP_PROFILE | jq -r '.datalake.cloudStorageBaseLocation' | sed 's|s3a://||; s|s3://||' | cut -d'/' -f1)
echo "Target bucket: $BUCKET_NAME"

# upload workshop data
if [ -d "../data" ]; then
    echo "Uploading data from ../data to s3://$BUCKET_NAME/cde-hol-source"
    aws s3 cp ../data s3://$BUCKET_NAME/cde-hol-source --recursive
    
    # automated validation
    echo "Validating data upload..."
    file_count=$(aws s3 ls s3://$BUCKET_NAME/cde-hol-source --recursive | grep -E "\.(csv)$" | wc -l)
    echo "Uploaded $file_count CSV files"
    
    if [ "$file_count" -gt 0 ]; then
        echo "✓ Workshop data uploaded successfully"
    else
        echo "⚠ Warning: No CSV files found after upload"
    fi
else
    echo "⚠ Warning: ../data directory not found. Skipping data upload."
    echo "Please ensure the data directory exists relative to the setup directory."
fi

echo "Setup completed successfully!"
