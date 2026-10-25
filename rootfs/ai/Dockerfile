# syntax=docker/dockerfile:1
# -----------------------------------------------------------------------------
# DevSecOps course — AI / LLM-security playground rootfs (2 vCPU / 4 GiB)
# Ollama (CPU-only, with qwen2.5:0.5b baked in) + Garak. Python from vmbase.
#
# IMPORTANT: builds FROM the slim vmbase (~390 MB), NOT the full base image.
# The AI playground does not need Docker/Trivy/Semgrep/etc., so inheriting the
# 3.5 GB base was pure bloat. The install script also strips Ollama's bundled
# GPU libraries (we're CPU-only) and cleans caches — keeping the image small.
#
# Build (from repo root), after devsecops-vmbase:latest exists:
#   docker build --platform linux/amd64 \
#     -f rootfs/ai/Dockerfile \
#     --build-arg BASE=devsecops-vmbase:latest \
#     -t ghcr.io/mercadoalex/devsecops-ai:latest rootfs
#
# NOTE: baking the model needs network during build to pull qwen2.5:0.5b.
# -----------------------------------------------------------------------------
ARG BASE=devsecops-vmbase:latest
FROM ${BASE}

ARG LAB_USER=laborant
ENV LAB_USER=${LAB_USER}

COPY ai/install-ai-tools.sh /tmp/install-ai-tools.sh
RUN chmod +x /tmp/install-ai-tools.sh && /tmp/install-ai-tools.sh && rm -f /tmp/install-ai-tools.sh

# iximiuz examiner (task engine) — REQUIRED for playground task verification.
# Same as the base image: create + enable examiner.service (with a stub the
# platform overlays with the real binary at boot). Without it, no task turns green.
COPY common/set-up-systemd-examiner-service.sh /tmp/set-up-systemd-examiner-service.sh
RUN chmod +x /tmp/set-up-systemd-examiner-service.sh \
    && LAB_USER=${LAB_USER} sh /tmp/set-up-systemd-examiner-service.sh \
    && rm -f /tmp/set-up-systemd-examiner-service.sh

RUN printf 'DevSecOps — AI playground\nOllama (qwen2.5:0.5b baked, CPU-only) on :11434 + Garak.\n' \
      > /home/${LAB_USER}/.welcome \
    && chown ${LAB_USER}:${LAB_USER} /home/${LAB_USER}/.welcome

CMD ["/sbin/init"]
