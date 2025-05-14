# Cloudera Data Engineering Hands-on Lab CEMEA Setup Guide

This document provides a step-by-step guide to setting up Cloudera Services and Configurations for running the Hands-on Lab. The setup includes creating and configuring Cloudera services, setting up Ranger permissions and uploading workshop data. The setup is designed to be executed on a Linux-based system (e.g. macOS) with the necessary tools installed. The setup guide covers:

- Cloudera on Cloud Environment & Data Lake w/ RAZ enabled
- Cloudera Data Engineering Service with Public Endpoints/CIDR
- Ranger Permissions for S3 Access
- Workshop Data Upload
- Virtual Clusters

The following prequisites are required to execute the setup:

- Terraform for deploying AWS prequisites and Cloudera infrastructure
- AWS CLI with access to the AWS account (required for AWS prerequisites deployment via Terraform)
- CDP CLI with access to the Cloudera tenant (required for Cloudera on Cloud deployment via Terraform)

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

1. Create the Data Engineering Service via the Control Plane UI with the following configurations:

- Enable Public Load Balancer
- Disable Default Virtual Cluster
- Everything else can be left with default values

1. Create the Virtual Clusters by setting the variables in the create_vclusters.sh script:

```bash
...
N_VCLUSTERS=<number-participants>
...
```

- Run the script to create virtual clusters:

```bash
bash setup.sh
```

### 3. Configure Cloudera and Ranger Permissions

#### Cloudera User Management

For the Cloudera environment, enable access to the workshop user group by assigning following roles:

- EnvironmentUser
- DEUser
- DWUser
- MLUser

#### Ranger

Add the workshop user group to the following Ranger policies for SQL/S3 access:

- hadoop sql: all storage url, all url, database table columns
- s3: all bucket path

### 4. Upload workshop data

- Upload the workshop data to your bucket:

```bash
aws s3 cp data s3://<bucket-name>/cde-hol-source --recursive
```

- Validate the bucket has the data in the correct structure:

```bash
$ aws s3 ls s3://<bucket-name>/cde-hol-source --profile <aws-cli-profile> --recursive

2025-01-23 12:50:55     442307 cde-hol-source/2021/customers.csv
2025-01-23 12:50:55      90249 cde-hol-source/2021/sales.csv
2025-01-23 12:50:55        170 cde-hol-source/2022/customers.csv
2025-01-23 12:50:55     238087 cde-hol-source/2022/sales.csv
```

- Edit the `parameters.conf` file with the bucket name

```
[general]
s3BucketName: s3a://<bucket-name>/cde-hol-source
```
