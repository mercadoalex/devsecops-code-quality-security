# DevSecOps Course — Session Handoff

_Last updated: 2026-10-24 (end of day). Resume point for tomorrow._

Course: **DevSecOps: Code Quality & Security** on iximiuz Labs.
Repo: `/Users/alexmarket/Desktop/devsecops_lab` → GitHub `github.com/mercadoalex/devsecops-code-quality-security` (public, branch `main`).

---

## TL;DR — where we are

The course is written (7 modules, 16 challenges), published, and version-controlled.
The big blocker — **custom OCI images lacked the iximiuz examiner, so no task ever graded green** — is **FIXED**. Playgrounds were migrated to official bases + init tasks, and the green-check milestone is confirmed working end-to-end.

Today we also fixed a UX problem: **13 lessons' first "readiness" task graded ambient boot state** (tool on PATH / service up / cluster ready), so a checkbox turned green before the student did anything. All now grade a **student-produced evidence file + a live guard**, so the first green is earned.

Everything below is pushed to both the course and GitHub. HEAD = commit `88ac36e`.

---

## Key identifiers (copy/paste)

```
labctl PATH:   export PATH=$PATH:/Users/alexmarket/.iximiuz/labctl/bin
Course slug:   devsecops-code-quality-security-7b8ee83b
```

**Live playgrounds (examiner-enabled, DO NOT delete):**
- `devsecops-base-0d12f62a`  — base/dev (Docker, Trivy, Semgrep, Gitleaks, cosign, Checkov, OpenTofu, vuln app on :8080)
- `devsecops-ai-7fdb7fbb`    — Ollama + qwen2.5:0.5b + Garak
- `devsecops-k8s-1ae0b5be`   — k3s + Kyverno, Vault/OpenBao, Falco, local registry, moto, Prowler

All old/dead playground definitions (base-c07e1a31, ai-f64ca106, base-c8251caa) were destroyed + removed today. Catalog now shows only the 3 above.

---

## CRITICAL rules (don't relearn these the hard way)

1. **Push the course ONLY from inside `course-devsecops/`:**
   ```
   cd course-devsecops && labctl content push -f course devsecops-code-quality-security-7b8ee83b -d .
   ```
   NEVER push from the repo root — `.labctlignore` only lives in `course-devsecops/`, so a root push leaks `docs/`, `rootfs/`, and 100 MB+ ColdFusion installers into the remote course. (We cleaned up exactly this leak today.)

2. **`labctl content push` with `-f` + `--file` fails** ("accepts 2 args, received 3"). Use a **full directory push** (`-d .`, no `--file`); it respects `.labctlignore`. The push is often terse/silent — **always verify by pulling** to `/tmp/verify`, not by trusting push output.

3. **Playgrounds = official base + init-task manifests**, NOT custom OCI rootfs. Base/ai use `--base flexbox` + a `dev-machine` machine + `drives: source: docker` (this is what brings the examiner). k8s uses `--base k3s`. Do NOT use `--base docker` (fixed machine name `docker-01`, can't rename → breaks `machine: dev-machine` task refs).

4. **`tagz:` must not contain reserved categories** (kubernetes, containers, security, ci-cd, iac, etc.) — causes 400 errors.

5. **No `ssh`/`exec` in labctl** — in-VM commands must be run from the browser Terminal tab (`laborant@dev-machine`). `labctl playground tasks <RUN-ID>` needs the run ID, not the name.

---

## What was done today (all pushed + committed)

- Cleaned the repo-root push leak; remote course verified byte-for-byte in sync (63/63 files).
- Rewired every lesson's `playground.name` to the 3 new examiner-enabled playgrounds.
- Destroyed + removed all old dead playgrounds.
- **Green-check milestone CONFIRMED** (examiner grades tasks end-to-end).
- `module-1/1.lesson-shift-left` `verify_docker_ready`: now grades `/home/laborant/docker-ready.txt` (commit `bd132a3`).
- **12 more readiness tasks fixed** to grade student-produced evidence files + live guard (commit `88ac36e`). Pattern per task:
  - `run:` requires an evidence file under `/home/laborant/` (exists + grep expected string) AND re-runs the original ambient check as a secondary guard.
  - `hintcheck:` prints the exact `... | tee /home/laborant/<file>` command.
  - matching `unit-1.md` activity writes that file via `tee`.
  - Fixed tasks: owasp `verify_vuln_app_running`, iac-security `verify_tools`, iac-runtime-moto `verify_tools`, sast-semgrep `verify_semgrep_installed`, tech-debt `verify_semgrep`, gitleaks `verify_gitleaks`, image-signing `verify_cosign`, zap-dast `verify_target_up`, falco `verify_falco_running`, llm-security `verify_ollama`, kyverno `verify_cluster_ready`, rbac-vault `verify_cluster`.
  - NOT changed (correctly require real work already): trivy-first-scan `verify_image_pulled` (student must `docker pull`), sbom `verify_sbom_generated`, docker-hardening `verify_hardened_dockerfile`, capstone `verify_pipeline_script`.

---

## TOMORROW — pick up here

### 1. Browser verification (needs you — can't be done from labctl)
Open 2-3 fixed lessons fresh from the course UI and confirm:
- First checkbox is **grey on boot** (not auto-green), turns green only after running the `tee` command.
- Then live-test the 3 moderate-risk verification greps:
  - **M1 L5 iac-runtime-moto** `verify_applied` — run `tofu apply` against moto (endpoint `http://localhost:5001`), save to `/home/laborant/iac-rt/apply.log`; confirm it greens. (Pattern greps for `apply complete|resources: N added|created` — watch OpenTofu's actual wording.)
  - **M5 L2 image-signing** `verify_signature` — sign an image, `cosign verify` it with the pubkey, save stdout+stderr to `/home/laborant/verify-output.txt`; confirm it greens. (Greps `verified|signature` — confirm the redirect captures the "Verified OK" line.)
  - **M5 L3 zap-dast** `verify_zap_report` — run a ZAP baseline scan against `http://localhost:8080`, save `zap-report.html` or `.json`; confirm it greens.
- Report back which green vs. stay grey; I'll fix any fragile greps.

### 2. Images (style contract in `.kiro/steering/devsecops-image-style.md`)
- **Regenerate** the shift-left and kyverno images — they had style violations (flames / readable title text). Flames/hackers need Alex's approval per the contract.
- **Fill in remaining diagrams** from the `.png.todo` prompt files. Find them:
  ```
  find course-devsecops -name '*.png.todo'
  ```
  Each `.png.todo` contains a ready-to-paste Gemini prompt. Generate the PNG, drop it next to the `.todo` (same name minus `.todo`), then push the lesson.

### 3. Optional / later
- Access control: optionally set course + playground access to `student:<training-name>` for a paid cohort (see `docs/IXIMIUZ_ACCESS_CONTROL.md` / `IXIMIUZ_TRAINING_ACCESS_CONTROL.md`).
- `rootfs/` is now deprecated reference only (kept for a possible future baked-image roadmap) — ignore unless revisiting pre-baked images.

---

## Verify remote is clean (sanity check to run first tomorrow)
```
export PATH=$PATH:/Users/alexmarket/.iximiuz/labctl/bin
rm -rf /tmp/verify && labctl content pull course devsecops-code-quality-security-7b8ee83b -d /tmp/verify
ls /tmp/verify   # expect: index.md, __static__, module-1 ... module-7  (NO docs/ rootfs/ reference-working/ nested course-devsecops/)
```
