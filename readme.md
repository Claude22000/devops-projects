Project:

GitHub Runners hosted in AWS EKS

Architecture:

In amazon, there is a VPC with a private subnet routed to a NAT gateway to allow the github arc inside the cluster to connect to github.


SERVICES USED:

- EKS (Elastic Kubernetes Service): Infra to host and run runners
- ECR (Elastic Container Registry): Service to upload and pull private docker images from infra.
- Secrets Manager
- IAM for OIDC authentication

Security:

In order to deploy and build infra we authenticate to AWS through OIDC authentication, we have an IAM role to build and deploy github runners and upload artifacts related to its CI/CD pipeline specifically with a custom policy associated with it. 