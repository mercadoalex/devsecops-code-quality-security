---
kind: unit

title: "IaC: From Static Scan to Live Posture (Optional)"

name: iac-runtime-moto-unit-1
---

## The scan said the code was fine. The account still got breached. How?

> **Optional advanced lesson.** The core IaC lesson (static scanning) is all you
> need to pass Module 1. This lesson goes one step further for those who want to
> see the full picture — it's heavier, and it's entirely optional.

In the previous lesson you caught misconfigurations by scanning `.tf` files *before* applying them. That is shift-left, and it is essential. But it has a blind spot: static scanning sees only what's **in the files you scanned**. It can't see a bucket someone created by hand in the console, a drift between code and reality, or a risky interaction between resources that only emerges once they're deployed together. For that you need to scan the **live account** itself — its actual, current state. That's **Cloud Security Posture Management (CSPM)**.

This lesson closes the loop. You'll `apply` OpenTofu against a **local AWS emulator** (moto), producing a live (emulated) account, then scan that account with **Prowler** — and see findings that the static scan never could.

::image-box
---
:src: __static__/iac-static-vs-posture-v1.png
:alt: Two-stage diagram. Stage 1 "Static (pre-deploy)" shows a .tf file scanned by Checkov before anything exists. Stage 2 "Posture (runtime)" shows OpenTofu applying to a moto emulated AWS account, then Prowler scanning the live account's actual resources and reporting findings; a caption notes that posture scanning also catches drift and console-created resources that static scans miss
---
_Static scanning checks the code before deploy; posture scanning (Prowler) checks the live account after — catching drift and out-of-band changes the files never show._
::

::note-box
---
:summary: 🧰 Tool & license — and why NOT LocalStack
---
- **Tools:** moto (Apache 2.0) as the AWS emulator; OpenTofu (MPL 2.0) to apply; Prowler (Apache 2.0) for the posture scan
- **Why not LocalStack:** as of March 2026, LocalStack consolidated its images, archived the open-source Community repo (no more updates/patches), and gated the free "Hobby" tier behind an account with a **non-commercial-use restriction** — unsuitable for a paid course and contrary to this course's all-open-source rule. **moto** (`moto_server`) is Apache 2.0, account-free, and much lighter.
- **Why it's on the `devsecops-k8s` (4 GiB) playground:** running `moto_server` + `tofu apply` + Prowler at once needs more headroom than the 2 GiB base VM. Nothing here uses Kubernetes; we just borrow the roomier VM.
- **Still no real cloud:** moto is a local mock. No AWS account, no real credentials, no spend — the `apply` hits `http://localhost:5001`, not AWS.
- **Playground:** `devsecops-k8s`.
::

::hint-box
---
:summary: Static scan vs posture scan — isn't this the same SAST/DAST idea again?
---
Exactly the same shape, applied to infrastructure. **Static IaC scan (Checkov)** = read the definition before it runs, like SAST reads code. **Posture scan (Prowler)** = inspect the live, running account, like DAST probes the running app. Neither replaces the other: static catches problems early and cheaply; posture catches what actually exists right now, including drift and changes made outside your IaC. Mature cloud teams run both, continuously.
::

---

## 1. Confirm the stack

**Activity — Terminal (dev):** Check the three tools are present.

```bash
moto_server --help | head -n 2
tofu version
prowler --version
```

::simple-task
---
:tasks: tasks
:name: verify_tools
---
#active
Confirm `moto_server`, `tofu`, and `prowler` are all installed.

#completed
The runtime IaC stack is ready. ✓
::

---

## 2. Start the local AWS emulator

**Activity — Terminal (dev):** Launch moto as a standalone server on port 5001.

```bash
# moto_server emulates AWS APIs locally on port 5001 — no account, no cost
nohup moto_server -p 5001 > /home/laborant/moto.log 2>&1 &
sleep 2

# Confirm it answers
curl -s -o /dev/null -w "moto HTTP %{http_code}\n" http://localhost:5001/
```

::hint-box
---
:summary: How do OpenTofu and Prowler talk to moto instead of real AWS?
---
Both honor the standard AWS SDK settings. You point the **endpoint** at `http://localhost:5001` and use dummy credentials. For OpenTofu, the AWS provider takes an `endpoints { ... }` block (or `AWS_ENDPOINT_URL`); for the AWS CLI / Prowler you set `AWS_ENDPOINT_URL=http://localhost:5001` and `AWS_ACCESS_KEY_ID=test` / `AWS_SECRET_ACCESS_KEY=test`. Because it's a mock, the credentials are ignored — they just have to be present so the SDK doesn't complain.
::

::simple-task
---
:tasks: tasks
:name: verify_moto_running
---
#active
Start `moto_server` on port 5001 and confirm it responds.

#completed
The AWS emulator is running locally. ✓
::

---

## 3. Apply OpenTofu against the emulator

**Activity — Terminal (dev):** Create a small config pointed at moto, with one deliberately public bucket, and apply it.

```bash
mkdir -p /home/laborant/iac-rt && cd /home/laborant/iac-rt
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

cat > main.tf << 'EOF'
provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_requesting_account_id  = true
  endpoints { s3 = "http://localhost:5001" }
}

resource "aws_s3_bucket" "data" {
  bucket = "demo-data"
}

# Deliberately public — a posture scan should flag this on the LIVE account
resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl    = "public-read"
}
EOF

tofu init -no-color | tee apply.log
tofu apply -auto-approve -no-color | tee -a apply.log
```

> ⏱️ `tofu init` downloads the AWS provider on first run — allow a minute.

::simple-task
---
:tasks: tasks
:name: verify_applied
---
#active
Apply the OpenTofu config against moto and capture the output to `iac-rt/apply.log`.

#completed
You provisioned (emulated) infrastructure — safely, locally. ✓
::

---

## 4. Scan the live account with Prowler

Now the resources *exist* in the emulated account. Prowler inspects what's actually there — not your files.

**Activity — Terminal (dev):** Run Prowler against the moto endpoint.

```bash
cd /home/laborant/iac-rt
export AWS_ENDPOINT_URL=http://localhost:5001
export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=us-east-1

# Scan S3 checks against the emulated account; save the report
prowler aws --service s3 --endpoint-url http://localhost:5001 2>&1 \
  | tee /home/laborant/iac-rt/prowler-report.txt | tail -n 30
```

Prowler reports PASS/FAIL per check against the account's real state — for example a FAIL for the public bucket you just created. That's a finding about the **live account**, produced after deploy, the way a continuous CSPM scan runs in production.

::hint-box
---
:summary: Prowler flagged the same public bucket Checkov would have. So why run both?
---
Here they overlap because the only resource came from your `.tf`. The difference shows the moment reality diverges from code: someone makes a bucket public in the console, a drifted resource lingers after a half-failed apply, or a third service enables public access indirectly. Checkov never sees those — they're not in your files. Prowler does, because it reads the account. Static scanning prevents; posture scanning verifies. Run static in the PR, posture continuously against the account.
::

::simple-task
---
:tasks: tasks
:name: verify_prowler_report
---
#active
Run Prowler against the emulated account and save the report to `iac-rt/prowler-report.txt`.

#completed
You ran a cloud posture scan on a live (emulated) account. ✓
::

---

When all the checks above are green, this optional lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **CSPM** | Cloud Security Posture Management — scan the live account's state |
| **Static vs posture** | Scan the IaC files vs scan the deployed account |
| **Drift** | Live account differs from what the IaC code describes |
| **moto** | Apache-2.0 local AWS API emulator (`moto_server`) |
| **`AWS_ENDPOINT_URL`** | Point SDK/tools at the emulator instead of real AWS |
| **OpenTofu `endpoints`** | Provider block redirecting a service to the emulator |
| **Prowler** | Apache-2.0 cloud posture / compliance scanner |
| **Why not LocalStack** | OSS community image archived; free tier now account-gated + non-commercial |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**IaC: del escaneo estático a la postura en vivo (opcional)**

- Lección **opcional avanzada**. El escaneo estático de la lección anterior detecta fallos *antes* de desplegar, pero solo ve lo que está en los archivos. No ve *drift* ni recursos creados por fuera del IaC. Para eso se escanea la **cuenta en vivo**: eso es **CSPM** (gestión de postura de seguridad en la nube).
- Aplicaste OpenTofu contra un **emulador local de AWS (moto)** — sin cuenta real, sin credenciales reales, sin coste (todo apunta a `http://localhost:5001`) — y luego escaneaste la cuenta emulada con **Prowler**.
- **Por qué no LocalStack:** desde marzo de 2026 archivaron el repo open source de la edición Community (sin parches) y el tier gratuito "Hobby" quedó restringido a uso **no comercial** y tras una cuenta — inadecuado para un curso de pago y contrario a la regla "todo open source". **moto** (Apache 2.0) es libre, sin cuenta y más ligero.
- Corre en el playground de **4 GiB** por ser más pesado (moto + tofu + Prowler); no usa Kubernetes.
- **Estático vs postura:** igual que SAST vs DAST — el estático previene en el PR; la postura verifica el estado real de la cuenta de forma continua. Se usan ambos.
::

---

## Now Prove It

The challenge asks you to apply a config to moto, scan the live account with Prowler, remediate a flagged resource, and re-scan to show the finding clear.

::card
---
:challenge: challenges.iac-runtime-b4d0f1f7
---
::
