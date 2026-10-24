# DevSecOps course — playground rootfs images

Three Firecracker-bootable Ubuntu 24.04 rootfs images for the course playgrounds.
They layer on a shared VM base.

```
rootfs/
  common/
    Dockerfile.vmbase        # systemd + VM boot reqs + laborant user + common CLIs
    install-base-tools.sh    # Docker, Trivy, Semgrep, Gitleaks, cosign, Checkov, OpenTofu
  base/Dockerfile            # -> ghcr.io/<ns>/devsecops-base   (2 GiB)
  k8s/
    Dockerfile               # -> ghcr.io/<ns>/devsecops-k8s    (4 GiB)
    install-k8s-tools.sh     # k3s, Kyverno, OpenBao/Vault(dev), Falco, registry, moto, Prowler
  ai/
    Dockerfile               # -> ghcr.io/<ns>/devsecops-ai     (4 GiB)
    install-ai-tools.sh      # Ollama (+ qwen2.5:0.5b baked), Garak
  Makefile
```

## Build & push

```bash
cd rootfs
# First build ~20-40 min on Apple Silicon (QEMU amd64 emulation); cached rebuilds fast.
make all  REGISTRY=ghcr.io/<your-namespace>

echo "<ghcr-PAT>" | docker login ghcr.io -u <your-user> --password-stdin
make push REGISTRY=ghcr.io/<your-namespace>
# Then make each GHCR package PUBLIC (github.com -> Packages -> settings) so iximiuz can pull.
```

Build order is handled by the Makefile: `vmbase -> base -> {k8s, ai}`.

## Design notes / constraints applied (from docs/BUILD_JOURNAL.md)

- `--platform linux/amd64` — iximiuz Firecracker VMs are x86_64; required on Apple Silicon.
- systemd is PID 1; serial console on `ttyS0`; `machine-id` reset for fresh VM identity.
- `noble-backports` pinned off to avoid the QEMU GPG failure.
- `laborant` (uid 1001) with passwordless sudo; all root file ops happen before any USER switch.
- Services that need a running cluster/model are **enabled, not started, at build** — they
  come up on first VM boot (k3s with `INSTALL_K3S_SKIP_START=true`; Kyverno applied by a
  `devsecops-first-boot` oneshot unit once the API server is healthy).

## Things to verify on a REAL VM before publishing

These depend on the microVM kernel and can't be fully validated in `docker build`:

1. **Falco driver** — the scripts prefer `modern_ebpf`. If the probe can't load in the
   iximiuz kernel, switch to Falco's userspace path or run the demo with `falco -M`.
   This is the single most environment-sensitive tool in the course.
2. **k3s first boot** — confirm `kubectl get nodes` is Ready and the `devsecops-first-boot`
   unit applied Kyverno (`kubectl -n kyverno get pods`).
3. **OpenBao/Vault dev unit** — confirm `vault status` works and the `vault` symlink resolves.
4. **Ollama model** — confirm `qwen2.5:0.5b` is present without a network pull
   (`curl localhost:11434/api/tags`). If the service user can't see the baked blobs,
   adjust the model-store copy in `install-ai-tools.sh`.
5. **Local registry** — `curl localhost:5000/v2/` returns 200; moto uses 5001 (no clash).

## Pins (bump as needed)

| Tool | Pinned version | Where |
|---|---|---|
| Gitleaks | 8.21.2 | install-base-tools.sh |
| OpenTofu | 1.8.5 | install-base-tools.sh |
| OpenBao | 2.1.0 | install-k8s-tools.sh |
| Kyverno | v1.13.2 | install-k8s-tools.sh |
| Model | qwen2.5:0.5b | install-ai-tools.sh |
| Trivy / Semgrep / Checkov / cosign / Falco / Ollama / Garak / Prowler | latest | respective scripts |

> `kubectl` and k3s use the current stable channel. Pin them too if you need
> fully reproducible builds.
