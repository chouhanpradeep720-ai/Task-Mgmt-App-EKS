# AWS Secrets Manager Integration with Amazon EKS

This directory contains the configuration and documentation for integrating **AWS Secrets Manager with Amazon EKS using External Secrets Operator (ESO)**.

The goal is to securely manage PostgreSQL database credentials and application administrator credentials outside Kubernetes manifests.

## Table of Contents

- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [Technologies Used](#technologies-used)
- [Prerequisites](#prerequisites)
- [AWS Secrets Manager Configuration](#1-aws-secrets-manager-configuration)
- [Create IAM Policy](#2-create-iam-policy)
- [Create IAM Role](#3-create-iam-role)
- [Configure EKS Pod Identity](#4-configure-eks-pod-identity)
- [Install External Secrets Operator](#5-install-external-secrets-operator)
- [Configure SecretStore](#6-configure-secretstore)
- [Configure ExternalSecret](#7-configure-externalsecret)
- [Verify Secret Synchronization](#8-verify-secret-synchronization)
- [Configure Backend Deployment](#9-configure-backend-deployment)
- [Password Rotation](#10-password-rotation)
- [Troubleshooting](#troubleshooting)
- [Security Best Practices](#security-best-practices)
- [Conclusion](#conclusion)

---

## Architecture

```text
                   AWS Secrets Manager
                           |
                           | Stores credentials
                           |
                           v
                 Amazon EKS Pod Identity
                           |
                           | IAM Role Credentials
                           v
              External Secrets Operator
                           |
                           | Reads secret values
                           v
                    SecretStore
                           |
                           v
                   ExternalSecret
                           |
                           | Synchronizes credentials
                           v
                Kubernetes Secret
                  backend-aws-secret
                           |
                           | Environment Variables
                           v
                   Backend Deployment
                           |
                           | PostgreSQL Connection
                           v
                     Amazon RDS
```

### How It Works

1. Credentials are stored in AWS Secrets Manager.
2. Amazon EKS Pod Identity provides temporary AWS credentials to the External Secrets Operator.
3. An IAM role grants permission to read the required Secrets Manager secret.
4. The `SecretStore` configures access to AWS Secrets Manager.
5. The `ExternalSecret` retrieves selected properties from AWS Secrets Manager.
6. External Secrets Operator creates or updates the Kubernetes Secret.
7. The backend application consumes the Kubernetes Secret through environment variables.
8. The backend uses the database credentials to connect to Amazon RDS.

---

## Project Structure

```text
aws-secret-manager/
├── README.md
├── secret-store.yaml
└── external-secret.yaml
```

| File | Purpose |
|---|---|
| `README.md` | Documentation for the integration |
| `secret-store.yaml` | Configures the AWS Secrets Manager provider |
| `external-secret.yaml` | Defines which AWS secret properties are synchronized to Kubernetes |

---

## Technologies Used

- Amazon EKS
- AWS Secrets Manager
- AWS IAM
- Amazon EKS Pod Identity
- External Secrets Operator
- Kubernetes Secret
- Amazon RDS for PostgreSQL
- AWS CLI
- kubectl
- Helm

---

## Prerequisites

Make sure the following are available:

- An AWS account with the necessary IAM permissions.
- An existing EKS cluster.
- An existing AWS Secrets Manager secret.
- AWS CLI configured with valid credentials.
- `kubectl` configured to access the EKS cluster.
- Helm installed.
- An existing Kubernetes namespace named `task-management`.
- An existing PostgreSQL database on Amazon RDS.

### Verify AWS Account

```bash
aws sts get-caller-identity
```

### Verify AWS Region

```bash
aws configure get region
```

This project uses:

```text
Region: ap-south-1
Cluster: task-management-eks
Namespace: task-management
```

### Verify EKS Access

```bash
aws eks update-kubeconfig \
  --name task-management-eks \
  --region ap-south-1
```

```bash
kubectl get nodes
```

```bash
kubectl get namespaces
```

Verify that the `task-management` namespace exists.

```bash
kubectl get namespace task-management
```

---

## 1. AWS Secrets Manager Configuration

Create a secret in AWS Secrets Manager with the name:

```text
task-management/backend/prod
```

The secret contains the PostgreSQL connection details and application administrator credentials.

### Example Secret Structure

```json
{
  "username": "<DB_USERNAME>",
  "password": "<DB_PASSWORD>",
  "engine": "postgres",
  "host": "<RDS_ENDPOINT>",
  "port": 5432,
  "dbInstanceIdentifier": "<RDS_INSTANCE_ID>",
  "dbname": "task_management",
  "adminUsername": "<ADMIN_USERNAME>",
  "adminPassword": "<ADMIN_PASSWORD>"
}
```

Replace the placeholders with your actual values in AWS Secrets Manager.

**Do not commit actual passwords or secret values to GitHub.**

### Secret Property Mapping

| AWS Secrets Manager Property | Kubernetes Environment Variable | Purpose |
|---|---|---|
| `username` | `DB_USER` | PostgreSQL username |
| `password` | `DB_PASSWORD` | PostgreSQL password |
| `host` | `DB_HOST` | RDS endpoint |
| `port` | `DB_PORT` | PostgreSQL port |
| `dbname` | `DB_NAME` | Database name |
| `adminUsername` | `ADMIN_USERNAME` | Application administrator username |
| `adminPassword` | `ADMIN_PASSWORD` | Application administrator password |

### Important Difference Between Passwords

There are two separate passwords in this configuration:

- `password`: The PostgreSQL database password.
- `adminPassword`: The Task Management application's administrator login password.

Changing `adminPassword` does not change the PostgreSQL password.

Changing the `password` property in AWS Secrets Manager does not automatically change the actual PostgreSQL user's password. The database password and the stored secret value must match.

### Verify the Secret ARN

```bash
aws secretsmanager describe-secret \
  --secret-id task-management/backend/prod \
  --region ap-south-1 \
  --query 'ARN' \
  --output text
```

The secret ARN should belong to the AWS account in which the secret is stored.

---

## 2. Create IAM Policy

Create an IAM policy named:

```text
TaskManagementESOSecretRead
```

This policy allows External Secrets Operator to read the required secret.

### IAM Policy JSON

Use the actual AWS account ID where the secret exists.

For this project, the verified secret ARN is:

```text
arn:aws:secretsmanager:ap-south-1:892279937170:secret:task-management/backend/prod-rACzNe
```

Policy JSON:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:secretsmanager:ap-south-1:892279937170:secret:task-management/backend/prod-*"
    }
  ]
}
```

This policy grants read access to secrets matching the specified name prefix in the specified AWS account and region.

### Why Is This Policy Required?

External Secrets Operator needs permission to call:

```text
secretsmanager:GetSecretValue
```

Without this permission, the Kubernetes `ExternalSecret` cannot retrieve the AWS secret.

**Important:** If the secret is encrypted using a customer-managed AWS KMS key, the IAM role may also require the appropriate `kms:Decrypt` permission and the KMS key policy must allow access.

---

## 3. Create IAM Role

Create an IAM role named:

```text
TaskManagementESOSecretRead
```

Attach the policy:

```text
TaskManagementESOSecretRead
```

### Trust Relationship

Configure the role's trust policy to allow Amazon EKS Pod Identity to assume the role.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "pods.eks.amazonaws.com"
      },
      "Action": [
        "sts:AssumeRole",
        "sts:TagSession"
      ]
    }
  ]
}
```

The trust policy allows the EKS Pod Identity service to assume the role. The attached permissions policy controls which AWS resources the role can access.

---

## 4. Configure EKS Pod Identity

Amazon EKS Pod Identity provides temporary AWS credentials to Kubernetes workloads without requiring static AWS access keys in the application or Kubernetes manifests.

### Verify Pod Identity Agent

```bash
kubectl get pods -n kube-system | grep pod-identity
```

Verify that the EKS Pod Identity Agent pods are running.

### Create the Pod Identity Association

In the AWS Console:

1. Open **Amazon EKS**.
2. Select the cluster `task-management-eks`.
3. Open **Access** or **Pod Identity associations**, depending on the console layout.
4. Create a Pod Identity association.
5. Select the namespace `external-secrets`.
6. Select the service account `external-secrets`.
7. Select the IAM role `TaskManagementESOSecretRead`.
8. Create the association.

Use these exact values:

| Setting | Value |
|---|---|
| Cluster | `task-management-eks` |
| Namespace | `external-secrets` |
| Service Account | `external-secrets` |
| IAM Role | `TaskManagementESOSecretRead` |

### Verify the Association

```bash
aws eks list-pod-identity-associations \
  --cluster-name task-management-eks \
  --region ap-south-1
```

Inspect the association details:

```bash
aws eks describe-pod-identity-association \
  --cluster-name task-management-eks \
  --association-id <ASSOCIATION_ID> \
  --region ap-south-1
```

Replace `<ASSOCIATION_ID>` with the association ID returned by the previous command.

### Restart External Secrets Operator

If the association was created after External Secrets Operator started, restart the deployment so its pods are recreated.

```bash
kubectl rollout restart deployment external-secrets \
  -n external-secrets
```

Wait for the rollout:

```bash
kubectl rollout status deployment external-secrets \
  -n external-secrets
```

Verify the pods:

```bash
kubectl get pods -n external-secrets -o wide
```

Verify that the deployment's service account matches the association:

```bash
kubectl get deployment external-secrets \
  -n external-secrets \
  -o jsonpath='{.spec.template.spec.serviceAccountName}{"\n"}'
```

Expected output:

```text
external-secrets
```

---

## 5. Install External Secrets Operator

External Secrets Operator synchronizes external secret providers, such as AWS Secrets Manager, with Kubernetes Secrets.

If External Secrets Operator is already installed, skip the installation commands and verify the existing deployment.

### Add the Helm Repository

```bash
helm repo add external-secrets \
  https://charts.external-secrets.io
```

```bash
helm repo update
```

### Install External Secrets Operator

```bash
helm install external-secrets \
  external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace
```

If the release already exists, do not run the installation command again. Verify the existing release instead.

### Verify Installation

```bash
helm list -n external-secrets
```

```bash
kubectl get pods -n external-secrets
```

```bash
kubectl get crds | grep external-secrets
```

The External Secrets Operator pods should be running, and its custom resource definitions should be installed.

---

## 6. Configure SecretStore

The `SecretStore` defines how External Secrets Operator connects to AWS Secrets Manager.

File:

```text
secret-store.yaml
```

### YAML Configuration

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: aws-secretsmanager
  namespace: task-management
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-south-1
```

The provider uses AWS credentials available to the External Secrets Operator. In this EKS setup, those credentials are supplied through EKS Pod Identity.

### Apply the SecretStore

Run the command from the `aws-secret-manager` directory:

```bash
kubectl apply -f secret-store.yaml
```

### Verify SecretStore Status

```bash
kubectl get secretstore -n task-management
```

Inspect its conditions:

```bash
kubectl describe secretstore aws-secretsmanager \
  -n task-management
```

The `Ready` condition should become `True`.

If the store reports `AccessDenied`, check the IAM permissions policy and confirm that its resource ARN matches the actual secret ARN.

---

## 7. Configure ExternalSecret

The `ExternalSecret` specifies which properties to read from AWS Secrets Manager and which Kubernetes Secret to create.

File:

```text
external-secret.yaml
```

### YAML Configuration

```yaml
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: backend-external-secret
  namespace: task-management
spec:
  refreshInterval: 1h

  secretStoreRef:
    name: aws-secretsmanager
    kind: SecretStore

  target:
    name: backend-aws-secret
    creationPolicy: Owner

  data:
    - secretKey: DB_USER
      remoteRef:
        key: task-management/backend/prod
        property: username

    - secretKey: DB_PASSWORD
      remoteRef:
        key: task-management/backend/prod
        property: password

    - secretKey: DB_HOST
      remoteRef:
        key: task-management/backend/prod
        property: host

    - secretKey: DB_PORT
      remoteRef:
        key: task-management/backend/prod
        property: port

    - secretKey: DB_NAME
      remoteRef:
        key: task-management/backend/prod
        property: dbname

    - secretKey: ADMIN_USERNAME
      remoteRef:
        key: task-management/backend/prod
        property: adminUsername

    - secretKey: ADMIN_PASSWORD
      remoteRef:
        key: task-management/backend/prod
        property: adminPassword
```

### Configuration Explanation

| Field | Purpose |
|---|---|
| `refreshInterval: 1h` | Checks AWS Secrets Manager for updates at the configured refresh interval |
| `secretStoreRef` | References the SecretStore used to access AWS |
| `target.name` | Name of the Kubernetes Secret to create |
| `creationPolicy: Owner` | Makes the generated Secret owned by the ExternalSecret |
| `secretKey` | Key to create inside the Kubernetes Secret |
| `remoteRef.key` | AWS Secrets Manager secret name |
| `remoteRef.property` | Property to retrieve from the JSON secret |

### Apply the ExternalSecret

```bash
kubectl apply -f external-secret.yaml
```

Verify the resource:

```bash
kubectl get externalsecret -n task-management
```

Inspect its status:

```bash
kubectl describe externalsecret backend-external-secret \
  -n task-management
```

---

## 8. Verify Secret Synchronization

### Check the ExternalSecret

```bash
kubectl get externalsecret -n task-management
```

### Check the Kubernetes Secret

```bash
kubectl get secret backend-aws-secret \
  -n task-management
```

The `backend-aws-secret` Kubernetes Secret should be created after synchronization succeeds.

### Verify the Secret Keys Without Printing Their Values

```bash
kubectl get secret backend-aws-secret \
  -n task-management \
  -o json | jq -r '.data | keys[]'
```

Expected keys:

```text
ADMIN_PASSWORD
ADMIN_USERNAME
DB_HOST
DB_NAME
DB_PASSWORD
DB_PORT
DB_USER
```

This command prints the key names only, not the secret values.

### Check SecretStore Status

```bash
kubectl get secretstore aws-secretsmanager \
  -n task-management
```

### Check ExternalSecret Events

```bash
kubectl describe externalsecret backend-external-secret \
  -n task-management
```

Look for successful synchronization and a `Ready=True` condition.

---

## 9. Configure Backend Deployment

The backend Deployment must consume the Kubernetes Secret created by External Secrets Operator.

The application namespace is:

```text
task-management
```

The Kubernetes Secret is:

```text
backend-aws-secret
```

### Example Deployment Environment Variables

Add the following configuration to the backend container in `backend-deployment.yaml`:

```yaml
env:
  - name: DB_USER
    valueFrom:
      secretKeyRef:
        name: backend-aws-secret
        key: DB_USER

  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: backend-aws-secret
        key: DB_PASSWORD

  - name: DB_HOST
    valueFrom:
      secretKeyRef:
        name: backend-aws-secret
        key: DB_HOST

  - name: DB_PORT
    valueFrom:
      secretKeyRef:
        name: backend-aws-secret
        key: DB_PORT

  - name: DB_NAME
    valueFrom:
      secretKeyRef:
        name: backend-aws-secret
        key: DB_NAME

  - name: ADMIN_USERNAME
    valueFrom:
      secretKeyRef:
        name: backend-aws-secret
        key: ADMIN_USERNAME

  - name: ADMIN_PASSWORD
    valueFrom:
      secretKeyRef:
        name: backend-aws-secret
        key: ADMIN_PASSWORD
```

Add these variables to the existing backend container configuration. Do not replace the entire Deployment with this snippet.

### Apply the Deployment

If you edited the deployment manifest:

```bash
kubectl apply -f <BACKEND_DEPLOYMENT_FILE>
```

Replace `<BACKEND_DEPLOYMENT_FILE>` with the actual path to your backend Deployment YAML.

### Restart the Backend

If the backend is already running and its Secret values have changed, restart the Deployment to load the updated values into its environment.

```bash
kubectl rollout restart deployment backend-deployment \
  -n task-management
```

Wait for the rollout:

```bash
kubectl rollout status deployment backend-deployment \
  -n task-management
```

Verify the pods:

```bash
kubectl get pods -n task-management
```

**Note:** Kubernetes environment variables sourced from a Secret are not updated inside an already-running container when the Secret changes. Restart the backend pods to load updated values.

---

## 10. Password Rotation

AWS Secrets Manager and PostgreSQL maintain separate states. Updating a stored secret does not automatically change a PostgreSQL user's password.

### A. Rotate the Application Administrator Password

1. Update the `adminPassword` property in AWS Secrets Manager.
2. Allow External Secrets Operator to synchronize the updated property.
3. Verify that the Kubernetes Secret has been updated.
4. Restart the backend Deployment if it reads the administrator password from environment variables.
5. Test the application administrator login.

### B. Rotate the PostgreSQL Password

1. Change the PostgreSQL user's actual password in the database.
2. Update the `password` property in AWS Secrets Manager with the matching password.
3. Wait for External Secrets Operator to synchronize the value.
4. Verify that the Kubernetes Secret has been updated.
5. Restart the backend Deployment.
6. Verify that the backend can connect to PostgreSQL.

**Important:** Coordinate database password rotation carefully. If the database password and the secret value do not match, the backend may fail to authenticate to PostgreSQL.

---

## Troubleshooting

### 1. SecretStore Shows `InvalidProviderConfig`

Check the SecretStore:

```bash
kubectl describe secretstore aws-secretsmanager \
  -n task-management
```

If the error mentions EC2 Instance Metadata Service (IMDS), verify that:

- EKS Pod Identity Agent is installed and running.
- The Pod Identity association uses the correct cluster, namespace, and service account.
- The IAM role trust policy allows `pods.eks.amazonaws.com`.
- The External Secrets Operator pod was recreated after the association was created.

Check the association:

```bash
aws eks list-pod-identity-associations \
  --cluster-name task-management-eks \
  --region ap-south-1
```

### 2. ExternalSecret Shows `AccessDenied`

Example error:

```text
AccessDeniedException:
not authorized to perform secretsmanager:GetSecretValue
```

Verify the following:

- The correct IAM role is associated with the External Secrets Operator service account.
- The IAM permissions policy allows `secretsmanager:GetSecretValue`.
- The policy resource ARN matches the secret's actual ARN.
- The AWS account ID and region are correct.
- The secret is not restricted by a resource policy or permissions boundary.
- If a customer-managed KMS key is used, the role has the required decryption permission.

Verify the secret ARN:

```bash
aws secretsmanager describe-secret \
  --secret-id task-management/backend/prod \
  --region ap-south-1 \
  --query 'ARN' \
  --output text
```

### 3. Kubernetes Secret Is Not Created

Check the ExternalSecret:

```bash
kubectl describe externalsecret backend-external-secret \
  -n task-management
```

Check the SecretStore:

```bash
kubectl describe secretstore aws-secretsmanager \
  -n task-management
```

Verify that the property names in `external-secret.yaml` exactly match the JSON properties in AWS Secrets Manager.

### 4. Backend Cannot Connect to PostgreSQL

Check backend pod status:

```bash
kubectl get pods -n task-management
```

Inspect backend logs:

```bash
kubectl logs deployment/backend-deployment \
  -n task-management
```

Verify that:

- `DB_HOST` contains the correct RDS endpoint.
- `DB_PORT` is set to `5432`.
- `DB_NAME` is set to `task_management`.
- The database username and password match the actual PostgreSQL credentials.
- RDS security groups allow traffic from the EKS workload's network path.
- Network routes, DNS resolution, and PostgreSQL access are configured correctly.

Do not print database passwords in logs or share them in troubleshooting output.

### 5. Secret Changed but Backend Still Uses the Old Value

Check whether External Secrets Operator synchronized the latest value:

```bash
kubectl describe externalsecret backend-external-secret \
  -n task-management
```

Then restart the backend:

```bash
kubectl rollout restart deployment backend-deployment \
  -n task-management
```

Verify the rollout:

```bash
kubectl rollout status deployment backend-deployment \
  -n task-management
```

---

## Security Best Practices

- Never commit passwords, access keys, or other credentials to GitHub.
- Do not put actual secret values in Kubernetes YAML manifests.
- Use EKS Pod Identity instead of static AWS access keys for supported workloads.
- Grant the IAM role only the permissions required by External Secrets Operator.
- Restrict access to Secrets Manager secrets using narrowly scoped IAM policies.
- Keep AWS account IDs, region settings, and secret ARNs accurate.
- Avoid printing decoded Kubernetes Secret values in terminal output or logs.
- Restrict who can read Kubernetes Secrets through Kubernetes RBAC.
- Enable appropriate auditing and monitoring for AWS and Kubernetes access.
- Rotate credentials carefully and ensure database passwords remain synchronized with Secrets Manager.
- Use a customer-managed KMS key where required by your security design.

---

## Useful Commands

### Check EKS Nodes

```bash
kubectl get nodes
```

### Check External Secrets Operator

```bash
kubectl get pods -n external-secrets
```

### Check SecretStore

```bash
kubectl get secretstore -n task-management
```

### Check ExternalSecret

```bash
kubectl get externalsecret -n task-management
```

### Check Kubernetes Secret

```bash
kubectl get secret backend-aws-secret \
  -n task-management
```

### Check Backend Deployment

```bash
kubectl get deployment backend-deployment \
  -n task-management
```

### Check Backend Logs

```bash
kubectl logs deployment/backend-deployment \
  -n task-management
```

---

## Conclusion

This integration uses AWS Secrets Manager as the external source of truth for application and database credentials.

Amazon EKS Pod Identity provides temporary AWS credentials to External Secrets Operator, while IAM permissions restrict which secrets the operator can read. The `SecretStore` configures the AWS provider, and the `ExternalSecret` synchronizes the selected properties into the `backend-aws-secret` Kubernetes Secret.

The backend consumes those values through Kubernetes environment variables and uses them to connect to Amazon RDS and authenticate application administrators.

This approach separates sensitive credentials from application manifests and supports controlled secret updates and password rotation.