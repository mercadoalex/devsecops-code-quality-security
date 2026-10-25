# syntax=docker/dockerfile:1
# -----------------------------------------------------------------------------
# DevSecOps course — BASE playground rootfs (2 vCPU / 2 GiB)
# Tools: Docker, Trivy, Semgrep, Gitleaks, cosign, Checkov, OpenTofu.
#
# Build (from repo root), after building devsecops-vmbase:latest first:
#   docker build --platform linux/amd64 \
#     -f rootfs/base/Dockerfile \
#     -t ghcr.io/mercadoalex/devsecops-base:latest rootfs
# -----------------------------------------------------------------------------
FROM devsecops-vmbase:latest

ARG LAB_USER=laborant
ENV LAB_USER=${LAB_USER}

# All root-owned work happens here, before we drop to the lab user.
COPY common/install-base-tools.sh /tmp/install-base-tools.sh
RUN chmod +x /tmp/install-base-tools.sh && /tmp/install-base-tools.sh && rm -f /tmp/install-base-tools.sh

# iximiuz examiner (task engine) — REQUIRED for playground task verification.
# Creates /etc/systemd/system/examiner.service (+ a stub binary) and enables it,
# mirroring the working ColdFusion rootfs. The iximiuz platform injects the real
# examiner binary over the stub at playground boot; without this service unit the
# task checks never run (nothing turns green). If real examiner/examinerctl
# used and the platform overlays it at boot.
COPY common/set-up-systemd-examiner-service.sh /tmp/set-up-systemd-examiner-service.sh
RUN chmod +x /tmp/set-up-systemd-examiner-service.sh \
    && LAB_USER=${LAB_USER} sh /tmp/set-up-systemd-examiner-service.sh \
    && rm -f /tmp/set-up-systemd-examiner-service.sh

# Bake the deliberately-vulnerable demo app source (OWASP + ZAP lessons).
# The source lives at /opt/vuln-app; a boot helper builds + runs it so the
# vulnerable app is already serving on :8080 when students reach those lessons.
COPY vuln-app/ /opt/vuln-app/
COPY common/vuln-app-boot.sh /usr/local/bin/vuln-app-boot.sh
RUN chmod +x /usr/local/bin/vuln-app-boot.sh \
    && chown -R ${LAB_USER}:${LAB_USER} /opt/vuln-app
COPY common/vuln-app.service /etc/systemd/system/vuln-app.service
RUN ln -sf /etc/systemd/system/vuln-app.service \
      /etc/systemd/system/multi-user.target.wants/vuln-app.service

# A friendly welcome shown in the terminal.
RUN printf 'DevSecOps — Base playground\nTools: docker, trivy, semgrep, gitleaks, cosign, checkov, tofu\n' \
      > /home/${LAB_USER}/.welcome \
    && chown ${LAB_USER}:${LAB_USER} /home/${LAB_USER}/.welcome

CMD ["/sbin/init"]
