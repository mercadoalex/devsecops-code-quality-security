# DevSecOps Course — Build & Provisioning Notes

Everything you need to provision the playgrounds, create the challenges, replace
the placeholder slugs, and push the course to iximiuz Labs.

> This course follows the same authoring rules as the reference course in
> `docs/` (module `0.index.md` with `name:`, lesson `index.md` = frontmatter +
> tasks only, `unit-1.md` = content + `::card`, standalone `challenges/`, bare
> dates, `tagz` not `tags`). See `docs/CHALLENGE_AUTHORING.md` and
> `docs/IXIMIUZ_TASKS_REFERENCE.md`.

---

## 1. Playgrounds — two kinds, three playgrounds

The course uses **three** playgrounds, selected per lesson via `playground.name`
in the lesson/challenge frontmatter. They come in **two kinds**:

- **Custom OCI-image playgrounds** (`devsecops-base`, `devsecops-ai`) — boot our
  own rootfs image built in `rootfs/`. Manifest drive `source:` is an `oci://`
  reference to a GHCR image we push.
- **Platform-base + init-task playground** (`devsecops-k8s`) — created on top of
  the platform's tested `k3s` base and layered with our tools via `initTasks`.
  **No custom K8s rootfs** — that approach was abandoned (k3s-in-a-custom-rootfs
  is fragile on first Firecracker boot; the platform `k3s` base already works).
  This mirrors the proven pattern from the Rancher course.

| Playground | Kind | Serves |
|---|---|---|
| `devsecops-base` | custom OCI (`rootfs/base`) | M1 (all except L5), M2, M3, M5 L1 (Gitleaks), M5 L3 (ZAP) |
| `devsecops-k8s`  | `--base k3s` + initTasks | M1 L5 (moto), M4 (all), M5 L2 (signing), M5 L4 (Falco), M7 (capstone) |
| `devsecops-ai`   | custom OCI (`rootfs/ai`) | M6 (LLM security) — **last lab** |

The custom-image playgrounds expose a machine named **`dev-machine`**; the k8s
playground is multi-node (`dev-machine` workstation + `cplane-01` + `node-01`),
with students always working from `dev-machine`. User is **`laborant`** on all.
Keep these names exact — they match every task's `machine:`/`user:` fields.

Manifests live in `playground/`:
- `playground/devsecops-base.playground.yaml`
- `playground/devsecops-ai.playground.yaml`
- `playground/devsecops-k8s/manifest.yaml`  (init-task style)

### 1a. `devsecops-base` rootfs — tool manifest

| Tool | License | Install source | Notes |
|---|---|---|---|
| Docker (+ dockerd) | Apache 2.0 | distro repo | daemon must be up on boot |
| Trivy | Apache 2.0 | aquasecurity apt repo / binary | pre-warm the vuln DB at build so first scan is fast |
| Semgrep | LGPL 2.1 | `pipx install semgrep` | pre-fetch `--config auto` rules offline if possible |
| Gitleaks | MIT | github release binary | — |
| cosign | Apache 2.0 | sigstore release binary | used lightly here; main use is k8s playground |
| Checkov | Apache 2.0 | `pipx install checkov` | IaC scanner |
| OpenTofu (`tofu`) | MPL 2.0 | github release binary | only for realistic HCL; **never applied** |
| OWASP ZAP (container) | Apache 2.0 | `docker pull ghcr.io/zaproxy/zaproxy:stable` | pre-pull image; only the headless `zap-baseline.py` is used |
| Syft, Grype *(optional)* | Apache 2.0 | anchore release | mentioned as alternatives; nice-to-have |
| jq, yq, git, curl | MIT/various | distro repo | — |
| Local registry | Apache 2.0 | `registry:2` on `localhost:5000` | optional on base; required on k8s |
| Demo app image | — | `ghcr.io/iximiuz/labs/owasp-demo:latest` (+ `:patched`) | **pre-pull**; used by OWASP + ZAP lessons |

> The `owasp-demo` image names (`:latest`, `:patched`) are placeholders used in
> tasks — point them at whatever deliberately-vulnerable demo you bake/host, and
> keep the same tags, or update the task scripts.

### 1b. `devsecops-k8s` rootfs — tool manifest

Everything in `devsecops-base` **plus**:

| Tool | License | Install source | Notes |
|---|---|---|---|
| k3s (single-node) | Apache 2.0 | `curl -sfL https://get.k3s.io \| sh -` | lightweight K8s; `kubectl` symlinked |
| Kyverno | Apache 2.0 | `kubectl apply` install manifest | pre-installed in `kyverno` ns; pods Ready on boot |
| Vault (dev mode) | MPL 2.0 (older) / OpenBao | binary; `vault server -dev` as a service | `VAULT_ADDR=http://127.0.0.1:8200`, root token `root` — **lab only** |
| Argo CD (core) *(optional)* | Apache 2.0 | install manifest | introduced conceptually in M5 L2; full install optional |
| Falco (modern-eBPF) | Apache 2.0 | falcosecurity apt repo | run as a service; use `modern_ebpf` driver (no kernel module build) |
| Local registry `localhost:5000` | Apache 2.0 | `registry:2` | **required** — signing + capstone push here. **Note the port clash below.** |
| moto | Apache 2.0 | `pipx install 'moto[server]'` | AWS emulator for the optional M1 L5 lesson; `moto_server -p 5001` |
| OpenTofu (`tofu`) | MPL 2.0 | github release binary | also used by M1 L5 to `apply` against moto |
| Prowler | Apache 2.0 | `pipx install prowler` | cloud posture (CSPM) scanner for M1 L5 |

> **Port convention (already set in the lesson files):** the OCI **registry uses
> `localhost:5000`** (signing + capstone); **`moto_server` uses `localhost:5001`**
> (M1 L5). They never collide. Keep both ports free on `devsecops-k8s`.

> **Why not LocalStack (for M1 L5):** as of March 2026 LocalStack archived its
> open-source Community repo (no updates/patches) and gated the free "Hobby" tier
> behind an account with a **non-commercial-use restriction** — unsuitable for a
> paid course and against this course's all-open-source rule. **moto** is the
> Apache-2.0, account-free, lighter replacement.

> **Falco driver note:** in Firecracker use the `modern_ebpf` driver. If the
> probe can't load in your VM kernel, fall back to Falco's userspace path or run
> the demo with simulated events (`falco -M`). Validate on a real VM before
> publishing — this is the one tool most sensitive to the microVM kernel.
>
> **Vault license note:** recent Vault is BUSL. For a strictly-open-source
> course, install **OpenBao** (MPL 2.0, drop-in) — the `vault kv put/get`
> commands in the lessons are identical (`bao` ≈ `vault`).

### 1c. `devsecops-ai` rootfs — tool manifest

| Tool | License | Install source | Notes |
|---|---|---|---|
| Ollama | MIT | `curl -fsSL https://ollama.com/install.sh \| sh` | serves on `localhost:11434`; run as a service |
| Model: `qwen2.5:0.5b` | Apache 2.0 | `ollama pull qwen2.5:0.5b` | **bake into the image** (~400 MB) so there's no slow first-run pull; CPU-only |
| Garak | Apache 2.0 | `pipx install garak` | LLM scanner; one scoped probe only, run in background |
| Python 3 + pipx | PSF | distro repo | — |

> **CPU-only, no GPU** (Firecracker has no GPU passthrough — see
> `docs/IXIMIUZ_INTEGRATION`). Qwen2.5:0.5b is chosen to fit. A full Garak scan
> is hours on CPU, so lessons run **one probe** and defer it to the background;
> this is the **last** lab on purpose.

---

## 2. Playground access control (set in the UI, not labctl)

Per `docs/IXIMIUZ_ACCESS_CONTROL.md`, playground access is separate from content
access and must be **at least as permissive** as the content. For a paid cohort:

```
canList:  [owner]
canRead:  [anyone]            # teaser lessons readable
canStart: [student:<training-name>]   # only enrolled students can launch
```

Set this for all three playgrounds. For free/public listing, use `anyone` on all
three dimensions.

---

## 3. Lesson → playground → challenge map

| Module / lesson | Playground | Challenge dir (slug placeholder) |
|---|---|---|
| M1 1.shift-left | base | *(no challenge)* |
| M1 2.owasp-top10 | base | `owasp-top10` → `owasp-top10-1a595ab3` |
| M1 3.trivy-first-scan | base | `trivy-first-scan` → `trivy-first-scan-26cd5ac1` |
| M1 4.iac-security | base | `iac-security` → `iac-security-a78880fb` |
| M1 5.iac-runtime-moto *(optional)* | **k8s** | `iac-runtime` → `iac-runtime-b4d0f1f7` |
| M2 1.sast-semgrep | base | `semgrep-gate` → `semgrep-gate-04bd1d49` |
| M2 2.tech-debt | base | `tech-debt` → `tech-debt-562e044d` |
| M3 1.docker-hardening | base | `docker-hardening` → `docker-hardening-5361d5e5` |
| M3 2.sbom | base | `sbom-generate` → `sbom-generate-63de728a` |
| M4 1.kyverno | k8s | `kyverno-policy` → `kyverno-policy-a193dfe4` |
| M4 2.rbac-vault | k8s | `k8s-rbac` → `k8s-rbac-a7d48c0f` |
| M5 1.gitleaks | base | `gitleaks-scan` → `gitleaks-scan-6d67fce8` |
| M5 2.image-signing | k8s | `image-signing` → `image-signing-93f4df06` |
| M5 3.zap-dast | base | `zap-dast` → `zap-dast-1ea402e5` |
| M5 4.falco | k8s | `falco-runtime` → `falco-runtime-d71c2b5f` |
| M6 1.llm-security | ai | `garak-llm-scan` → `garak-llm-scan-006d06fe` |
| M7 1.capstone | k8s | `devsecops-capstone` → `devsecops-capstone-56f65b95` |

**16 challenges** across 17 lessons (the intro lesson has none; M1 L5 is optional/advanced).

---

## 4. Create challenges & replace placeholder slugs

Every challenge slug is currently the placeholder `<name>-XXXXXXXX`. The platform
assigns the real hash at `create` time. For each challenge directory:

```bash
export PATH=$PATH:/Users/alexmarket/.iximiuz/labctl/bin
cd /Users/alexmarket/Desktop/devsecops_lab/course-devsecops

# 1. Create the challenge on the platform — prints the real slug, e.g. owasp-top10-a1b2c3d4
labctl content create challenge owasp-top10 -d challenges/owasp-top10 --no-open -q
```

Then replace the placeholder in **three** places for that challenge:

1. the lesson `index.md` `challenges:` block,
2. the lesson `unit-1.md` `::card` → `:challenge:` line,
3. (the challenge `index.md` itself has **no** slug field — leave it; platform owns the slug).

A convenience loop once you've collected the real slugs into a map:

```bash
# Example: after creating, you learn owasp-top10 → owasp-top10-a1b2c3d4
OLD=owasp-top10-1a595ab3 ; NEW=owasp-top10-a1b2c3d4
grep -rl "$OLD" . | xargs sed -i '' "s/${OLD}/${NEW}/g"   # macOS sed
```

Repeat `create` + replace for all 15 challenge dirs:

```
owasp-top10  trivy-first-scan  iac-security  iac-runtime  semgrep-gate
tech-debt  docker-hardening  sbom-generate  kyverno-policy  k8s-rbac
gitleaks-scan  image-signing  zap-dast  falco-runtime  garak-llm-scan
devsecops-capstone
```

Sanity check that none are left:

```bash
grep -rn "XXXXXXXX" . && echo "STILL PLACEHOLDERS ABOVE" || echo "all slugs replaced"
```

---

## 5. Create the course & push

```bash
# Create the course shell (first time only) — prints the course slug
labctl content create course devsecops-code-quality-security -d . --no-open -q

# Push each challenge (force overwrite; -f avoids the TTY skip bug)
for c in owasp-top10 trivy-first-scan iac-security iac-runtime semgrep-gate \
         tech-debt docker-hardening sbom-generate kyverno-policy k8s-rbac \
         gitleaks-scan image-signing zap-dast falco-runtime garak-llm-scan \
         devsecops-capstone; do
  labctl content push -f challenge <real-slug-for-$c> -d challenges/$c
done

# Push the whole course
labctl content push -f course <course-slug> -d .
```

> Both the challenges **and** the course must be pushed. If a challenge card
> shows "Couldn't load the challenge", the usual causes are: wrong slug in the
> `::card`, the course wasn't re-pushed after editing the lesson `index.md`, or a
> task has no matching `::simple-task` (this course is validated clean on that
> last point).

---

## 6. Images (`__static__/*.png.todo`)

Every diagram is a `.todo` placeholder describing exactly what to draw. Replace
each with a real PNG at the same path (drop the `.todo`), and set the course
`cover.png` in `course-devsecops/__static__/`. The `.todo` text is written as an
image-gen prompt / designer brief and doubles as the alt-text source.

Placeholders to fulfil:

```
__static__/cover.png
module-1/1.lesson-shift-left/__static__/{shift-left-sdlc,devsecops-toolchain}-v1.png
module-1/2.lesson-owasp-top10/__static__/owasp-top10-overview-v1.png
module-1/3.lesson-trivy-first-scan/__static__/trivy-scan-flow-v1.png
module-1/4.lesson-iac-security/__static__/iac-scan-flow-v1.png
module-1/5.lesson-iac-runtime-moto/__static__/iac-static-vs-posture-v1.png
module-2/1.lesson-sast-semgrep/__static__/sast-flow-v1.png
module-2/2.lesson-tech-debt/__static__/tech-debt-clean-as-you-code-v1.png
module-3/1.lesson-docker-hardening/__static__/docker-hardening-checklist-v1.png
module-3/2.lesson-sbom/__static__/sbom-concept-v1.png
module-4/1.lesson-kyverno/__static__/kyverno-admission-v1.png
module-4/2.lesson-rbac-vault/__static__/rbac-vault-v1.png
module-5/1.lesson-gitleaks/__static__/gitleaks-history-v1.png
module-5/2.lesson-image-signing/__static__/cosign-signing-v1.png
module-5/3.lesson-zap-dast/__static__/dast-vs-sast-v1.png
module-5/4.lesson-falco/__static__/falco-runtime-v1.png
module-6/1.lesson-llm-security/__static__/prompt-injection-v1.png
module-7/1.lesson-capstone/__static__/pipeline-end-to-end-v1.png
```

> `__static__` is CDN-served with **no auth** — never put student-only or
> sensitive files there.

---

## 7. Pre-publish validation checklist

- [ ] All three playgrounds boot; `dev-machine`/`laborant` present; services up
- [ ] `devsecops-base`: `docker info`, `trivy --version`, `semgrep --version`, `gitleaks version`, `cosign version`, `checkov --version` all succeed
- [ ] `devsecops-k8s`: `kubectl get nodes` Ready, `kubectl -n kyverno get pods` Ready, `vault status` (dev), `localhost:5000` registry reachable, Falco service active
- [ ] `devsecops-k8s` (for optional M1 L5): `moto_server --help`, `tofu version`, `prowler --version` all succeed; port **5001** free for moto (registry keeps 5000)
- [ ] `iac-runtime` challenge created and its slug replaced (it's the 16th challenge)
- [ ] `devsecops-ai`: `curl localhost:11434/api/tags` lists `qwen2.5:0.5b`, `garak --list_probes` works
- [ ] Demo app image(s) pre-pulled on base/k8s
- [ ] All 15 challenges created; **no `XXXXXXXX` left** (section 4 check)
- [ ] Course pushed; every lesson renders body + tasks; every challenge card loads
- [ ] Each lesson's tasks turn green by following its own activities
- [ ] Images replaced (or accept `.todo` placeholders render without thumbnails)
- [ ] Access control set on content **and** all three playgrounds
