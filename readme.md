Project:

GitHub Runners hosted in AWS EKS

Architecture:

In amazon, there is a VPC with a private subnet and a public subnet. In the private subnet we have EKS clusters and infra, the only way to access them is from the public subnet. To connect  


SERVICES USED:

- EKS (Elastic Kubernetes Service): Infra to host and run runners
- ECR (Elastic Container Registry): Service to upload and pull private docker images from infra.
- Secrets Manager: Service to save auth credentials between runners and github and to connect to AWS project
- 

Security:

In order to deploy and build infra we authenticate to AWS through OIDC authentication, we have an IAM role for github runners specifically with a custom policy associated with it. 