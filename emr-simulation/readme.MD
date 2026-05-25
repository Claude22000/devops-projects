A more scalable version used by multiple users should have this architecture:

Amazon Load Balancer -> ingress controller -> service -> webapp <-> backend api <-> k8s jobs -> RDS (and the API would retrieve information from the RDS database aswell)


But for now i will limit it to use only and the load balancer and domain name will be skipped aswell due to costs reasons

This would be the current connection architecture

service -> webapp <-> backend api <-> k8s jobs -> RDS (the API would retrieve information from the RDS database aswell)
              