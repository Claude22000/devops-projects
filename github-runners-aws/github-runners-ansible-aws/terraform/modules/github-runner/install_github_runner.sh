#!/bin/bash
set -euo pipefail

GITHUB_OWNER="${GITHUB_OWNER}"
GITHUB_REPO="${GITHUB_REPO}"
GITHUB_PAT="${GITHUB_PAT}"
RUNNER_VERSION="${RUNNER_VERSION}"

RUNNER_BASE_NAME="${RUNNER_NAME}"
RUNNER_HOSTNAME=$(hostname -s)
RUNNER_NAME="$${RUNNER_BASE_NAME}-$${RUNNER_HOSTNAME}"

RUNNER_LABELS="${RUNNER_LABELS}"
RUNNER_USER="${RUNNER_USER}"
RUNNER_DIR="${RUNNER_DIR}"

export DEBIAN_FRONTEND=noninteractive

if command -v apt-get >/dev/null 2>&1; then
  apt-get update -y
  apt-get install -y curl jq tar sudo git libicu-dev libssl-dev zlib1g krb5-user
elif command -v dnf >/dev/null 2>&1; then
  dnf update -y
  dnf install -y curl jq tar sudo git libicu openssl-libs krb5-libs zlib
elif command -v yum >/dev/null 2>&1; then
  yum update -y
  yum install -y curl jq tar sudo git libicu openssl-libs krb5-libs zlib
fi

id "$RUNNER_USER" >/dev/null 2>&1 || useradd -m -s /bin/bash "$RUNNER_USER"

mkdir -p "$RUNNER_DIR"
chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_DIR"

cd "$RUNNER_DIR"

curl -L -o actions-runner-linux-x64.tar.gz \
  "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

tar xzf actions-runner-linux-x64.tar.gz
chown -R "$RUNNER_USER:$RUNNER_USER" "$RUNNER_DIR"

REG_TOKEN=$(curl -sX POST \
  -H "Authorization: Bearer ${GITHUB_PAT}" \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/actions/runners/registration-token" \
  | jq -r .token)

if [ -z "$REG_TOKEN" ] || [ "$REG_TOKEN" = "null" ]; then
  echo "Failed to get GitHub runner registration token"
  exit 1
fi

sudo -u "$RUNNER_USER" ./config.sh \
  --url "https://github.com/${GITHUB_OWNER}/${GITHUB_REPO}" \
  --token "$REG_TOKEN" \
  --name "$RUNNER_NAME" \
  --labels "$RUNNER_LABELS" \
  --unattended \
  --replace

./svc.sh install "$RUNNER_USER"
./svc.sh start

echo "GitHub runner installed and connected."