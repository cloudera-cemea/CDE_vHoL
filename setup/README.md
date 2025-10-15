# Cloudera Data Engineering Hands-on Lab CEMEA Setup Guide

This document provides a step-by-step guide to setting up Cloudera Services and Configurations for running the Hands-on Lab. The setup includes creating and configuring Cloudera services, setting up Ranger permissions and uploading workshop data. The setup is designed to be executed on a Linux-based system (e.g. macOS) with the necessary tools installed. The setup guide covers:

- Cloudera on Cloud Environment & Data Lake w/ RAZ enabled
- Cloudera Data Engineering Service with Public Endpoints/CIDR
- Ranger Permissions for S3 Access
- Workshop Data Upload
- Virtual Clusters

The following prerequisites are required to execute the setup:

- Terraform for deploying AWS prerequisites and Cloudera infrastructure
- AWS CLI with access to the AWS account (required for AWS prerequisites deployment via Terraform)
- CDP CLI with access to the Cloudera tenant (required for Cloudera on Cloud deployment via Terraform and automated service creation)
- jq command-line JSON processor (required for parsing CDP CLI responses in the automation script)

## Setup Steps

### 1. Create CDP Environment & Data Lake via the [Cloudera Terraform Quickstarts](https://github.com/cloudera-labs/cdp-tf-quickstarts.git)

>[!Warning]
>
> You must use the `env_prefix` "cde-hol" in order for the remaining setup steps to work without additional configurations.

- Edit the variables in the terraform.tfvars file, e.g.:

```
# ------- Global settings -------
env_prefix = "cde-hol" # Required name prefix for cloud and CDP resources, e.g. cldr1

# ------- Cloud Settings -------
aws_region = "eu-central-1" # Change this to specify Cloud Provider region, e.g. eu-west-1

# ------- CDP Environment Deployment -------
deployment_template = "public"  # Specify the deployment pattern below. Options are public, semi-private or private

# ------- Resource Tagging -------
# **NOTE: An example of how to specify tags is below; uncomment & edit if required
env_tags = {
    owner   = "mengelhardt"
    project = "cde-hol"
    enddate = "2025-01-30"
}
```

- Run the terraform apply command:

```bash
terraform apply
```

### 2. Create a Data Engineering Service and Virtual Clusters

The [./setup.sh](setup.sh) script automates the creation of both the Data Engineering Service and Virtual Clusters.

**Prerequisites**

- `CDP CLI` installed and configured with appropriate credentials
- `jq` command-line JSON processor installed
- Credentials to access to the CDP environment created in the first step

**Configuration**

Edit the setup.sh script to specify the number of workshop participants:

```bash
N_VCLUSTERS=<number-workshop-participants>
```

Optionally, adjust the CDP profile if you're not using the default:

```bash
CDP_PROFILE="default" # change if you are using non default cdp cli profile/credentials
```

**Execution**

Run the automated setup script:

```bash
bash setup.sh
```

This script will:

1. **Create the Data Engineering Service** with the following configurations:
   - Environment: `cde-hol-cdp-env`
   - Service name: `cde-hol-service-backup`
   - Public endpoint enabled
   - Instance type: `r5.4xlarge`
   - Auto-scaling: 1-50 instances

2. **Create individual Virtual Clusters** for each participant:
   - Naming pattern: `virtual-cluster-001`, `virtual-cluster-002`, etc.
   - User access: `user01`, `user02`, etc.
   - Resources: 20 CPU requests, 80Gi memory
   - Spark version: SPARK3_5
   - Tier: ALLP (All Purpose)

3. **Create a shared Virtual Cluster** for interactive sessions:
   - Name: `hol-shared-vc`
   - Resources: 80 CPU requests, 160Gi memory
   - Accessible by all users for collaborative work

The script includes automatic polling to wait for the service creation to complete before proceeding with virtual cluster creation.

### 3. Upload workshop data

The [./setup.sh](setup.sh) script automatically handles workshop data upload by:

1. **Detecting the target bucket**: Retrieves the S3 bucket name from the datalake's `cloudStorageBaseLocation`
2. **Uploading data**: Copies all files from `../data` to `s3://$BUCKET_NAME/cde-hol-source` recursively
3. **Validating upload**: Counts CSV files to ensure successful upload
4. **Error handling**: Gracefully handles missing data directory with clear warnings

**Manual upload (if needed):**

If you need to upload data manually or the automated upload fails, you can use:

```bash
aws s3 cp data s3://$BUCKET_NAME/cde-hol-source --recursive
```

**Validation:**

To verify the data structure manually:

```bash
aws s3 ls s3://$BUCKET_NAME/cde-hol-source --recursive

# Expected output:
2025-01-23 12:50:55     442307 cde-hol-source/2021/customers.csv
2025-01-23 12:50:55      90249 cde-hol-source/2021/sales.csv
2025-01-23 12:50:55        170 cde-hol-source/2022/customers.csv
2025-01-23 12:50:55     238087 cde-hol-source/2022/sales.csv
```

### 4. Configure Cloudera and Ranger Permissions

> **Note**: The following steps can be automated using CDP CLI and Ranger REST API. The setup.sh script can be extended to include these steps for a fully automated deployment.


#### Cloudera User Management

For the Cloudera environment, enable access to the workshop user group by assigning following roles:

- EnvironmentUser
- DEUser
- DWUser
- MLUser

**Automation Example:**
```bash
# Configuration
WORKSHOP_GROUP="<workshop-user-group>"

# Create workshop user group
cdp iam create-group --group-name "$WORKSHOP_GROUP"

# Assign roles to the group
cdp iam assign-group-role --group-name "$WORKSHOP_GROUP" --role "crn:altus:iam:us-west-1:altus:role:EnvironmentUser"
cdp iam assign-group-role --group-name "$WORKSHOP_GROUP" --role "crn:altus:iam:us-west-1:altus:role:DEUser"
cdp iam assign-group-role --group-name "$WORKSHOP_GROUP" --role "crn:altus:iam:us-west-1:altus:role:DWUser"
cdp iam assign-group-role --group-name "$WORKSHOP_GROUP" --role "crn:altus:iam:us-west-1:altus:role:MLUser"
```

#### Ranger

Add the workshop user group to the following Ranger policies for SQL/S3 access:

- hadoop sql: all storage url, all url, database table columns
- s3: all bucket path

**Automation Example:**
```bash
# Configuration
WORKSHOP_GROUP="<workshop-user-group>"
DATALAKE_NAME="<datalake-name>"

# Get Ranger admin URL from datalake endpoints
RANGER_ADMIN_HOST=$(cdp datalake describe-datalake --datalake-name "$DATALAKE_NAME" | jq -r '.datalake.endpoints.endpoints[] | select(.serviceName=="RANGER_ADMIN" and .mode=="SSO_PROVIDER_FROM_UMS") | .serviceUrl' | sed 's|https://||' | sed 's|/.*||')

# These can be automated using Ranger REST API calls
# Example: Create S3 policy via curl to Ranger Admin API
curl -X POST "https://$RANGER_ADMIN_HOST/service/public/v2/api/policy" \
  -H "Content-Type: application/json" \
  -d "{
    \"service\": \"s3-service\",
    \"name\": \"workshop-s3-policy\", 
    \"policyType\": 0,
    \"resources\": {\"path\": {\"values\": [\"*\"], \"isExcludes\": false, \"isRecursive\": true}},
    \"policyItems\": [{\"accesses\": [{\"type\": \"read\", \"isAllowed\": true}, {\"type\": \"write\", \"isAllowed\": true}], \"users\": [], \"groups\": [\"$WORKSHOP_GROUP\"]}]
  }"
```
