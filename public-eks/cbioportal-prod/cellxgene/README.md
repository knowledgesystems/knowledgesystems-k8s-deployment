### Description
A kubernetes configuration for the deployment of the [cellxgene][1] annotation
viewer application via [docker][2] image

### Datasets on file
1. pbmc3k.h5ad
2. scRNA_rds_Ovarian_Malignant_cluster_object.h5ad
3. scRNA_rds_Ovarian_nonMalignant_cluster_object.h5ad

### Namespace
```sh 
kubectl apply -f cellxgene-namespace.yaml -n cellxgene
```
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: cellxgene
```

# Allow access to s3 bucket data
cellxgene can launch h5ad files in multiple ways.
```sh
cellxgene launch /path/to/mydata.h5ad
cellxgene launch https://<somehost>/mydataset.h5ad
cellxgene launch s3://<bucket>/prefix (via boto3)
cellxgene launch gs://<bucket>/prefix (via gcsfs)
```

### Method (1): AWS access keys via k8s Secrets
`cellxgene-deployment.yaml` is configured to fetch `cellxgene-creds` from the k8s
secrets store
```yaml
# cellgene-secrets.yaml
# Create this file but don't commit to repo
apiVersion: v1
kind: Secret
metadata:
  name: cellxgene-creds
type: Opaque
data:
  aws_access_key_id: <base64_encoded>
  aws_secret_access_key: <base64_encoded>
```
```sh 
kubectl apply -f cellxgene-secrets.yaml -n cellxgene
```
### Method (2) "Preferred": AWS IAM roles for k8s service accounts
Refer to: [iam-roles-for-service-accounts][3]
```sh 
# Create aws iam policy
aws iam create-policy --policy-name cellxgene-s3-access-policy  --policy-document file://cellxgene-s3-access-policy.json --description "Policy defining S3 permissions for IAM-K8ServiceRole used by cellxgene services"
```
```sh
# Create the AWS IAM role 
# Create the k8s serviceRole 
# Attach permissions policy 
# Link IAM + K8ServiceRole together
# In a single command:
eksctl create iamserviceaccount --name cellxgene-service-account --namespace cellxgene  --cluster cbioportal-prod --role-name cellxgene-service-role --attach-policy-arn arn:aws:iam::070278699608:policy/cellxgene-s3-access-policy --approve
```
```sh
# Confirm role and service account are configured correctly
aws iam get-role --role-name cellxgene-service-role --query Role.AssumeRolePolicyDocument --output json

# Confirm policy is attached to the role 
aws iam list-attached-role-policies --role-name cellxgene-service-role

# View the default version of the policy
export policy_arn=arn:aws:iam::070278699608:policy/cellxgene-s3-access-policy
aws iam get-policy --policy-arn $policy_arn

aws iam get-policy-version --policy-arn arn:aws:iam::070278699608:policy/cellxgene-s3-access-policy --version-id v1 --output json
kubectl describe serviceaccount cellxgene-service-account -n cellxgene
```
```
# Configure the pods
pods
```

### Deployment, Pods, Services, & Ingress
```sh 
kubectl apply -f cellxgene-deployment.yaml -n cellxgene
kubectl apply -f cellxgene-ingress.yaml -n cellxgene
```

[1]: https://github.com/chanzuckerberg/cellxgene
[2]: https://github.com/hweej/single-cell-tools/tree/main/cellxgene
[3]: https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html

