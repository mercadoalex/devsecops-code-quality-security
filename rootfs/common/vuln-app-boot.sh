#!/usr/bin/env bash
# Boot helper for the DevSecOps demo vulnerable app.
# Builds the local images (once) and starts the VULNERABLE variant on :8080 so
# the OWASP Top 10 and ZAP lessons have a target ready without any pull.
# The student starts the PATCHED variant themselves (challenge) on :9090.
#
# Idempotent: safe to run on every boot. Build-safe: all failures are logged,
# never fatal.
set -uo pipefail

# Wait for the Docker daemon (this runs as a systemd unit After=docker).
for i in $(seq 1 30); do
  docker info >/dev/null 2>&1 && break || sleep 2
done

# Build both tags from the baked source if they don't already exist.
if ! docker image inspect vuln-app:latest >/dev/null 2>&1; then
  docker build -t vuln-app:latest /opt/vuln-app || echo "WARN: vuln-app build failed"
fi
if ! docker image inspect vuln-app:patched >/dev/null 2>&1; then
  # Same image; the patched behavior is selected at run time via APP_MODE.
  docker tag vuln-app:latest vuln-app:patched 2>/dev/null || true
fi

# Start the VULNERABLE app on :8080 (idempotent).
if ! docker ps --format '{{.Names}}' | grep -q '^demo-app$'; then
  docker rm -f demo-app >/dev/null 2>&1 || true
  docker run -d --restart=always --name demo-app \
    -e APP_MODE=vuln -p 8080:80 vuln-app:latest \
    || echo "WARN: could not start demo-app on :8080"
fi

echo "vuln-app boot helper done (vulnerable app on :8080)"
