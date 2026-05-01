# EKS Access Guide (AWS CLI + kubectl)

## 1. Verify AWS identity

``` bash
aws sts get-caller-identity
```

------------------------------------------------------------------------

## 2. Check cluster (optional)

``` bash
aws eks describe-cluster   --name <cluster-name>   --region <region>
```

------------------------------------------------------------------------

## 3. Create IAM role (if needed)

Example: `eks-admin`

Attach policy: - AmazonEKSClusterAdminPolicy

------------------------------------------------------------------------

## 4. Create Access Entry in EKS

``` bash
aws eks create-access-entry   --cluster-name <cluster-name>   --principal-arn arn:aws:iam::<account>:role/eks-admin   --type STANDARD
```

------------------------------------------------------------------------

## 5. Attach access policy

``` bash
aws eks associate-access-policy   --cluster-name <cluster-name>   --principal-arn arn:aws:iam::<account>:role/eks-admin   --policy-arn arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy   --access-scope type=cluster
```

------------------------------------------------------------------------

## 6. Generate kubeconfig (MOST IMPORTANT)

``` bash
aws eks update-kubeconfig   --name <cluster-name>   --region <region>   --role-arn arn:aws:iam::<account>:role/eks-admin
```

------------------------------------------------------------------------

## 7. Switch context

``` bash
kubectl config use-context <context-name>
```

------------------------------------------------------------------------

## 8. Test connection

``` bash
kubectl get nodes
```

------------------------------------------------------------------------

# 🧠 Flow summary

AWS IAM → Role → EKS Access Entry → kubeconfig → kubectl → cluster

------------------------------------------------------------------------

# ⚡ One-liner

``` bash
aws eks update-kubeconfig --name <cluster> --region <region> --role-arn <role>
kubectl get nodes
```
