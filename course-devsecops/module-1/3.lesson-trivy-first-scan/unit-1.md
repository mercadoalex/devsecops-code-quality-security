---
kind: unit

title: Your First Vulnerability Scan with Trivy

name: trivy-first-scan-unit-1
---

## Every image you pull is a bag of other people's code

When you write `FROM python:3.9-slim`, you inherit an operating system, a language runtime, and dozens of system libraries — none of which you wrote and all of which may contain known vulnerabilities. A scanner's job is to open that bag, read the version of everything inside, and check each one against a public database of known flaws (**CVEs**).

In this lesson you run that scan for the first time, learn to read the report, and turn it into an automated gate that fails a build when something critical shows up. This is the moment security stops being a document and becomes a command.

::image-box
---
:src: __static__/trivy-scan-flow-v1.png
:alt: Flow diagram showing a container image on the left feeding into Trivy in the center, which cross-references two databases labelled "OS packages" and "language dependencies" against a "vulnerability DB (CVEs)", producing a report on the right that lists vulnerabilities grouped by severity — CRITICAL, HIGH, MEDIUM, LOW
---
_Trivy reads every package in an image and matches each version against the CVE database, then groups findings by severity._
::

::hint-box
---
:summary: What exactly is a CVE?
---
**CVE** stands for Common Vulnerabilities and Exposures. Each entry is a public, uniquely numbered record of a specific flaw — for example `CVE-2023-4911`. The identifier lets everyone (scanners, vendors, you) refer to the same vulnerability unambiguously. Trivy's database maps package versions to the CVEs that affect them.
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tool:** Trivy (Apache 2.0) — `trivy`
- **Why it fits our microVM:** a single Go binary; scans an image and exits. The vulnerability DB download (~tens of MB) happens once and is cached.
- **Alternatives in the same family:** Grype (SCA/images) and Syft (SBOM), both Apache 2.0 — noted here so you know Trivy is not the only option.
- **Playground:** `devsecops-base`.
::

---

## 1. Pull a scan target

Let's scan a real, widely used base image. `python:3.9-slim` is old enough to carry a healthy list of findings, which makes it a good teaching target.

**Activity — Terminal (dev):** Pull the image.

```bash
# Pull an older base image that will have known CVEs
docker pull python:3.9-slim
```

::simple-task
---
:tasks: tasks
:name: verify_image_pulled
---
#active
Pull `python:3.9-slim` so Trivy has a local image to scan.

#completed
Scan target is present locally. ✓
::

---

## 2. Run the scan

**Activity — Terminal (dev):** Scan the image and read the human-readable table.

```bash
# Scan the image; Trivy downloads its vuln DB on first run
trivy image python:3.9-slim
```

> ⏱️ The first scan downloads the vulnerability database and can take 30–60 seconds.

The output groups findings by severity. The columns that matter most: the CVE ID, the installed version, the fixed version (if any), and the severity.

::hint-box
---
:summary: What do the severity levels mean, and which should fail my build?
---
Trivy uses CVSS-based severities: **CRITICAL, HIGH, MEDIUM, LOW, UNKNOWN**. A common, pragmatic policy is to *fail the build* on CRITICAL and HIGH that have a fix available, and *warn* on everything else. Failing on findings with no fix available just blocks you with no action to take — so filter with `--ignore-unfixed` when you want a gate that only stops fixable problems.
::

---

## 3. Save a machine-readable report

Humans read the table; pipelines read JSON. Save a JSON report so a script can act on it.

**Activity — Terminal (dev):** Write the report to a file.

```bash
# Produce a JSON report a pipeline can parse
trivy image -f json -o /home/laborant/trivy-report.json python:3.9-slim

# Confirm it was written
head -c 200 /home/laborant/trivy-report.json; echo
```

::simple-task
---
:tasks: tasks
:name: verify_scan_report
---
#active
Generate `/home/laborant/trivy-report.json` with Trivy's JSON output.

#completed
Machine-readable scan report saved. ✓
::

---

## 4. Turn the scan into a gate

A scan that only prints is a suggestion. A scan that returns a non-zero exit code when it finds something critical is a *gate* — it can stop a pipeline. Trivy supports this directly with `--exit-code` and `--severity`.

**Activity — Terminal (dev):** Create a gate script that fails on critical findings.

```bash
# A reusable gate: exit 1 if any CRITICAL (fixable) vuln is found
cat > /home/laborant/gate.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail
IMAGE="${1:-python:3.9-slim}"
echo "Scanning ${IMAGE} — failing on CRITICAL (fixable) findings..."
trivy image --exit-code 1 --severity CRITICAL --ignore-unfixed "${IMAGE}"
EOF
chmod +x /home/laborant/gate.sh

# Run it — a non-zero exit means the gate blocked the build
/home/laborant/gate.sh python:3.9-slim || echo "GATE FAILED (as expected if CRITICALs exist)"
```

::hint-box
---
:summary: Why --ignore-unfixed in the gate?
---
A vulnerability with no released fix cannot be remediated by upgrading — blocking on it just stalls your pipeline with no action you can take. `--ignore-unfixed` keeps the gate actionable: it only fails on problems you can actually solve by bumping a version. You still *report* the unfixed ones (without `--exit-code`) so they are visible, but they do not block.
::

::simple-task
---
:tasks: tasks
:name: verify_gate_script
---
#active
Create `/home/laborant/gate.sh` that uses Trivy to fail (exit non-zero) on **CRITICAL** findings.

#completed
Your first automated security gate is written. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **Trivy image** | `trivy image <name>` — scan a container image for CVEs |
| **Severity** | CRITICAL / HIGH / MEDIUM / LOW / UNKNOWN (CVSS-based) |
| **`--exit-code 1`** | Return non-zero when matching vulns are found (makes a gate) |
| **`--severity`** | Limit the gate to specific severities |
| **`--ignore-unfixed`** | Only fail on vulns that have an available fix |
| **`-f json -o file`** | Write a machine-readable report |
| **CVE** | A uniquely numbered public record of one specific flaw |
| **Security gate** | An automated check that can block the pipeline on failure |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Tu primer escaneo de vulnerabilidades con Trivy**

- Cada imagen que usas (`FROM python:3.9-slim`) hereda un sistema operativo y decenas de librerías que no escribiste y que pueden tener vulnerabilidades conocidas (**CVEs**).
- `trivy image <nombre>` lee cada paquete de la imagen y lo compara con la base de datos de CVEs, agrupando hallazgos por severidad: **CRITICAL, HIGH, MEDIUM, LOW**.
- Guardaste un reporte en JSON (`-f json -o`) para que un pipeline pueda procesarlo.
- Creaste tu primer **gate de seguridad**: un script que usa `--exit-code 1 --severity CRITICAL` para que el build falle cuando hay hallazgos críticos. Con `--ignore-unfixed` el gate solo bloquea lo que realmente puedes corregir subiendo de versión.
::

---

## Now Prove It

The challenge gives you a vulnerable image and asks you to scan it, build a passing gate, then produce a remediated image that clears the same gate.

::card
---
:challenge: challenges.trivy-first-scan-26cd5ac1
---
::
