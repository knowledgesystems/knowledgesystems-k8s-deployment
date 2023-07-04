# Cluster setup

| Dependency | Version |
| ---------- | ------- |
| aws-cli    | 2.9.15  |
| k8s server | 1.27+   |
| k8s client | 1.27+   |
| helm       | 3.5.2   |

Please make sure the aws-cli and k8s is using desired version

1. At first, please check if you have the **eks-admin** group in your account: [https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/users](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/users), if you don't see it, ask help from an admin
2. Generate access key: [https://us-east-1.console.aws.amazon.com/iamv2/home#/security_credentials?section=IAM_credentials](https://us-east-1.console.aws.amazon.com/iamv2/home#/security_credentials?section=IAM_credentials)
3. Configure aws with newly generated access id and key

   ```bash
   aws configure
   ```

4. Update k8s config

    1. If you already have a profile that has an eks-admin group (PROFILE is your existing profile)

       ```bash
       aws --region us-east-1  eks update-kubeconfig  --name cbioportal-prod --role-arn arn:aws:sts::ACCOUNT_ID:role/eks-admin --profile [PROFILE]
       ```

    2. If you don't have an existing profile

        1. Generate k8s token (Please note to replace **ACCOUNT_ID** with your IAM account id)

           ```bash
           aws sts assume-role --role-arn "arn:aws:iam::ACCOUNT_ID:role/eks-admin" --role-session-name AWSCLI-Session
           ```

        2. (Optional) Ask an admin to add you to the authentication config map, admin can refer this command to add user

           ```bash
           kubectl edit cm aws-auth -n kube-system
           ```

        3. Update k8s config

           ```bash
           aws --region us-east-1  eks update-kubeconfig  --name cbioportal-prod
           ```
