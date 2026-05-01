# ARC Runner Scale Set Standardization on GKE

This document covers the latest part of the setup:

1. Pulling a custom runner image from Google Artifact Registry.
2. Configuring ARC to use that image.
3. Standardizing runner configuration with Helm values.
4. Recommended structure for reusable environments and runner profiles.

---

# 0. Context

We already have:

```text
GKE cluster:
github-runners-cluster

Project:
directed-sonar-474004-j3

Zone:
us-west1-a

ARC controller namespace:
arc-systems

Runner namespace:
arc-runners

Runner scale set:
gke-docker-runners

GitHub repo:
https://github.com/Claude22000/github-runners
```

The ARC controller should remain installed and untouched.

The part we usually change is the **runner scale set** configuration.

---

# 1. Why the ARC controller can stay untouched

The ARC controller is the operator that manages runner scale sets.

It lives in:

```text
arc-systems
```

Example controller pod:

```text
arc-gha-rs-controller-xxxxx   1/1   Running
```

If this pod is healthy, do not uninstall it.

The runner scale set is the part that defines:

```text
- Which GitHub repo/org the runners register to
- Runner image
- min/max runners
- Docker-in-Docker mode
- CPU and memory
- volumes
- storage
- labels
```

So for most changes, update or reinstall:

```text
gke-docker-runners
```

not:

```text
arc
```

---

# 2. Pulling a custom runner image from Artifact Registry

The runner image will be stored in Artifact Registry.

Example image:

```text
us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
```

Image format:

```text
REGION-docker.pkg.dev/PROJECT_ID/REPOSITORY/IMAGE_NAME:TAG
```

Example:

```text
us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
```

---

# 3. Give GKE permission to pull from Artifact Registry

GKE pulls images through the node service account.

Find the node service account:

```bash
gcloud container clusters describe github-runners-cluster \
  --project directed-sonar-474004-j3 \
  --zone us-west1-a \
  --format="value(nodeConfig.serviceAccount)"
```

If it returns `default` or empty, the nodes may be using the default Compute Engine service account.

In this setup, the service account used was:

```text
458232171789-compute@developer.gserviceaccount.com
```

Grant Artifact Registry Reader:

```bash
gcloud artifacts repositories add-iam-policy-binding github-runners \
  --location=us-west1 \
  --project=directed-sonar-474004-j3 \
  --member="serviceAccount:458232171789-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.reader"
```

If this fails, you may need roles/artifactregistry.reader permission.

If the runner image is pushed by GitHub Actions or another CI process, that identity needs:

```text
roles/artifactregistry.writer
```

For pulling only, the cluster node service account needs:

```text
roles/artifactregistry.reader
```

---

# 4. Configure ARC to use the custom image

Edit:

```text
arc-runner-values.yaml
```

Basic custom image version:

```yaml
githubConfigUrl: "https://github.com/Claude22000/github-runners"
githubConfigSecret: github-pat-secret

minRunners: 1
maxRunners: 5

containerMode:
  type: "dind"

template:
  spec:
    containers:
      - name: runner
        image: us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
        command: ["/home/runner/run.sh"]
```

The `name: runner` container is important because ARC expects the runner container to use that name.

---

# 5. Apply the change

Upgrade the runner scale set:

```bash
helm upgrade gke-docker-runners \
  --namespace arc-runners \
  -f arc-runner-values.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

Validate:

```bash
kubectl get pods -n arc-systems
kubectl get pods -n arc-runners
```

If pods fail to pull the image:

```bash
kubectl describe pod -n arc-runners POD_NAME
```

Common image pull errors:

```text
ImagePullBackOff
ErrImagePull
403 Forbidden
404 Not Found
```

Meaning:

| Error | Likely cause |
|---|---|
| `403 Forbidden` | Node service account lacks `roles/artifactregistry.reader` |
| `404 Not Found` | Image path, repo, region, or tag is wrong |
| `ImagePullBackOff` | Kubernetes retried pulling and failed |
| `ErrImagePull` | First pull attempt failed |

---

# 6. Standardizing ARC runner configuration

Yes, standardization can be done with a Helm chart or Helm values.

At minimum, standardize these things:

```text
- Runner image
- CPU requests/limits
- Memory requests/limits
- Ephemeral storage requests/limits
- minRunners / maxRunners
- GitHub repo/org target
- Docker-in-Docker mode
- Node selectors
- Tolerations
- Service account usage
- Labels
- Secrets
```

For most practical setups, you do not need to write a full custom Helm chart immediately.

A cleaner first step is:

```text
Use the official ARC Helm chart
Maintain your own values files
```

Example structure:

```text
arc/
  values/
    dev.yaml
    prod.yaml
    docker-small.yaml
    docker-medium.yaml
    docker-large.yaml
  scripts/
    install-controller.sh
    install-runner-scale-set.sh
    upgrade-runner-scale-set.sh
```

---

# 7. Example standardized values file

Example:

```yaml
githubConfigUrl: "https://github.com/Claude22000/github-runners"
githubConfigSecret: github-pat-secret

minRunners: 1
maxRunners: 5

containerMode:
  type: "dind"

template:
  spec:
    containers:
      - name: runner
        image: us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
        command: ["/home/runner/run.sh"]
        resources:
          requests:
            cpu: "1"
            memory: "2Gi"
            ephemeral-storage: "10Gi"
          limits:
            cpu: "2"
            memory: "4Gi"
            ephemeral-storage: "20Gi"
```

This standardizes:

| Resource | Request | Limit |
|---|---:|---:|
| CPU | `1` core | `2` cores |
| Memory | `2Gi` | `4Gi` |
| Ephemeral storage | `10Gi` | `20Gi` |

---

# 8. Runner size profiles

You can create multiple runner scale sets for different workload sizes.

Example:

```text
gke-docker-small
gke-docker-medium
gke-docker-large
```

Then workflows can choose:

```yaml
runs-on: gke-docker-small
```

or:

```yaml
runs-on: gke-docker-large
```

Example structure:

```text
arc/values/docker-small.yaml
arc/values/docker-medium.yaml
arc/values/docker-large.yaml
```

## Small runner example

```yaml
githubConfigUrl: "https://github.com/Claude22000/github-runners"
githubConfigSecret: github-pat-secret

minRunners: 0
maxRunners: 5

containerMode:
  type: "dind"

template:
  spec:
    containers:
      - name: runner
        image: us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
        command: ["/home/runner/run.sh"]
        resources:
          requests:
            cpu: "500m"
            memory: "1Gi"
            ephemeral-storage: "5Gi"
          limits:
            cpu: "1"
            memory: "2Gi"
            ephemeral-storage: "10Gi"
```

## Medium runner example

```yaml
githubConfigUrl: "https://github.com/Claude22000/github-runners"
githubConfigSecret: github-pat-secret

minRunners: 1
maxRunners: 5

containerMode:
  type: "dind"

template:
  spec:
    containers:
      - name: runner
        image: us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
        command: ["/home/runner/run.sh"]
        resources:
          requests:
            cpu: "1"
            memory: "2Gi"
            ephemeral-storage: "10Gi"
          limits:
            cpu: "2"
            memory: "4Gi"
            ephemeral-storage: "20Gi"
```

## Large runner example

```yaml
githubConfigUrl: "https://github.com/Claude22000/github-runners"
githubConfigSecret: github-pat-secret

minRunners: 0
maxRunners: 3

containerMode:
  type: "dind"

template:
  spec:
    containers:
      - name: runner
        image: us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
        command: ["/home/runner/run.sh"]
        resources:
          requests:
            cpu: "2"
            memory: "4Gi"
            ephemeral-storage: "20Gi"
          limits:
            cpu: "4"
            memory: "8Gi"
            ephemeral-storage: "40Gi"
```

Install each one as a different scale set:

```bash
helm install gke-docker-small \
  --namespace arc-runners \
  -f arc/values/docker-small.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

```bash
helm install gke-docker-medium \
  --namespace arc-runners \
  -f arc/values/docker-medium.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

```bash
helm install gke-docker-large \
  --namespace arc-runners \
  -f arc/values/docker-large.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

Then use:

```yaml
runs-on: gke-docker-medium
```

---

# 9. Standardizing storage

There are two types of storage to think about.

## 1. Ephemeral storage

This is local pod/node storage used during jobs.

Useful for:

```text
- Docker layers
- Build caches
- Temporary files
- npm/pip/maven caches
```

Example:

```yaml
resources:
  requests:
    ephemeral-storage: "10Gi"
  limits:
    ephemeral-storage: "20Gi"
```

This is enough for many CI jobs.

## 2. Persistent volumes

Use persistent storage only if you really need data to survive between pods.

For ephemeral GitHub runners, persistent volumes are usually not recommended because each runner should be disposable.

Better pattern:

```text
Use external caches:
- GitHub Actions cache
- Artifact Registry cache images
- Cloud Storage
- Dependency proxy/cache
```

Use persistent volumes only for special cases.

---

# 10. Standardizing node pools

For better control, create dedicated GKE node pools for ARC runners.

Example:

```text
default-pool
runner-pool-small
runner-pool-large
```

Benefits:

```text
- Isolate CI workload from app workloads
- Tune machine types for build workloads
- Use autoscaling per node pool
- Apply taints/tolerations
- Improve cost control
```

Example runner pod targeting a node pool:

```yaml
template:
  spec:
    nodeSelector:
      cloud.google.com/gke-nodepool: runner-pool-medium
    containers:
      - name: runner
        image: us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
        command: ["/home/runner/run.sh"]
```

If using taints:

```yaml
template:
  spec:
    tolerations:
      - key: "workload"
        operator: "Equal"
        value: "github-runners"
        effect: "NoSchedule"
```

---

# 11. Standardizing security

Recommended security controls:

```text
- Use GitHub App instead of PAT for production
- Use a dedicated GCP service account for nodes
- Grant only roles/artifactregistry.reader to node SA for image pulls
- Avoid broad Editor permissions
- Keep runner pods ephemeral
- Avoid mounting hostPath unless absolutely required
- Limit maxRunners to control spend
- Use separate scale sets for different trust levels
```

For example:

```text
trusted-main-runners
pr-runners
docker-build-runners
deployment-runners
```

Avoid running untrusted pull request code on highly privileged runners.

---

# 12. Standardizing secrets

The current setup uses:

```text
github-pat-secret
```

Long-term, a GitHub App is cleaner than a PAT.

Possible secret standards:

```text
github-pat-secret-dev
github-pat-secret-prod
github-app-secret
```

For production, prefer GitHub App auth.

---

# 13. Standardizing installation commands

Use scripts.

Example:

```text
scripts/install-arc-controller.sh
scripts/install-runner-scale-set.sh
scripts/upgrade-runner-scale-set.sh
```

## install-arc-controller.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="arc-systems"

helm upgrade --install arc \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

## upgrade-runner-scale-set.sh

```bash
#!/usr/bin/env bash
set -euo pipefail

INSTALLATION_NAME="${1:-gke-docker-runners}"
VALUES_FILE="${2:-arc-runner-values.yaml}"
NAMESPACE="arc-runners"

helm upgrade --install "${INSTALLATION_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f "${VALUES_FILE}" \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

Usage:

```bash
./scripts/upgrade-runner-scale-set.sh gke-docker-runners arc-runner-values.yaml
```

---

# 14. When to create your own Helm chart

You do not need your own chart immediately.

Recommended progression:

```text
Phase 1:
Official ARC chart + values files

Phase 2:
Wrapper Helm chart that templates multiple ARC scale sets

Phase 3:
Terraform manages GKE, Artifact Registry, IAM, and Helm releases
```

Create your own Helm chart when:

```text
- You have multiple runner profiles
- You want reusable templates
- You want environment-specific config
- You want to standardize across repos/orgs
- You want CI/CD to deploy ARC config automatically
```

A wrapper chart could template:

```text
- Multiple gha-runner-scale-set releases
- Resource profiles
- Secrets
- nodeSelector/tolerations
- image versions
- min/max runners
```

But for now, `values.yaml` files are enough.

---

# 15. Recommended standard folder structure

```text
github-runners/
  arc/
    values/
      docker-small.yaml
      docker-medium.yaml
      docker-large.yaml
    scripts/
      install-controller.sh
      upgrade-scale-set.sh
    README.md
  docker/
    Dockerfile
  .github/
    workflows/
      build-runner-image.yaml
      test_standard_runners.yaml
```

---

# 16. Final recommendation

For this lab, standardize with:

```text
- Official ARC Helm charts
- One values file per runner profile
- Custom runner image from Artifact Registry
- Dedicated node service account with Artifact Registry Reader
- minRunners/maxRunners per profile
- CPU/memory/ephemeral-storage requests and limits
```

Do not build a custom chart yet unless you want to manage many runner profiles.

The immediate next good setup is:

```text
gke-docker-small
gke-docker-medium
gke-docker-large
```

Each one has its own values file and its own `runs-on` label.
