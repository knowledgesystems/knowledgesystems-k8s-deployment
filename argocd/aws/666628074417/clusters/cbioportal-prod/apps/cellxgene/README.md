# Protecting ingress routes
1. `nginx-ingress` can use [basic-auth][1] for authentication and will
refer to an `EKS Secret` for the credentials.
2. An `EKS Secret` can have one or more username/password pairs

```
# auth file, contents are base64 encoded and included under secret/data.auth
user1:<hashed_password>
user2:<hashed_password>
```

#### Set the kubectl namespace context
```sh
KUBE_NAMESPACE=cellxgene
kubectl config set-context --current --namespace=$KUBE_NAMESPACE
# or
kubens $KUBE_NAMESPACE
```

### Creating a new username/password pair
Create a hashed password with htppasswd
```sh
htpasswd -nb <username> <password>
# OR Prompt user for password, save to new auth file
htpasswd -c auth <username>
```

### Creating a new secret with one username/password
1. Create a hashed username/password pair using `htpasswd`
2. Adding the new username/password pair to `auth` file
```
# auth file
user1:<hashed_password>
user2:<hashed_password>
new_user3:<hashed_password>
```

### Add a new user to an existing secret for multi-user setup
Useful for providing multiple credentials for the same ingress object
1. Get the current auth map from secrets
```sh
SECRET_NAME=test-credentials
kubectl get secrets/$SECRET_NAME --template={{.data.auth}} | base64 -d > auth
```
2. Add username/password pair to the `auth` file
```
# auth file
user1:<hashed_password>
user2:<hashed_password>
new_user3:<hashed_password>
```

### Create/Update/Apply the EKS secret from the auth file
The `auth` file can contain one or more username/password pairs.
It is important that this file be named auth. See [basic-auth][1]
```sh
kubectl create secret generic $SECRET_NAME --from-file=auth 
```

### nginx-ingress annotations
```yaml
# Add annotations to the ingress object you want to protect
nginx.ingress.kubernetes.io/auth-type: basic
nginx.ingress.kubernetes.io/auth-secret: <name_of_secret>
nginx.ingress.kubernetes.io/auth-realm: 'Authentication Required'
```

##### Manage plaintext credentials in secrets manager
TBD
##### Optional, hash credentials list from plaintext
TBD

[1]: https://kubernetes.github.io/ingress-nginx/examples/auth/basic/ "basic-auth"
