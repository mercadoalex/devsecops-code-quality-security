#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# Install the DevSecOps toolchain shared by the BASE (and inherited by K8S)
# playground: Docker, Trivy, Semgrep, Gitleaks, cosign, Checkov, OpenTofu.
# Run as root during docker build. Idempotent where practical.
# -----------------------------------------------------------------------------
set -euo pipefail
LAB_USER="${LAB_USER:-laborant}"

echo "== Docker engine =="
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu noble stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update
apt-get install -y --no-install-recommends \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
usermod -aG docker "${LAB_USER}"
systemctl enable docker

echo "== Trivy (Aqua apt repo) =="
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key \
  | gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
https://aquasecurity.github.io/trivy-repo/deb generic main" \
  > /etc/apt/sources.list.d/trivy.list
apt-get update && apt-get install -y trivy

echo "== Gitleaks (release binary) =="
GL_VER="8.21.2"
curl -fsSL -o /tmp/gitleaks.tar.gz \
  "https://github.com/gitleaks/gitleaks/releases/download/v${GL_VER}/gitleaks_${GL_VER}_linux_x64.tar.gz"
tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks
chmod +x /usr/local/bin/gitleaks
rm -f /tmp/gitleaks.tar.gz

echo "== cosign (Sigstore release binary) =="
curl -fsSL -o /usr/local/bin/cosign \
  "https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64"
chmod +x /usr/local/bin/cosign

echo "== OpenTofu (release binary) =="
TOFU_VER="1.8.5"
curl -fsSL -o /tmp/tofu.zip \
  "https://github.com/opentofu/opentofu/releases/download/v${TOFU_VER}/tofu_${TOFU_VER}_linux_amd64.zip"
unzip -o /tmp/tofu.zip -d /tmp/tofu
install -m 0755 /tmp/tofu/tofu /usr/local/bin/tofu
rm -rf /tmp/tofu /tmp/tofu.zip

echo "== Python-based scanners via pipx for the lab user =="
# Semgrep (SAST) and Checkov (IaC) — installed into the lab user's pipx env.
sudo -u "${LAB_USER}" bash -lc 'pipx install semgrep || pipx upgrade semgrep'
sudo -u "${LAB_USER}" bash -lc 'pipx install checkov  || pipx upgrade checkov'

echo "== Pre-warm Trivy vulnerability DB (so the first student scan is fast) =="
trivy image --download-db-only || echo "WARN: DB pre-warm skipped (no network at build?)"

echo "== Pre-pull images used by lessons (best-effort; needs dockerd at build) =="
# These may be skipped at build time; the lesson tasks pull on demand as fallback.
echo "NOTE: pre-pull owasp-demo and zaproxy images in CI if dockerd is available:"
echo "  docker pull ghcr.io/iximiuz/labs/owasp-demo:latest"
echo "  docker pull ghcr.io/zaproxy/zaproxy:stable"
echo "  docker pull python:3.9-slim python:3.12-slim alpine:3.20"

echo "== clean apt =="
rm -rf /var/lib/apt/lists/*
echo "base-tools install complete"
