---
inclusion: manual
---

# iximiuz Init Tasks — Troubleshooting Playbook

> If the playground is stuck at "Warming up playground… Init tasks completed: 0/N",
> an init task script has either timed out or is polling something that boots too slowly.

## ⚠️ THE #1 RULE — WHERE INIT TASKS LIVE (read this first)

**Init tasks go in the PLAYGROUND manifest under a top-level `initTasks:` key —
NOT in a lesson's `index.md` `tasks:` block.** This is the single most important
fact about init tasks, and getting it wrong cost this project ~2 days on the GPU
course (Oct 2026): an `init: true` task placed in a lesson's `tasks:` block makes
the "Warming up playground… Init tasks completed: 0/N" spinner hang **forever**.

**Two different task locations, two different purposes:**

| Location | Key | Purpose | `init: true`? | `timeout_seconds`? |
|----------|-----|---------|---------------|--------------------|
| **Playground manifest** (`playground.yaml` / `manifest.yaml`) | `initTasks:` | Provision the environment before the student arrives (kubeconfig, install prereqs, wait for services). Blocks the "Warming up" screen until all exit 0. | **Yes** | **Yes — valid and honored here** (e.g. 180/300/600) |
| **Lesson** (`index.md`) | `tasks:` | Grade the student's work. The green/red boxes. Run AFTER the playground is up. | **Never** | **No** |

So `timeout_seconds` IS a real, supported field — but ONLY inside the playground's
`initTasks:`. It is NOT valid on lesson grading tasks. Putting `init: true` or
`timeout_seconds` on a lesson task is the classic hang.

**Lessons reference the playground by name** (`playground.name: <suffixed-slug>`);
they do not define init tasks. The playground is built/updated ONCE with
`labctl playground update <slug> -f manifest.yaml`; lessons are pushed separately
with `labctl content push`. Init-task changes require re-running the playground
update and restarting the playground, NOT a content push.

Canonical working shape (from a validated Rancher/K3s course —
see `rancher_ex/playgrounds/*/manifest.yaml`):
```yaml
# In the PLAYGROUND manifest, as a sibling of machines: and tabs:
playground:
  machines: [ ... ]
  tabs: [ ... ]
  initTasks:
    init_setup:
      init: true
      machine: dev-machine
      user: laborant
      timeout_seconds: 180         # valid HERE (playground initTasks only)
      needs: [ other_init_task ]   # init tasks can chain with needs:
      run: |
        # wait for a dependency, set up ~/.kube/config, export KUBECONFIG so
        # every later shell (and the examiner) finds the cluster
        export KUBECONFIG="$HOME/.kube/config"
        grep -q 'KUBECONFIG=' "$HOME/.bashrc" || \
          echo 'export KUBECONFIG=$HOME/.kube/config' >> "$HOME/.bashrc"
        kubectl get nodes
```

**Debugging checklist when the spinner hangs at 0/N:**
1. Is there an `init: true` task in a lesson `index.md`? → That's the bug. Move it to the playground manifest `initTasks:`.
2. Did you re-run `labctl playground update` after changing `initTasks:`? A content push does NOT update init tasks.
3. Did you restart the playground (fresh instance)? A running VM keeps the old init tasks.
4. `labctl playground tasks <play-id> --kind init -o json` — if the task is stuck at
   `status: 10` (created) and shows **`controlPlaneOnly: true`**, see the warning below.

## ⚠️ `controlPlaneOnly: true` on single-machine custom playgrounds (unresolved)

On a **single-machine** playground built from a custom OCI image (one machine, e.g.
`dev-machine`, no separate `cplane-01`), the platform INJECTS `controlPlaneOnly: true`
onto init tasks — a field you did NOT write and that does NOT appear in working
multi-machine playgrounds (verified: `labctl playground manifest k8s-omni` shows zero
`controlPlaneOnly`). The task then never dispatches (stuck at `status: 10` / "created")
and the "Warming up" spinner hangs forever. `labctl playground start -f <manifest>`
does NOT clear it — a fresh run re-injects the flag. Confirmed Oct 2026 on the GPU course.

**Working playgrounds that use init tasks (k8s-omni, rancher-k3s) all have a real
multi-node topology with a `cplane-01` control-plane machine.** A single custom-image
machine does not satisfy whatever role classification the platform expects.

**Pragmatic workaround (what the GPU course does):** do NOT use an iximiuz init task
on a single-machine custom-image playground. Instead:
- Bake a **systemd service** into the image that provisions the environment on boot
  (e.g. `kwok-cluster.service` creating the KWOK cluster). systemd owns it, it persists.
- Omit `initTasks:` entirely → no "Warming up" gate → the student lands straight in the
  terminal while the service finishes in the background.
- Make the lesson's FIRST grading task poll-and-wait for readiness (it runs in a loop,
  so it goes green on its own once the service is up).

Revisit init tasks only if iximiuz support clarifies the `controlPlaneOnly` behavior, or
if you move to a multi-machine base with a real control-plane node.

---

## How the platform boots a playground

```
VM starts (microVM cold boot)
  └── systemd starts services

Platform task runner fires ALL init tasks in parallel immediately on SSH-reachability

Playground UI shows "Warming up playground..."
  └── spinner stays until EVERY init task exits 0
  └── Once all exit 0 → regular tasks start → UI unlocks
```

**Key insight:** init tasks fire the moment the VM is reachable via SSH — the services
have NOT started yet. If an init task times out it exits non-zero and the spinner
**never clears** (no platform-side timeout on the warming-up phase visible to students).

---

## Canonical init task patterns

### Wait for a port (preferred — use `nc -z`)

```yaml
init_wait_for_service:
  init: true
  machine: <machine-name>
  user: laborant
  timeout_seconds: 300
  run: |
    until nc -z 127.0.0.1 <PORT> 2>/dev/null; do
      echo "Waiting for service on port <PORT>..."
      sleep 5
    done
    sleep 10
    echo "Service is up ✓"
```

**Rules:**
- Use `nc -z` (TCP port open check) **not** an HTTP URL poll — HTTP endpoints are
  one of the last things a service exposes; the port opens 30–40 s earlier.
- `sleep 10` after the port opens gives the process time to finish internal init
  before regular tasks start firing requests.
- `timeout_seconds: 300` — always. 120 s was too tight and caused timeouts.

### Wait for an HTTP endpoint (only when port check isn't reliable)

```yaml
init_wait_for_http:
  init: true
  machine: <machine-name>
  user: laborant
  timeout_seconds: 300
  run: |
    until curl -s -o /dev/null -w "%{http_code}" http://localhost:<PORT>/ \
        | grep -q "200\|302"; do
      echo "Waiting for HTTP on port <PORT>..."
      sleep 5
    done
    echo "Service is up ✓"
```

Use this when a service's HTTP layer initialises slightly after the port opens
(e.g. CommandBox/Lucee). For most services `nc -z` is faster and more reliable.

### Wait for a child process (add a leading sleep)

When service B is spawned by service A (e.g. Solr spawned by ColdFusion), add
`sleep 30` before the poll loop so you don't waste the entire timeout polling a
port that won't open for 60+ seconds:

```yaml
init_wait_for_child_service:
  init: true
  machine: <machine-name>
  user: laborant
  timeout_seconds: 300
  run: |
    sleep 30
    until nc -z 127.0.0.1 <PORT> 2>/dev/null; do
      echo "Waiting..."
      sleep 5
    done
    echo "Service is up ✓"
```

---

## What "Warming up playground" actually means

| Platform state | UI |
|---|---|
| VMs booting | "Warming up playground… Init tasks completed: 0/N" |
| Init tasks running (poll loop) | Same — still 0/N |
| Any init task exits non-zero (timeout) | **Stuck forever at 0/N** |
| All init tasks exit 0 | Spinner clears, regular tasks start, UI unlocks |

---

## Common failure modes

| Symptom | Cause | Fix |
|---|---|---|
| "0/N" forever after 3+ min | `timeout_seconds` too low (e.g. 120) | Use 300 |
| Init task hangs near timeout | Polling a slow HTTP admin URL instead of port | Use `nc -z` |
| Child service init times out at 300 s | Task starts polling before parent service is up | Add `sleep 30` |
| Two init tasks both time out simultaneously | Parallel fire burning the same timeout window | Tasks are independent by design — use `sleep` stagger |

## KWOK binary runtime: warm the cache at build time, not boot

The kwokctl **binary runtime** (`kwokctl create cluster --runtime=binary`) runs
etcd + kube-apiserver + kube-controller-manager + kube-scheduler + kwok as plain
Linux binaries. On the FIRST `create cluster`, kwokctl downloads those binaries
(kube from dl.k8s.io, etcd image tag matching the K8s minor) and caches them.

- **Warm the cache during the image BUILD, never at boot.** A microVM boots with
  no network guarantees and the init-task timeout is short — downloading kube+etcd
  at boot is exactly what hangs the "Warming up playground" spinner. Run a throwaway
  `create cluster` + `delete cluster` in the Dockerfile so the cache is already
  populated; the delete frees the ephemeral cluster but the cached binaries persist.
- **The cache is home-dir relative** (`~/.kwok/cache/kubernetes/<KUBE_VERSION>/...`),
  so the warm-up MUST run as the SAME user the playground runs as (`laborant`), not
  root. Caching to `/root/.kwok` is invisible to `laborant` at runtime.
- **Bake the repo in; don't clone at boot.** Copy the course repo into the image
  (`/opt/gpu-k8s-lab`, with `/workdir` symlinked to it) so init tasks never `git clone`.
- **Init tasks only WAIT — they never build.** The setup script creates the cluster
  synchronously (offline, <30s); the init task just runs it then `kubectl wait`s for
  nodes Ready. No downloads, no `curl .../releases/latest`.

## Long-lived processes MUST be systemd services, not init tasks

The iximiuz examiner **reaps the init task's entire process tree** when the task
completes. Any long-lived process started by an init task is therefore KILLED the
moment the "Warming up playground" spinner clears. This bit the KWOK cluster: an
init task that ran `setup-kwok-cluster.sh` started etcd + kube-apiserver +
kwok-controller as detached children, and all three were reaped on task
completion — the student terminal then showed no cluster (`kwokctl get clusters`
empty, `kubectl` connection refused), even though running the same script by hand
in the login shell worked (those children belong to the login shell, not the
reaped init task).

**Rule:** a long-lived process (notably a `kwokctl` binary-runtime cluster) MUST
be owned by a **systemd service baked into the image** — systemd is PID 1 and
persists for the VM lifetime, so a service it owns survives. Enable the unit in
the Dockerfile (`COPY` the `.service` file + `systemctl enable`). The init task's
ONLY job is to **WAIT** for the systemd-managed service to be ready: poll the
apiserver port (`nc -z`), then loop until `kubectl get nodes` shows the expected
Ready nodes. The init task must never create the cluster.

**`KillMode=process` is required** on the service. For a `Type=oneshot` +
`RemainAfterExit=yes` unit whose `ExecStart` creates the cluster then returns,
systemd's default `KillMode=control-group` would kill the whole cgroup — including
the detached cluster children — when the ExecStart process exits, reproducing the
examiner-reap bug at the systemd layer. `KillMode=process` makes systemd signal
only the main process on stop, leaving the cluster children alive. Run the service
as the lab user (`laborant`) with `HOME=/home/laborant` so it reuses the
build-time-warmed cache and writes the kubeconfig to the default
`~/.kube/config` the login shell reads.

---

## Critical: `init: true` must ONLY appear on real init tasks

Adding `init: true` to regular (student-facing) tasks causes the "Warming up
playground" screen to hang forever. The foundations course has **zero** init tasks
and works correctly — regular tasks run after the playground is up with no `init:` key.

---

## Pre-push checklist

- [ ] Every `init` task uses `timeout_seconds: 300`
- [ ] Port checks use `nc -z`, not an HTTP URL
- [ ] `nc -z` is followed by `sleep 10`
- [ ] Child-process services start with `sleep 30` before their poll loop
- [ ] Regular tasks do NOT have `init: true`
- [ ] Regular tasks do NOT use `timeout_seconds` (not a documented field on regular tasks)
- [ ] Regular tasks do NOT use `needs: [init_wait_*]` — platform guarantees regular
      tasks only start after all init tasks pass; explicit `needs` to init tasks is
      not required and is not supported

---

## kwokctl binary-runtime gotchas (learned the hard way)

- **Warm the cache at BUILD time, never at boot.** `kwokctl create cluster --runtime=binary`
  downloads kube + etcd + kwok binaries from `dl.k8s.io`. Run a throwaway
  `create`+`delete` in the Dockerfile so the binaries land in `~/.kwok/cache/`.
  At playground boot the create is then fully offline.
- **kwokctl v0.6.0 has NO `--kube-version` flag.** Select the version with the
  `KWOK_KUBE_VERSION` env var: `KWOK_KUBE_VERSION=v1.31.3 kwokctl create cluster --runtime=binary`.
- **Cache path is URL-mirrored**, not `cache/kubernetes/<ver>`. The real path is
  `~/.kwok/cache/https/dl.k8s.io/release/<ver>/bin/linux/amd64/kube-apiserver`.
  Assert that exact path in the Dockerfile to confirm the warm-up worked.
- **Run the warm-up AS the lab user** (`laborant`), not root — the cache is HOME-relative
  and the playground runs as the lab user.
- **"Cluster is started" is optimistic.** kwokctl prints it even if the apiserver
  isn't serving yet. ALWAYS poll `kubectl get --raw /healthz` until it returns `ok`
  before applying any objects, or node applies hit "connection refused".
- **Apply fake nodes with `kubectl apply --validate=false`** — avoids a dependency on
  the apiserver's openapi endpoint being fully warmed in the first seconds.
- **Never hardcode `lastHeartbeatTime` on KWOK fake nodes.** With the
  `kwok.x-k8s.io/node: fake` annotation, the kwok controller owns the Ready condition
  and heartbeat. A pinned timestamp goes stale and fails the Ready freshness check.
- **QEMU emulation is NOT representative of boot time.** Building/running the amd64
  image on an Apple Silicon host under QEMU makes the apiserver take minutes to serve.
  On native amd64 (the real Firecracker runtime) it's ~10s. Do not quote emulated
  timings to students, and give the health-check loop generous headroom.

## GPU simulation on KWOK: patch node status, do NOT use a device-plugin operator

The run.ai fake-gpu-operator (and any real device plugin) runs as a **pod on the
node** that registers GPUs with the kubelet. KWOK has **no kubelet** and only
*simulates* pods — they show `Running` but their containers never execute (hence
"no logs found" for a Running pod). So the operator's pods are a façade: their
GPU-injection code never runs, and `nvidia.com/gpu` never appears.

**The reliable KWOK-native way to advertise a GPU is a direct node-status patch:**

```bash
kubectl patch node <node> --subresource=status --type=merge -p '{
  "status": {"capacity": {"nvidia.com/gpu": "4"}, "allocatable": {"nvidia.com/gpu": "4"}}
}'
```

`--subresource=status` is required (the field lives under `.status`, not `.spec`).
This is exactly what a real device plugin makes the kubelet write — so it's also a
good teaching device. Save the device-plugin/GPU-Operator machinery for the Tier 2
(real GPU) modules.

## Service startup times (reference)

| Service | Port | Time to ready (cold boot, 2 GiB microVM) |
|---|---|---|
| Kubernetes API server (kwokctl binary runtime) | dynamic | <10 s (binaries pre-cached) |
| KWOK nodes reporting Ready | — | 5–10 s after API server |
| Kueue controller | — | 10–20 s after API server |
| Prometheus | 9090 | 15–30 s |
| Grafana | 3000 | 20–40 s |
| vLLM (CPU stub / smoke test) | 8000 | 30–60 s |
