for a more scalable version used by multiple users we should have this architecture:

Amazon Load Balancer -> ingress controller -> service -> webapp -> backend api -> k8s jobs -> RDS
                                                            ^---------|-^--------------------|