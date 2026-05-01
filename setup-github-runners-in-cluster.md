# Install Actions Runner Controller (ARC) on GKE

This runbook starts from the point where the GKE cluster already exists.

The goal is to install **Actions Runner Controller (ARC)** on the existing GKE cluster and create an ephemeral GitHub Actions runner scale set.

Final result:

```yaml
runs-on: gke-docker-runners
```

---

# 0. Connect to your cluster first

Fetch the GKE cluster credentials so `kubectl` can communicate with the cluster:

```bash
gcloud container clusters get-credentials github-runners-cluster \
  --project directed-sonar-474004-j3 \
  --zone us-west1-a
```

Validate that the cluster is reachable:

```bash
kubectl get nodes
```

Expected result:

```text
NAME                                      STATUS   ROLES    AGE   VERSION
gke-github-runners-cluster-default-...    Ready    <none>   ...   ...
gke-github-runners-cluster-default-...    Ready    <none>   ...   ...
```

If the nodes show `Ready`, the cluster connection is working.

---

# 1. Validate Helm and kubectl

Cloud Shell usually already includes both tools, but verify them:

```bash
helm version
```

```bash
kubectl version --client
```

If both commands return versions, you can continue.

---

# 2. Install the ARC controller

ARC has two main Helm installations:

```text
1. ARC controller
2. Runner scale set
```

The controller watches GitHub job queues and manages runner pods inside Kubernetes.

Install the ARC controller into a dedicated namespace:

```bash
NAMESPACE="arc-systems"

helm install arc \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set-controller
```

Validate the controller pod:

```bash
kubectl get pods -n arc-systems
```

Expected result:

```text
arc-gha-runner-scale-set-controller-xxxxx   1/1   Running
```

---

# 3. Create the runner namespace

Create a separate namespace for the actual GitHub runner pods:

```bash
kubectl create namespace arc-runners
```

Validate:

```bash
kubectl get namespaces
```

You should see:

```text
arc-systems
arc-runners
```

---

# 4. Create the GitHub PAT secret in Kubernetes

For a simple repo-level setup, use a GitHub Personal Access Token.

The PAT is used by ARC to register runners with GitHub.

In Cloud Shell, read the PAT without showing it in the terminal:

```bash
read -s GITHUB_PAT
```

Paste your GitHub PAT and press Enter.

Then create the Kubernetes secret:

```bash
kubectl create secret generic github-pat-secret \
  --namespace=arc-runners \
  --from-literal=github_token="${GITHUB_PAT}"
```

Validate that the secret exists:

```bash
kubectl get secret github-pat-secret -n arc-runners
```

Expected result:

```text
NAME                TYPE     DATA   AGE
github-pat-secret   Opaque   1      ...
```

Do not hardcode the PAT inside a YAML file.

---

# 5. Create the runner scale set values file

Create a file named:

```text
arc-runner-values.yaml
```

Command:

```bash
cat > arc-runner-values.yaml <<'EOF'
githubConfigUrl: "https://github.com/Claude22000/Begotten-III-optimization-and-refactor-private"
githubConfigSecret: github-pat-secret

minRunners: 0
maxRunners: 5

containerMode:
  type: "dind"
EOF
```

Explanation:

| Field | Meaning |
|---|---|
| `githubConfigUrl` | GitHub repo or org where the runners will be registered |
| `githubConfigSecret` | Kubernetes secret that contains the GitHub PAT |
| `minRunners` | Minimum number of idle runners |
| `maxRunners` | Maximum number of ephemeral runners ARC can create |
| `containerMode.type: dind` | Enables Docker-in-Docker mode |

Because we set:

```yaml
minRunners: 0
```

ARC will not keep idle runners alive.

It will create runner pods only when jobs are queued.

---

# 6. Install the runner scale set

The Helm release name becomes the GitHub Actions `runs-on` label.

We will use:

```text
gke-docker-runners
```

Install the runner scale set:

```bash
INSTALLATION_NAME="gke-docker-runners"
NAMESPACE="arc-runners"

helm install "${INSTALLATION_NAME}" \
  --namespace "${NAMESPACE}" \
  --create-namespace \
  -f arc-runner-values.yaml \
  oci://ghcr.io/actions/actions-runner-controller-charts/gha-runner-scale-set
```

After this, GitHub Actions workflows can target the runner with:

```yaml
runs-on: gke-docker-runners
```

---

# 7. Validate the ARC installation

List all Helm releases:

```bash
helm list -A
```

Expected result:

```text
NAME                 NAMESPACE     STATUS
arc                  arc-systems   deployed
gke-docker-runners   arc-runners   deployed
```

Check the ARC controller:

```bash
kubectl get pods -n arc-systems
```

Check the runner namespace:

```bash
kubectl get pods -n arc-runners
```

At first, you may not see runner pods because:

```yaml
minRunners: 0
```

That is normal.

ARC should create runner pods only when a GitHub Actions job is queued.

---

# 8. Create a test GitHub Actions workflow

Create this workflow in your repo:

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

---

# 9. Watch runner pods

While the workflow is queued or running, watch the runner namespace:

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
6. Runner pod is destroyed
```

---

# 10. Troubleshooting commands

Check all pods:

```bash
kubectl get pods -A
```

Check ARC controller logs:

```bash
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

Describe runner pods if they fail:

```bash
kubectl describe pod -n arc-runners
```

---

# 11. Common issues

## Workflow stays queued

Possible causes:

```text
- The workflow is using the wrong runs-on label.
- The runner scale set Helm release has a different name.
- The GitHub PAT does not have access to the repo.
- The ARC listener is not running.
- The runner scale set failed to register with GitHub.
```

Validate:

```bash
helm list -A
kubectl get pods -n arc-runners
kubectl get events -n arc-runners --sort-by=.lastTimestamp
```

Make sure the workflow uses the same name as the Helm release:

```yaml
runs-on: gke-docker-runners
```

---

## Runner pods do not appear

Check if the listener exists:

```bash
kubectl get pods -n arc-runners
```

Check events:

```bash
kubectl get events -n arc-runners --sort-by=.lastTimestamp
```

Check controller logs:

```bash
kubectl logs -n arc-systems deploy/arc-gha-runner-scale-set-controller
```

---

## Docker does not work inside the runner

This setup uses:

```yaml
containerMode:
  type: "dind"
```

Docker-in-Docker usually needs privileged behavior.

That is why this setup should use **GKE Standard** instead of GKE Autopilot.

---

# 12. Cleanup commands

Uninstall the runner scale set:

```bash
helm uninstall gke-docker-runners -n arc-runners
```

Uninstall the ARC controller:

```bash
helm uninstall arc -n arc-systems
```

Delete namespaces if needed:

```bash
kubectl delete namespace arc-runners
kubectl delete namespace arc-systems
```

---

# Final State

After completing these steps, you should have:

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

GitHub Actions label:
runs-on: gke-docker-runners
```
