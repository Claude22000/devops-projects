# GitHub Actions Self-Hosted Runners on GKE with ARC

This document explains, step by step, what we did to create Docker-based GitHub Actions self-hosted runners on Google Cloud using:

- Google Kubernetes Engine (GKE)
- Workload Identity Federation
- GitHub Actions OIDC
- Artifact Registry
- Actions Runner Controller (ARC)
- Helm
- Kubernetes namespaces and secrets

The final goal is to have GitHub Actions jobs run on ephemeral runner pods inside a GKE cluster.

---

# Step 0 — Overall Architecture

The architecture is:

```text
GitHub Actions workflow
        ↓
GitHub OIDC token
        ↓
GCP Workload Identity Federation
        ↓
GCP service account impersonation
        ↓
GKE cluster
        ↓
Actions Runner Controller
        ↓
Ephemeral runner pods
        ↓
Job runs
        ↓
Runner pod is destroyed
```

For Docker-based runners, we used **GKE Standard**, not GKE Autopilot, because Docker-in-Docker commonly requires privileged behavior and Autopilot can restrict privileged workloads.

---

# Step 1 — Confirm the Active GCP Project

In Cloud Shell, we confirmed the active project:

```bash
gcloud config get-value project
```

The active project was:

```text
directed-sonar-474004-j3
```

If needed, set it explicitly:

```bash
gcloud config set project directed-sonar-474004-j3
```

---

# Step 2 — Enable Required GCP APIs

When trying to create the GKE cluster, we hit this error:

```text
ERROR: (gcloud.container.clusters.create) ResponseError: code=403, message=Google Compute Engine:
Compute Engine API has not been used in project directed-sonar-474004-j3 before or it is disabled.
```

This happened because GKE creates Compute Engine resources under the hood, such as VM nodes, disks, and networking components.

We enabled the required APIs:

```bash
gcloud services enable compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  --project=directed-sonar-474004-j3
```

These APIs are used for:

| API | Purpose |
|---|---|
| `compute.googleapis.com` | Required for GKE VM nodes, disks, and networking |
| `container.googleapis.com` | Required for Google Kubernetes Engine |
| `artifactregistry.googleapis.com` | Required for Docker image storage |
| `iam.googleapis.com` | Required for IAM and Workload Identity Federation |

Validate enabled services:

```bash
gcloud services list --enabled \
  --project=directed-sonar-474004-j3 \
  | grep -E "compute|container|artifactregistry|iam"
```

---

# Step 3 — Create a Workload Identity Pool

In GCP Console, we created a Workload Identity Pool.

The pool display name was:

```text
identity group
```

The pool ID was:

```text
id-identity-group
```

The pool is used to trust external identities from GitHub Actions.

---

# Step 4 — Create an OIDC Provider for GitHub

Inside the Workload Identity Pool, we added an OIDC provider.

Provider values:

```text
Provider type: OpenID Connect (OIDC)
Provider display name: GitHub
Provider ID: github
Issuer URL: https://token.actions.githubusercontent.com
JWK file: empty
Allowed audiences: empty
```

We left **Allowed audiences** empty so GCP uses the default expected audience.

The final provider path became:

```text
projects/458232171789/locations/global/workloadIdentityPools/id-identity-group/providers/github
```

Important note:

The provider ID is:

```text
github
```

Not:

```text
github-provider
```

This mattered later because using the wrong provider ID caused the error:

```text
invalid_target
The target service indicated by the "audience" parameters is invalid.
```

---

# Step 5 — Configure Provider Attribute Mapping

We configured the provider attribute mapping.

Minimum required mapping:

```text
google.subject = assertion.sub
```

We also used a custom attribute for repository owner or repository filtering.

Example using repository owner:

```text
attribute.custom_attribute = assertion.repository_owner
```

Example using exact repository:

```text
attribute.custom_attribute = assertion.repository
```

---

# Step 6 — Configure the Attribute Condition

At first, the provider creation failed with:

```text
The attribute condition must reference one of the provider's claims.
```

This happened because the provider needed an attribute condition that references a valid GitHub OIDC claim.

We fixed it by adding a condition.

Example condition for a GitHub owner:

```text
assertion.repository_owner == 'Claude22000'
```

Alternative condition for a specific repo:

```text
assertion.repository == 'Claude22000/Begotten-III-optimization-and-refactor-private'
```

For a lab, repository owner filtering is more flexible.

For tighter security, exact repository filtering is better.

---

# Step 7 — Choose the GCP Service Account

For practical testing, we decided to use the default Compute Engine service account:

```text
458232171789-compute@developer.gserviceaccount.com
```

This is not the cleanest production approach, but it works for practical labs.

Recommended production approach:

```text
github-actions-deployer@PROJECT_ID.iam.gserviceaccount.com
```

A dedicated service account should have only the minimum permissions needed.

---

# Step 8 — Allow GitHub to Impersonate the Service Account

The `principal://...` value is not used inside the workflow directly.

It is used in GCP IAM to grant GitHub Actions permission to impersonate the service account.

The principal format is:

```text
principal://iam.googleapis.com/projects/458232171789/locations/global/workloadIdentityPools/id-identity-group/subject/SUBJECT_ATTRIBUTE_VALUE
```

For a branch-specific subject, GitHub usually uses a subject like:

```text
repo:Claude22000/REPO_NAME:ref:refs/heads/main
```

Example:

```text
principal://iam.googleapis.com/projects/458232171789/locations/global/workloadIdentityPools/id-identity-group/subject/repo:Claude22000/Begotten-III-optimization-and-refactor-private:ref:refs/heads/main
```

Grant this principal the role:

```text
roles/iam.workloadIdentityUser
```

On the service account:

```text
458232171789-compute@developer.gserviceaccount.com
```

In GCP Console:

```text
IAM & Admin
  → Service Accounts
  → 458232171789-compute@developer.gserviceaccount.com
  → Permissions
  → Grant Access
```

Role:

```text
Workload Identity User
```

---

# Step 9 — Create GitHub Actions Secrets

In the GitHub repository:

```text
Settings
  → Secrets and variables
  → Actions
  → Secrets
```

Create:

```text
GCP_WORKLOAD_IDENTITY_PROVIDER
```

Value:

```text
projects/458232171789/locations/global/workloadIdentityPools/id-identity-group/providers/github
```

Create:

```text
GCP_SERVICE_ACCOUNT
```

Value:

```text
458232171789-compute@developer.gserviceaccount.com
```

Important:

Use the real provider ID:

```text
github
```

Not:

```text
github-provider
```

---

# Step 10 — Fix GitHub Actions Secret Usage

We originally had a mismatch:

```yaml
env:
  GCP_WORKLOAD_IDENTITY_PROVIDER: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
  GCP_SERVICE_ACCOUNT: ${{ secrets.GCP_SERVICE_ACCOUNT }}
```

But the action was using:

```yaml
with:
  workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
  service_account: ${{ vars.GCP_SERVICE_ACCOUNT }}
```

That caused:

```text
The GitHub Action workflow must specify exactly one of "workload_identity_provider" or "credentials_json"
```

The fix was to use `secrets` directly:

```yaml
with:
  workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
  service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
```

---

# Step 11 — Working GitHub Actions Auth Workflow

Example workflow for testing GCP authentication:

```yaml
name: Deploy GCP docker based runners

on:
  workflow_dispatch:
  push:
    branches:
      - feature/github-runners
      - main

permissions:
  id-token: write
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repo
        uses: actions/checkout@v4

      - name: Auth to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}

      - name: Setup gcloud
        uses: google-github-actions/setup-gcloud@v3

      - name: Test auth
        run: |
          gcloud auth list
          gcloud config list
```

Required workflow permissions:

```yaml
permissions:
  id-token: write
  contents: read
```

Without `id-token: write`, GitHub cannot issue the OIDC token.

---

# Step 12 — Create the GKE Cluster

We created a GKE Standard cluster with 2 nodes.

Command:

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

Cluster settings:

| Setting | Value |
|---|---|
| Cluster name | `github-runners-cluster` |
| Project | `directed-sonar-474004-j3` |
| Zone | `us-west1-a` |
| Node count | `2` |
| Machine type | `e2-standard-4` |
| Disk size | `80 GB` |
| Release channel | `regular` |
| IP alias | enabled |

---

# Step 13 — Connect kubectl to the Cluster

After creating the cluster, fetch credentials:

```bash
gcloud container clusters get-credentials github-runners-cluster \
  --project directed-sonar-474004-j3 \
  --zone us-west1-a
```

Validate nodes:

```bash
kubectl get nodes
```

Expected result:

```text
NAME                                      STATUS   ROLES    AGE   VERSION
gke-github-runners-cluster-default-...    Ready    <none>   ...   ...
gke-github-runners-cluster-default-...    Ready    <none>   ...   ...
```

---

# Step 14 — Install Helm

Validate Helm:

```bash
helm version
```

Validate kubectl:

```bash
kubectl version --client
```

Cloud Shell normally already includes both.

---

# Step 15 — Install the ARC Controller

ARC has two Helm components:

```text
1. Controller
2. Runner scale set
```

Install the controller in its own namespace:

```bash
NAMESPACE="arc-systems"

helm install arc \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

Validate:

```bash
kubectl get pods -n arc-systems
```

Expected:

```text
arc-gha-runner-scale-set-controller-xxxxx   1/1   Running
```

---

# Step 16 — Create the Runner Namespace

Create a separate namespace for runner pods:

```bash
kubectl create namespace arc-runners
```

Validate:

```bash
kubectl get namespaces
```

---

# Step 17 — Create a GitHub PAT Secret in Kubernetes

For the simplest repo-level setup, use a GitHub PAT.

Create a PAT with the required repository permissions.

Then in Cloud Shell:

```bash
read -s GITHUB_PAT
```

Paste the PAT and press Enter.

Create the Kubernetes secret:

```bash
kubectl create secret generic github-pat-secret \
  --namespace=arc-runners \
  --from-literal=github_token="${GITHUB_PAT}"
```

Validate:

```bash
kubectl get secret github-pat-secret -n arc-runners
```

Do not hardcode the PAT in YAML.

---

# Step 18 — Create the ARC Runner Scale Set Values File

Create a file called:

```text
arc-runner-values.yaml
```

Content:

```yaml
githubConfigUrl: "https://github.com/Claude22000/github-runners"
githubConfigSecret: github-pat-secret

minRunners: 0
maxRunners: 5

containerMode:
  type: "dind"
```

Explanation:

| Field | Purpose |
|---|---|
| `githubConfigUrl` | GitHub repo or org where the runners will be registered |
| `githubConfigSecret` | Kubernetes secret containing the GitHub PAT |
| `minRunners` | Minimum number of always-on runners |
| `maxRunners` | Maximum number of runners ARC can create |
| `containerMode.type: dind` | Enables Docker-in-Docker runners |

With:

```yaml
minRunners: 0
```

ARC will not keep idle runners alive.

It will create runner pods only when jobs are queued.

---

# Step 19 — Install the Runner Scale Set

The Helm release name becomes the value used by GitHub Actions in `runs-on`.

We used:

```text
gke-docker-runners
```

Install:

```bash
INSTALLATION_NAME="gke-docker-runners"
NAMESPACE="arc-runners"

helm install "${INSTALLATION_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f arc-runner-values.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

This means GitHub Actions workflows should use:

```yaml
runs-on: gke-docker-runners
```

---

# Step 20 — Validate ARC Installation

List Helm releases:

```bash
helm list -A
```

Expected:

```text
arc                  arc-systems   deployed
gke-docker-runners   arc-runners   deployed
```

Check controller pods:

```bash
kubectl get pods -n arc-systems
```

Check runner namespace:

```bash
kubectl get pods -n arc-runners
```

At first, runner pods may not exist because:

```yaml
minRunners: 0
```

The listener should exist, and ephemeral runner pods should appear only when a workflow job is queued.

---

# Step 21 — Test the GKE ARC Runner

Create this GitHub Actions workflow:

```yaml
name: Test GKE ARC Runner

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: gke-docker-runners

    steps:
      - name: Check runner
        run: |
          echo "Running inside GKE ARC runner"
          uname -a
          docker version
```

Run it manually from GitHub Actions.

While it is running, watch the runner pods:

```bash
kubectl get pods -n arc-runners -w
```

Expected behavior:

```text
1. GitHub workflow queues a job
2. ARC listener detects the queued job
3. ARC creates an ephemeral runner pod
4. Runner executes the job
5. Runner unregisters
6. Pod is destroyed
```

---

# Step 22 — Optional: Push a Docker Image to Artifact Registry

For Docker-based runner images or workloads, use Artifact Registry.

Create a Docker repository:

```bash
gcloud artifacts repositories create github-runners \
  --repository-format=docker \
  --location=us-west1 \
  --description="Docker images for GitHub runners"
```

Grant writer permissions to the service account:

```bash
gcloud artifacts repositories add-iam-policy-binding github-runners \
  --location=us-west1 \
  --member="serviceAccount:458232171789-compute@developer.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

Image format:

```text
us-west1-docker.pkg.dev/PROJECT_ID/github-runners/IMAGE_NAME:TAG
```

Example:

```text
us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
```

Configure Docker auth:

```bash
gcloud auth configure-docker us-west1-docker.pkg.dev --quiet
```

Build and push:

```bash
docker build -t us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest .

docker push us-west1-docker.pkg.dev/directed-sonar-474004-j3/github-runners/docker-runner:latest
```

---

# Troubleshooting

## Error: `workload_identity_provider` or `credentials_json` missing

Cause:

The workflow used `vars` but the values were stored as `secrets`.

Wrong:

```yaml
with:
  workload_identity_provider: ${{ vars.GCP_WORKLOAD_IDENTITY_PROVIDER }}
```

Correct:

```yaml
with:
  workload_identity_provider: ${{ secrets.GCP_WORKLOAD_IDENTITY_PROVIDER }}
```

---

## Error: `invalid_target`

Example:

```text
failed to generate Google Cloud federated token
invalid_target
The target service indicated by the "audience" parameters is invalid.
```

Cause:

The Workload Identity Provider path is wrong.

Correct value:

```text
projects/458232171789/locations/global/workloadIdentityPools/id-identity-group/providers/github
```

Wrong value:

```text
projects/458232171789/locations/global/workloadIdentityPools/id-identity-group/providers/github-provider
```

---

## Error: Compute Engine API disabled

Example:

```text
Compute Engine API has not been used in project before or it is disabled.
```

Fix:

```bash
gcloud services enable compute.googleapis.com \
  container.googleapis.com \
  artifactregistry.googleapis.com \
  iam.googleapis.com \
  --project=directed-sonar-474004-j3
```

---

## Runner pods do not appear

Check the ARC controller:

```bash
kubectl get pods -n arc-systems
kubectl logs -n arc-systems deploy/arc-gha-runner-scale-set-controller
```

Check runner namespace events:

```bash
kubectl get events -n arc-runners --sort-by=.lastTimestamp
```

Check Helm releases:

```bash
helm list -A
```

---

## Workflow stays queued

Possible causes:

1. The workflow is using the wrong `runs-on` label.
2. The runner scale set was installed with a different Helm release name.
3. The GitHub PAT does not have access to the repo.
4. ARC listener pod is not running.
5. The runner scale set failed to register with GitHub.

Check:

```bash
helm list -A
kubectl get pods -n arc-runners
kubectl get events -n arc-runners --sort-by=.lastTimestamp
```

Make sure the workflow uses:

```yaml
runs-on: gke-docker-runners
```

If the Helm release name is different, use that release name instead.

---

# Useful Commands

Check active GCP account:

```bash
gcloud auth list
```

Check active GCP project:

```bash
gcloud config get-value project
```

Set project:

```bash
gcloud config set project directed-sonar-474004-j3
```

List enabled APIs:

```bash
gcloud services list --enabled --project directed-sonar-474004-j3
```

List GKE clusters:

```bash
gcloud container clusters list --project directed-sonar-474004-j3
```

Get GKE credentials:

```bash
gcloud container clusters get-credentials github-runners-cluster \
  --project directed-sonar-474004-j3 \
  --zone us-west1-a
```

List nodes:

```bash
kubectl get nodes
```

List all pods:

```bash
kubectl get pods -A
```

List Helm releases:

```bash
helm list -A
```

Watch runner pods:

```bash
kubectl get pods -n arc-runners -w
```

Delete runner scale set:

```bash
helm uninstall gke-docker-runners -n arc-runners
```

Delete ARC controller:

```bash
helm uninstall arc -n arc-systems
```

Delete cluster:

```bash
gcloud container clusters delete github-runners-cluster \
  --project directed-sonar-474004-j3 \
  --zone us-west1-a
```

---

# Final State

At the end of this setup, we have:

```text
GCP Project:
directed-sonar-474004-j3

GKE Cluster:
github-runners-cluster

Cluster Zone:
us-west1-a

ARC Controller Namespace:
arc-systems

Runner Namespace:
arc-runners

Runner Scale Set Name:
gke-docker-runners

GitHub Actions runs-on label:
gke-docker-runners

Workload Identity Pool:
id-identity-group

OIDC Provider:
github

Service Account:
458232171789-compute@developer.gserviceaccount.com
```

Workflows can now target the GKE-based self-hosted runner with:

```yaml
runs-on: gke-docker-runners
```
