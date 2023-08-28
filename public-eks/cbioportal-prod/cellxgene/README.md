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

### Deployment, Pods, Services, & Ingress
```sh 
kubectl apply -f cellxgene-deployment.yaml -n cellxgene
kubectl apply -f cellxgene-ingress.yaml -n cellxgene
```

### Secrets
Will be switching to rolebased access soon
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: awscreds
type: Opaque
data:
  aws_access_key_id: <base64_encoded>
  aws_secret_access_key: <base64_encoded>
```

[1]: https://github.com/chanzuckerberg/cellxgene
[2]: <https://github.com/hweej/single-cell-tools/tree/main/cellxgene>

