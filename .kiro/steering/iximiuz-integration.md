---
inclusion: auto
name: iximiuz-integration
description: How the iximiuz Labs platform connects to GCP, auto-grading, monetization model
---

# iximiuz Labs Integration

## What iximiuz Provides

| Feature | Details |
|---------|---------|
| Playground | Custom `flexbox` or `k8s-omni`-based multi-VM environment |
| Tutorial | Markdown + embedded shell steps + auto-graded `<task>` blocks |
| ILT (instructor-led) | Enrollment, premium seats, progress tracking for paid cohorts |
| Self-paced | Published tutorial with access control (`canStart` role) |
| Delivery VM | Firecracker microVM — browser terminal, no student setup required |

## What iximiuz Cannot Do

- **No GPU passthrough** — Firecracker microVMs have no hardware GPU access.
- **Not self-serve for monetization** — Independent Authors program is pilot-only
  (4 hand-picked authors). Do not wait for it; use Gumroad/Stripe for billing.

## How the iximiuz VM Connects to GCP

```
Student browser
    │
    ▼
iximiuz Playground (Firecracker microVM)
    │
    │  GCP SA key → baked into VM as Application Default Credentials (ADC)
    │  gke-gcloud-auth-plugin → short-lived OAuth2 token (auto-refreshed)
    │  kubectl → GKE API server over public HTTPS (port 443)
    │
    ▼
GKE cluster (us-west1) — GPU node pool
    ├── NVIDIA GPU Operator
    ├── vLLM pod (on L4 or A100 MIG partition)
    └── Prometheus + Grafana
```

- **No VPC peering, no tunnel** — plain HTTPS to the GKE API server is sufficient.
- **Auth method:** GCP Service Account key injected as ADC into the iximiuz VM image.
  The SA has minimal permissions (GKE developer role on the lab cluster only).
- **Token refresh:** `gke-gcloud-auth-plugin` handles token refresh automatically;
  students never see credentials.

## Auto-Graded Task Structure

Each module ships 2–4 auto-graded tasks following this pattern:

```markdown
<task title="Install Kueue ClusterQueue" id="task-03-1-install-kueue">
  <hint>Apply the manifest in course-1/manifests/clusterqueue-default.yaml</hint>
  <validate>validate-kueue-clusterqueue.sh</validate>
</task>
```

Validation scripts (`validate-<slug>.sh`) are idempotent shell scripts that:
1. Run `kubectl get` / `kubectl describe` checks.
2. Exit 0 on pass, non-zero on fail with a human-readable error message.
3. Are kept < 50 lines — complexity belongs in the K8s object, not the validator.

## Assessment Weights

| Type | C1 Weight | C2 Weight | C3 Weight |
|------|-----------|-----------|-----------|
| Auto-graded tasks (iximiuz) | 60% | 50% | 40% |
| Capstone / benchmark report | 30% | 25% + 25% | 20% × 2 + 20% |
| Validation report | 10% | — | — |

## Monetization Flow

```
Student pays → Gumroad / Stripe
                    │
                    ▼
            Webhook → grant iximiuz access
            (canStart role on the tutorial)
                    │
                    ▼
            Student launches playground
            (iximiuz spins up Firecracker VM)
                    │
                    ▼
            VM connects to GCP cluster
            (SA key pre-baked in VM image)
```

iximiuz is the **delivery layer** only. All billing, access control, and student
management runs through your own Gumroad/Stripe integration.

## Lab Phases (Student Journey — Course 1)

1. Verify cluster (3 nodes Ready, GPU capacity visible via ghostgpu)
2. Install ghostgpu → nodes report `nvidia.com/gpu`
3. Configure Kueue → ClusterQueue, LocalQueue, cohort, borrowing
4. Gang scheduling with Volcano → `minAvailable`, DRF fair-share
5. Karpenter NodePool → author YAML, validate with `--dry-run=server`
6. Observability → wire Prometheus + Grafana, DCGM panels
7. Capstone → 3 teams, 3 workloads, observe scheduling decisions
8. GPU Validation (GCP Tier 2) → deploy vLLM, benchmark tokens/s, compare SGLang
