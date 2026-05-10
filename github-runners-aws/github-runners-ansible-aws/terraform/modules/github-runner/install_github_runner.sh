#!/bin/bash
set -euo pipefail

# ====== CONFIG ======
GITHUB_OWNER="${GITHUB_OWNER}"
GITHUB_REPO="${GITHUB_REPO}"
GITHUB_PAT="${GITHUB_PAT}"
RUNNER_VERSION="${RUNNER_VERSION}"
RUNNER_NAME="${RUNNER_NAME}-$(hostname)"
RUNNER_LABELS="${RUNNER_LABELS}"
RUNNER_USER="${RUNNER_USER}"
RUNNER_DIR="${RUNNER_DIR}"
# ====================

export DEBIAN_FRONTEND=noninteractive

# Install dependencies
if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y curl jq tar sudo git
elif command -v yum >/dev/null 2>&1; then
  yum update -y
  yum install -y curl jq tar sudo git
fi

# Create runner user
id "$RUNNER_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$RUNNER_USER"

mkdir -p "$RUNNER_DIR"
chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_DIR"

cd "$RUNNER_DIR"

# Download runner
curl -L -o actions-runner-linux-x64.tar.gz \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

tar xzf actions-runner-linux-x64.tar.gz
chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_DIR"

# Get temporary registration token
REG_TOKEN=$(curl -sX POST \
  -H "Authorization: Bearer ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token" \
  | jq -r .token)

# Configure runner
sudo -u "$RUNNER_USER" ./config.sh \
  --url "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}" \
  --token "$REG_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --unattended \
  --replace

# Install and start as systemd service
./svc.sh install "$RUNNER_USER"
./svc.sh start

echo "GitHub runner installed and connected."