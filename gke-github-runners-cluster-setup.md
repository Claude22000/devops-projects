# Create a GKE Cluster for GitHub Actions Runners

This document explains how to fix the `Compute Engine API has not been used` error and create a GKE cluster that will later be used to run self-hosted GitHub Actions runners through Actions Runner Controller (ARC).

## Current Error

When running:

```bash
gcloud container clusters create github-runners-cluster \
  --zone us-west1-a \
  --num-nodes 2 \
  --machine-type e2-standard-4 \
  --disk-size 80 \
  --release-channel regular \
  --enable-ip-alias
```

The following error appeared:

```text
ERROR: (gcloud.container.clusters.create) ResponseError: code=403, message=Google Compute Engine:
Compute Engine API has not been used in project directed-sonar-474004-j3 before or it is disabled.
```

## Why This Happens

GKE creates Compute Engine resources under the hood, such as VM instances for the cluster nodes.

Because of that, the project needs the **Compute Engine API** enabled before GKE can create the cluster.

The active project shown in Cloud Shell was:

```text
directed-sonar-474004-j3
```

So the APIs need to be enabled in that project.

## 1. Confirm the Active Project

Run:

```bash
gcloud config get-value project
```

Expected output:

```text
directed-sonar-474004-j3
```

If the wrong project is selected, change it with:

```bash
gcloud config set project directed-sonar-474004-j3
```

## 2. Enable Required APIs

Enable the APIs needed for GKE, Compute Engine, IAM, and Artifact Registry:

```bash
gcloud services enable compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  --project=directed-sonar-474004-j3
```

These APIs are needed for:

| API | Purpose |
|---|---|
| `compute.googleapis.com` | Required for GKE nodes, disks, networking, and VM resources |
| `container.googleapis.com` | Required for Google Kubernetes Engine |
| `artifactregistry.googleapis.com` | Needed later to store Docker images |
| `iam.googleapis.com` | Needed for identity, permissions, and Workload Identity Federation |

## 3. Verify That the APIs Are Enabled

Run:

```bash
gcloud services list --enabled \
  --project=directed-sonar-474004-j3 \
  | grep -E "compute|container|artifactregistry|iam"
```

You should see entries similar to:

```text
artifactregistry.googleapis.com
compute.googleapis.com
container.googleapis.com
iam.googleapis.com
```

If the APIs were just enabled, wait a minute or two before retrying the cluster creation.

## 4. Create the GKE Cluster

Create a GKE Standard cluster with 2 nodes:

```bash
gcloud container clusters create github-runners-cluster \
  --project directed-sonar-474004-j3 \
  --zone us-west1-a \
  --num-nodes 2 \
  --machine-type e2-standard-4 \
  --disk-size 80 \
  --release-channel regular \
  --enable-ip-alias
```

This creates:

| Setting | Value |
|---|---|
| Cluster name | `github-runners-cluster` |
| Project | `directed-sonar-474004-j3` |
| Zone | `us-west1-a` |
| Nodes | `2` |
| Machine type | `e2-standard-4` |
| Disk size | `80 GB` |
| Release channel | `regular` |
| VPC-native/IP alias | Enabled |

## 5. Connect kubectl to the Cluster

After the cluster is created, fetch the cluster credentials:

```bash
gcloud container clusters get-credentials github-runners-cluster \
  --project directed-sonar-474004-j3 \
  --zone us-west1-a
```

This updates your local kubeconfig so `kubectl` can talk to the cluster.

## 6. Validate the Cluster

Check that the nodes are available:

```bash
kubectl get nodes
```

Expected result:

```text
NAME                                      STATUS   ROLES    AGE   VERSION
gke-github-runners-cluster-default-...    Ready    <none>   ...   ...
gke-github-runners-cluster-default-...    Ready    <none>   ...   ...
```

You should see 2 nodes with status:

```text
Ready
```

## 7. Next Step: Install Actions Runner Controller

Once the cluster is ready, the next step is to install ARC using Helm.

The architecture will be:

```text
GitHub Actions job
        ↓
Actions Runner Controller listener in GKE
        ↓
Ephemeral runner pod is created
        ↓
Job runs
        ↓
Runner pod is destroyed
```

For Docker-based runners, this cluster should remain as **GKE Standard**, not Autopilot, because Docker-in-Docker usually requires privileged behavior that Autopilot may restrict.

## Useful Commands

Check active account:

```bash
gcloud auth list
```

Check active project:

```bash
gcloud config get-value project
```

List GKE clusters:

```bash
gcloud container clusters list --project directed-sonar-474004-j3
```

List nodes:

```bash
kubectl get nodes
```

List all pods across namespaces:

```bash
kubectl get pods -A
```

Delete the cluster if needed:

```bash
gcloud container clusters delete github-runners-cluster \
  --project directed-sonar-474004-j3 \
  --zone us-west1-a
```
