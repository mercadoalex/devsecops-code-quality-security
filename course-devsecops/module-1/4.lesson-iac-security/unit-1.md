---
kind: unit

title: Infrastructure-as-Code Security

name: iac-security-unit-1
---

## Most cloud breaches aren't clever hacks — they're a checkbox left wrong

Year after year, the leading cause of cloud data exposure is not a sophisticated attacker. It is a storage bucket left public, a security group open to `0.0.0.0/0`, or a database with its default password. These are **misconfigurations** — and because modern infrastructure is defined in code (Terraform, OpenTofu, Kubernetes YAML, CloudFormation), the misconfiguration lives in a text file you can scan *before* it ever becomes a real, exposed resource.

That is the entire idea of **Infrastructure-as-Code (IaC) security**: treat your infrastructure definitions like source code, and run a static scanner over them in the pull request. Catch the public bucket in review, not in a breach report.

::image-box
---
:src: __static__/iac-scan-flow-v1.png
:alt: Diagram with two input files on the left — a Terraform/OpenTofu .tf file and a Kubernetes pod.yaml — both flowing into a scanner box labelled "Checkov / trivy config" in the center, which checks them against a policy library (CIS benchmarks, provider best practices) and emits a report on the right listing PASSED and FAILED checks; a prominent note reads "static analysis only — nothing is deployed, no cloud credentials"
---
_IaC scanners read the definition files and check them against a policy library. Nothing is provisioned — it is pure static analysis of text._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tools:** Checkov (Apache 2.0) and `trivy config` (Apache 2.0)
- **Why it fits our microVM:** both read files and exit. Checkov is a Python CLI (~150 MB); `trivy config` reuses the Trivy binary you already have. No cloud account, no credentials, no `apply`.
- **Alternatives in the same family:** KICS and tfsec (both Apache 2.0) do the same job.
- **Playground:** `devsecops-base`.
::

::hint-box
---
:summary: Wait — are we going to deploy infrastructure? We're in a microVM.
---
No. This is the most important point of the lesson: **we provision nothing.** IaC security is *static analysis of text files*. Checkov and `trivy config` parse the `.tf` and `.yaml` files and check them against policy rules. They never call a cloud API, never need credentials, and never run `tofu apply`. You could scan a Terraform file for AWS on a laptop with no AWS account at all. That is exactly why it is a shift-left control — you catch the problem long before anything is created.
::

---

## 1. Terraform vs OpenTofu — a licensing detour that matters

The most common IaC language is **HCL** (HashiCorp Configuration Language), used by Terraform. In 2023 HashiCorp relicensed Terraform from the open-source MPL-2.0 to the **BUSL (Business Source License)** — source-available, but with commercial-use restrictions. The community responded by forking it into **OpenTofu**, hosted by the Linux Foundation and still under the fully open-source **MPL-2.0**.

| | Terraform | OpenTofu |
|---|---|---|
| License | BUSL (source-available) | MPL-2.0 (open source) |
| Syntax | HCL | HCL (drop-in compatible) |
| CLI | `terraform` | `tofu` |

::hint-box
---
:summary: Does the licensing change affect the security scan?
---
Not at all — Checkov and `trivy config` parse the HCL text regardless of which CLI would apply it. We reference **OpenTofu** because this course only ships truly open-source tooling, and because the Terraform→BUSL story is itself a DevSecOps lesson: your toolchain's license is part of your supply chain. The `.tf` we scan is valid for both.
::

---

## 2. Write a misconfigured OpenTofu file

**Activity — Terminal (dev):** Create an `iac/` folder and an OpenTofu file with two classic mistakes — a public storage bucket and a security group open to the world.

```bash
mkdir -p /home/laborant/iac

cat > /home/laborant/iac/main.tf << 'EOF'
# NOTE: this file is only ever SCANNED, never applied. No cloud account needed.

resource "aws_s3_bucket" "data" {
  bucket = "devsecops-demo-data"
}

# Misconfiguration: bucket ACL set to public-read
resource "aws_s3_bucket_acl" "data" {
  bucket = aws_s3_bucket.data.id
  acl    = "public-read"
}

# Misconfiguration: SSH open to the entire internet
resource "aws_security_group" "web" {
  name = "web-sg"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
EOF

echo "Wrote iac/main.tf (scan target only)"
```

::simple-task
---
:tasks: tasks
:name: verify_tf_file
---
#active
Create `/home/laborant/iac/main.tf` with the misconfigured OpenTofu resources above.

#completed
OpenTofu scan target is ready. ✓
::

---

## 3. Write a misconfigured Kubernetes manifest

IaC isn't only cloud HCL — your Kubernetes YAML is infrastructure-as-code too, and the same scanners read it. This matters because Module 4 is all Kubernetes.

**Activity — Terminal (dev):** Create a Pod manifest with the classic container-security mistakes — privileged, running as root, no resource limits.

```bash
cat > /home/laborant/iac/pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: demo
spec:
  containers:
    - name: app
      image: nginx:latest
      securityContext:
        privileged: true          # Misconfiguration: privileged container
        runAsNonRoot: false       # Misconfiguration: runs as root
      # Misconfiguration: no resource requests/limits set
EOF

echo "Wrote iac/pod.yaml (scan target only)"
```

::simple-task
---
:tasks: tasks
:name: verify_k8s_manifest
---
#active
Create `/home/laborant/iac/pod.yaml` as a Kubernetes manifest with the misconfigurations above.

#completed
Kubernetes scan target is ready. ✓
::

---

## 4. Scan both with Checkov, then trivy config

**Activity — Terminal (dev):** Confirm the scanners, then scan the whole `iac/` directory.

```bash
# Record both tool versions so the lab can confirm YOU ran this step
{ checkov --version; trivy --version; } | tee /home/laborant/iac-tools.txt

# Checkov scans every supported file in the directory (HCL + YAML)
checkov -d /home/laborant/iac --compact | tee /home/laborant/iac-scan.txt

# trivy config does the same job — you already have Trivy
trivy config /home/laborant/iac
```

Both scanners report each check as PASSED or FAILED, with the check ID (e.g. `CKV_AWS_20` for the public bucket) and the file and line. You should see failures for the public ACL, the open SSH port, the privileged container, and the missing limits.

::hint-box
---
:summary: Checkov or trivy config — which should I use?
---
Both read the same files and map findings to industry benchmarks (CIS, provider best practices). `trivy config` is convenient when Trivy is already in your pipeline — one tool for images, SBOMs, *and* IaC. Checkov has a larger policy library and friendlier output for pure IaC work, plus easy custom policies. Many teams run `trivy config` in the fast pre-commit stage and Checkov in the fuller CI stage. For this course, know that either one turns "someone left it public" into a failed check in the PR.
::

::simple-task
---
:tasks: tasks
:name: verify_scan_output
---
#active
Scan `/home/laborant/iac` and save the Checkov report to `/home/laborant/iac-scan.txt`.

#completed
Both scan targets analyzed; report saved. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_tools
---
#active
Run `checkov --version` and `trivy --version` to confirm both scanners are available — the check records them to `/home/laborant/iac-tools.txt`.

#completed
IaC scanners are ready. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **IaC** | Infrastructure-as-Code — infra defined in text (HCL, YAML) |
| **Misconfiguration** | A wrong setting (public bucket, open port, root pod) — top cloud-breach cause |
| **Static IaC scan** | Analyze definition files; **nothing is deployed** |
| **Checkov** | IaC scanner with a large policy library (CIS benchmarks) |
| **`trivy config`** | Trivy's IaC/misconfig scanner |
| **HCL** | HashiCorp Configuration Language (Terraform / OpenTofu) |
| **OpenTofu (MPL-2.0)** | Open-source fork of Terraform after its BUSL relicense |
| **CKV_… / AVD_…** | Check IDs in Checkov / Trivy reports |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Seguridad de Infrastructure-as-Code (IaC)**

- La principal causa de exposición de datos en la nube no es un ataque sofisticado, sino una **mala configuración**: un bucket público, un puerto abierto a `0.0.0.0/0`, una contraseña por defecto.
- Como la infraestructura se define en código (HCL, YAML), puedes **escanear el texto antes de desplegar nada**. Eso es seguridad IaC: tratar la infraestructura como código fuente y escanearla en el pull request.
- **Importante:** aquí no se aprovisiona nada. Checkov y `trivy config` solo *leen* los archivos — sin cuenta cloud, sin credenciales, sin `apply`. Es análisis estático puro, ideal para un microVM.
- Usamos **OpenTofu** (MPL-2.0) en vez de Terraform (relicenciado a BUSL) porque este curso solo usa herramientas open source — y la licencia de tu toolchain es parte de tu cadena de suministro.
- Escaneaste un `.tf` (bucket público, SSH abierto) y un manifiesto de Kubernetes (contenedor privilegiado, como root, sin límites), y guardaste el reporte.
::

---

## Now Prove It

The challenge hands you a misconfigured OpenTofu file and a risky Kubernetes manifest and asks you to remediate every finding until both scanners pass clean.

::card
---
:challenge: challenges.iac-security-a78880fb
---
::
