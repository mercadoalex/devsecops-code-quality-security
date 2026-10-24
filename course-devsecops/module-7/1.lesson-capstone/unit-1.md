---
kind: unit

title: End-to-End DevSecOps Pipeline

name: end-to-end-pipeline-unit-1
---

## One commit, six gates, zero surprises

You've learned each control on its own. Now you assemble them into the thing that actually protects a real team: **a pipeline where every stage is a security gate**, and nothing reaches production unless it passes all of them. This is the whole course in one artifact — the point where "DevSecOps" stops being a list of tools and becomes a single, continuous flow from commit to deploy.

The chain you'll build, in order, from the earliest/cheapest check to the last line of defense:

::image-box
---
:src: __static__/pipeline-end-to-end-v1.png
:alt: Horizontal pipeline diagram with six gates left to right, each a box with its tool and a pass/fail gate symbol — 1 Secret scan (Gitleaks), 2 SAST (Semgrep), 3 Image CVE scan (Trivy), 4 SBOM (Trivy), 5 Sign (cosign), 6 Admission policy (Kyverno verifyImages) — a commit enters on the left and only a signed, policy-compliant deployment exits on the right into a prod namespace; any failing gate stops the flow with a red X
---
_The end-to-end pipeline: six gates in sequence. A change only reaches prod if it clears every one._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tools (all open source):** Gitleaks (MIT), Semgrep (LGPL), Trivy (Apache 2.0), cosign (Apache 2.0), Kyverno (Apache 2.0) on k3s
- **Why it fits our microVM:** each stage is a short-lived CLI run against local files and a local registry/cluster. Nothing external, no credentials leave the VM.
- **Playground:** `devsecops-k8s` (has the base scanners plus the cluster and registry).
::

::hint-box
---
:summary: Why this specific order of gates?
---
Cheapest and fastest first, so failures surface early and quickly. **Secret scanning** and **SAST** run on source in seconds — no build needed — so they fail a bad commit before you waste time building. **Image CVE scan** and **SBOM** need the built image. **Signing** happens once the image is deemed good. **Admission policy** is the last line, at deploy time, enforcing that only a signed, compliant image runs — it catches anything that somehow skipped the earlier stages (a manual `kubectl apply`, a tampered registry). Defense in depth means the final gate doesn't trust that the earlier ones ran.
::

---

## 1. Build the pipeline script

**Activity — Terminal (dev):** Create a pipeline script that chains the gates. Each stage fails the whole run on a problem.

```bash
cat > /home/laborant/pipeline.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
REPO=/home/laborant/app-src
IMAGE=localhost:5000/app:ci

echo "== Gate 1: secret scan (Gitleaks) =="
gitleaks detect -s "${REPO}" --no-banner

echo "== Gate 2: SAST (Semgrep) =="
semgrep scan --config auto --error --severity ERROR "${REPO}"

echo "== Build image =="
docker build -t "${IMAGE}" "${REPO}"
docker push "${IMAGE}"

echo "== Gate 3: image CVE scan (Trivy) =="
trivy image --exit-code 1 --ignore-unfixed --severity CRITICAL "${IMAGE}"

echo "== Gate 4: SBOM (Trivy) =="
trivy image --format cyclonedx -o /home/laborant/app.cdx.json "${IMAGE}"

echo "== Gate 5: sign (cosign) =="
COSIGN_PASSWORD="" cosign sign --key /home/laborant/cosign.key --yes "${IMAGE}"
cosign verify --key /home/laborant/cosign.pub "${IMAGE}"

echo "ALL GATES PASSED — image signed and ready to deploy"
EOF
chmod +x /home/laborant/pipeline.sh
cat /home/laborant/pipeline.sh
```

::simple-task
---
:tasks: tasks
:name: verify_pipeline_script
---
#active
Create `/home/laborant/pipeline.sh` chaining the Gitleaks, Semgrep, Trivy, and cosign stages.

#completed
Your end-to-end pipeline script is written. ✓
::

---

## 2. Run the pipeline

**Activity — Terminal (dev):** Run the pipeline against a clean sample app and capture the log. (The lab seeds a clean `app-src` and a cosign key pair.)

```bash
bash /home/laborant/pipeline.sh | tee /home/laborant/pipeline-run.log
```

If any gate fails, the run stops there with a non-zero exit — exactly what you want in CI. On a clean app, every gate passes and the image is signed.

::hint-box
---
:summary: A gate failed on my app — is that a bug?
---
No — that's the pipeline doing its job. A failing gate means a real problem was caught: a secret in the repo, an ERROR-level SAST finding, a CRITICAL fixable CVE, or a verification mismatch. Read the failing stage's output, fix the underlying issue (rotate the secret, fix the code, bump the base image), and re-run. "Green" should mean *earned*, not bypassed. The one thing never to do is add `|| true` to silence a gate.
::

::simple-task
---
:tasks: tasks
:name: verify_pipeline_runs
---
#active
Run the pipeline and capture its output to `/home/laborant/pipeline-run.log`.

#completed
The pipeline ran through all gates. ✓
::

---

## 3. Deploy — and let the policy be the final judge

The signed image now faces the last gate: a Kyverno `verifyImages` policy in the `prod` namespace that admits only images signed by your key.

**Activity — Terminal (dev):** Deploy the signed image to `prod`.

```bash
# The prod namespace has a verifyImages ClusterPolicy requiring your signature.
kubectl create namespace prod 2>/dev/null || true

kubectl -n prod create deployment app --image=localhost:5000/app:ci
kubectl -n prod rollout status deployment/app --timeout=90s
kubectl -n prod get deploy app
```

Because the image is signed with the key the policy trusts, admission succeeds and the deployment becomes ready. An *unsigned* image would be rejected at this step — the final proof that your chain holds end to end.

::hint-box
---
:summary: How is this the same idea as GitOps with Argo CD?
---
In a full GitOps setup you wouldn't run `kubectl` by hand — you'd commit this deployment manifest to Git and let **Argo CD** reconcile it into the cluster, where the same Kyverno policy still gates admission. The security properties are identical; GitOps just adds that every deploy is a reviewed, audited, revertible Git commit instead of a human command. The manual deploy here is the teaching version of that final stage.
::

::simple-task
---
:tasks: tasks
:name: verify_signed_image_deployed
---
#active
Deploy the signed image to the `prod` namespace and confirm it becomes ready (admitted by the policy).

#completed
The signed, scanned image is running in prod. The chain holds. ✓
::

---

When all the checks above are green, you've completed the capstone — and the course.

## Key concepts reference

| Stage | Tool | Catches |
|---|---|---|
| Secret scan | Gitleaks | Credentials in the repo |
| SAST | Semgrep | Insecure code patterns |
| Image CVE scan | Trivy | Vulnerable dependencies/OS packages |
| SBOM | Trivy | Supply-chain inventory for later re-scans |
| Sign | cosign | Integrity + provenance proof |
| Admission policy | Kyverno | Unsigned / non-compliant images at deploy |

| Principle | Detail |
|---|---|
| **Fail fast** | Cheapest checks (secrets, SAST) run first |
| **Defense in depth** | The final gate doesn't trust the earlier ones ran |
| **Never silence a gate** | Fix the issue; don't bypass with `|| true` |
| **GitOps** | The same gates, driven by reviewed Git commits |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Pipeline DevSecOps de extremo a extremo**

- Aquí ensamblas todos los controles en **un pipeline donde cada etapa es un gate de seguridad**: nada llega a producción sin pasarlos todos. Es el curso entero en un solo artefacto.
- Orden (del más barato y temprano al último): **1 Gitleaks** (secretos) → **2 Semgrep** (SAST) → build → **3 Trivy** (CVE) → **4 Trivy** (SBOM) → **5 cosign** (firma) → **6 Kyverno verifyImages** (admisión en el deploy).
- **Fail fast:** los checks de código (secretos, SAST) van primero, sin necesidad de build. La **política de admisión** es la última línea: solo admite imágenes firmadas y conformes, aunque algo se salte las etapas previas.
- Escribiste `pipeline.sh`, lo ejecutaste capturando el log, y desplegaste la imagen firmada en `prod` — la política la admite por estar firmada con tu clave; una imagen sin firmar sería rechazada.
- **Defensa en profundidad:** el gate final no confía en que los anteriores se ejecutaron. Nunca silencies un gate con `|| true`. En GitOps, los mismos gates se activan desde commits de Git revisados (Argo CD).
::

---

## Now Prove It

The capstone challenge asks you to run the full pipeline on a repo that contains one planted problem, fix it, and deploy the signed result to a policy-gated namespace.

::card
---
:challenge: challenges.devsecops-capstone-56f65b95
---
::
