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

# A friendly welcome shown in the terminal.
RUN printf 'DevSecOps — Base playground\nTools: docker, trivy, semgrep, gitleaks, cosign, checkov, tofu\n' \
      > /home/${LAB_USER}/.welcome \
    && chown ${LAB_USER}:${LAB_USER} /home/${LAB_USER}/.welcome

CMD ["/sbin/init"]
