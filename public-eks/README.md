# Cluster setup

- Make sure the latest aws-cli is installed, the current version of aws used at the time is 2.9.15

    ```bash
    aws --region us-east-1  eks update-kubeconfig  --name cbioportal-prod
    ```

- At first, please make sure to have the **eks-admin** group in your account: [https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/users](https://us-east-1.console.aws.amazon.com/iamv2/home?region=us-east-1#/users), if you don't see it, ask help from an admin
- Generate access key: [https://us-east-1.console.aws.amazon.com/iamv2/home#/security_credentials?section=IAM_credentials](https://us-east-1.console.aws.amazon.com/iamv2/home#/security_credentials?section=IAM_credentials)
- Configure aws with newly generated access id and key

    ```bash
    aws configure
    ```

- Update k8s config
    - If you already have a profile that has an eks-admin group (PROFILE is your existing profile)

        ```bash
        aws --region us-east-1  eks update-kubeconfig  --name cbioportal-prod --role-arn arn:aws:sts::070278699608:role/eks-admin --profile [PROFILE]
        ```

    - else
        - Generate k8s token (Please note to replace **ACCOUNT_ID** with your IAM account id)

            ```bash
            aws sts assume-role --role-arn "arn:aws:iam::ACCOUNT_ID:role/eks-admin" --role-session-name AWSCLI-Session
            ```

        - Ask an admin to add you to the authentication config map, admin can refer this command to add user

            ```bash
            kubectl edit cm aws-auth -n kube-system
            ```

        - Update k8s config

            ```bash
            aws --region us-east-1  eks update-kubeconfig  --name cbioportal-prod
            ```