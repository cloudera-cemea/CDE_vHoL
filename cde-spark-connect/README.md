# Configuring Spark Connect Sessions

Learn how to configure a Spark Connect Session with CDE.

## Prerequisites

Before creating a Spark Connect Session, ensure the following steps are completed:

1. **Enable a Cloudera Data Engineering Service.**
2. **Create a CDE Virtual Cluster:**
   - Select "All Purpose (Tier 2)" in the Virtual Cluster option.
   - Choose Spark version 3.5.1.

## Configuration Steps

Perform the following steps on each user's machine:

1. **Create Configuration File:**
   - Create `~/.cde/config.yaml`.
   - Add `vcluster-endpoint` and `cdp-endpoint` parameters.
   - Example:

```yaml
cdp-endpoint: https://console-cdp.apps.example.com
credentials-file: /Users/exampleuser/.cde/credentials
vcluster-endpoint: https://ffws6v27.cde-c9b822vr.apps.example.com/dex/api/v1
```

2. **Create Access Key:**
   - Update the `credentials-file` parameter in `~/.cde/config.yaml` with the path to the credentials file.
   - Access keys configured with the default profile are supported.
   - Example:

```ini
[default]
cdp_access_key_id=571ff....
cdp_private_key=dvbYd....
```

## Creating a Spark Connect Session

You can create a Spark Connect Session using the following methods:

### Using the UI

- Follow the steps in "Creating Sessions in Cloudera Data Engineering."
- Select "Spark Connect (Tech Preview)" from the Type drop-down list.

### Using the CLI

- Run the following command:

```bash
cde session create --name [***SPARK-SESSION-NAME***] --type spark-connect
```

- To view all attributes of a cde session command, run:

```bash
cde session -h
```

### Downloading Required Files

1. On the CDE Home page, click "Sessions" and select the created Spark Connect Session.
2. Go to the "Connect" tab and download the required CDE TAR file and PySpark TAR file.

Note: The PySpark TAR file version must match the Virtual Cluster's Spark version.

### Setting Up Python Environment

1. Create a new Python virtual environment or use an existing one:

```bash
python3 -m venv cdeconnect
. cdeconnect/bin/activate
```

2. Install the TAR files

```bash
pip install [***CDECONNECT TARBALL***]
pip install [***PYSPARK TARBALL***]
```

Note: The "Copy Link" option can be used to retrieve a URL and download the client using cURL.

> [!NOTE] Example download link format:
> * https://service.cde-7zvcczml.se-sandb.a465-9q4k.cloudera.site/downloads/cde-connect/3.5.1/7.2.18.0/cdeconnect.tar.gz
> * https://service.cde-7zvcczml.se-sandb.a465-9q4k.cloudera.site/downloads/cde-connect/3.5.1/7.2.18.0/pyspark-3.5.1.tar.gz
