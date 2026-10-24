---
kind: unit

title: Software Bill of Materials (SBOM)

name: software-bill-of-materials-unit-1
---

## When the next Log4Shell hits, "do we use it?" must take seconds, not days

In December 2021 a vulnerability in a logging library called Log4j set the industry on fire. The hardest part for most teams was not fixing it — it was *finding* it. "Do we even use Log4j, and where?" took some organizations days to answer. That question should take seconds.

A **Software Bill of Materials (SBOM)** is the answer. It is a complete, machine-readable inventory of every component inside an artifact — every library, every version, every license. With an SBOM on file, "are we affected?" becomes a one-line query.

::image-box
---
:src: __static__/sbom-concept-v1.png
:alt: Diagram of a container image shown as a box being X-rayed, revealing an inventory list to its right titled "SBOM" with columns for component name, version, and license — entries include openssl 3.0.11, python 3.12.1, libc 2.36 — with a note that the same SBOM can later be re-scanned against new CVEs without rebuilding the image
---
_An SBOM is an itemized inventory of everything inside an artifact — the "ingredients label" for your software._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tool:** Trivy (Apache 2.0) for SBOM generation and scanning
- **Alternatives:** Syft (Apache 2.0) generates SBOMs; Grype (Apache 2.0) scans them — a popular Syft+Grype pairing does the same job.
- **Why it fits our microVM:** an SBOM is a small JSON file; generating and re-scanning it are near-instant.
- **Playground:** `devsecops-base`.
::

::hint-box
---
:summary: How is an SBOM different from just running a Trivy scan?
---
A Trivy scan answers "what's vulnerable *right now*". An SBOM answers "what's *inside*", independent of today's vulnerability database. The power is in the separation: you generate the SBOM once at build time, store it, and later re-scan that stored SBOM whenever a new CVE is published — no rebuild, no access to the original image needed. The scan is a snapshot; the SBOM is the durable record.
::

---

## 1. Two formats you'll meet

| Format | Steward | Notes |
|---|---|---|
| **CycloneDX** | OWASP | Security-focused, compact, widely used in AppSec tooling |
| **SPDX** | Linux Foundation | License-focused, common in open-source compliance |

Trivy generates both. CycloneDX is the more common default in a DevSecOps context, so we use it here.

---

## 2. Generate a CycloneDX SBOM

**Activity — Terminal (dev):** Produce a CycloneDX SBOM for a base image.

```bash
# Generate a CycloneDX SBOM from a container image
trivy image --format cyclonedx -o /home/laborant/sbom.cdx.json python:3.12-slim

# Peek at the format header
head -c 300 /home/laborant/sbom.cdx.json; echo
```

::simple-task
---
:tasks: tasks
:name: verify_sbom_generated
---
#active
Generate `/home/laborant/sbom.cdx.json` as a CycloneDX SBOM of `python:3.12-slim`.

#completed
CycloneDX SBOM generated. ✓
::

---

## 3. Count what's inside

An SBOM is only useful if you can query it. The JSON has a `components` array — counting it tells you how big your supply chain really is.

**Activity — Terminal (dev):** Count the components and save the number.

```bash
# Count components in the SBOM and record the number
jq '.components | length' /home/laborant/sbom.cdx.json > /home/laborant/component-count.txt
cat /home/laborant/component-count.txt
```

::hint-box
---
:summary: The number looks big for a "slim" image — is that normal?
---
Yes. Even a slim base image pulls in dozens of OS packages and shared libraries. That is exactly why the SBOM matters: most of those components you never consciously chose, yet each is part of your attack surface. Seeing the real count is often the moment "supply chain security" stops being an abstract phrase.
::

::simple-task
---
:tasks: tasks
:name: verify_component_count
---
#active
Write the number of components in the SBOM to `/home/laborant/component-count.txt`.

#completed
Component count recorded. ✓
::

---

## 4. Re-scan the SBOM for vulnerabilities

The payoff: scan the stored SBOM directly, without the original image. This is how you answer "are we affected?" for a brand-new CVE months after the build.

**Activity — Terminal (dev):** Scan the SBOM and save the result.

```bash
# Scan the SBOM itself against the current vulnerability DB
trivy sbom /home/laborant/sbom.cdx.json | tee /home/laborant/sbom-scan.txt
```

::hint-box
---
:summary: Why scan the SBOM instead of the image again?
---
Three reasons. First, speed: the SBOM is a small JSON file; re-scanning it is near-instant versus pulling and unpacking a multi-hundred-megabyte image. Second, availability: you may not have the original image anymore, but you kept the SBOM. Third, scale: a central store of SBOMs for every service lets you answer "which of our 200 services ship the newly vulnerable library?" in one batch query. That is the Log4Shell problem solved.
::

::simple-task
---
:tasks: tasks
:name: verify_sbom_scanned
---
#active
Run `trivy sbom` on your SBOM and save the output to `/home/laborant/sbom-scan.txt`.

#completed
SBOM scanned for vulnerabilities. ✓
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **SBOM** | Machine-readable inventory of every component in an artifact |
| **CycloneDX** | OWASP SBOM format, security-focused |
| **SPDX** | Linux Foundation SBOM format, license-focused |
| **`trivy image --format cyclonedx`** | Generate an SBOM from an image |
| **`trivy sbom <file>`** | Scan a stored SBOM against current CVEs |
| **Supply-chain security** | Managing risk from components you didn't write |
| **Re-scan without rebuild** | Query old SBOMs when new CVEs appear |
| **Log4Shell lesson** | "Are we affected?" must be a fast query, not a hunt |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**SBOM — Software Bill of Materials**

- Un **SBOM** es un inventario legible por máquina de **todos los componentes** de un artefacto: cada librería, versión y licencia. Es la "etiqueta de ingredientes" de tu software.
- Tras Log4Shell, la pregunta "¿usamos esta librería y dónde?" debe responderse en segundos. Con un SBOM guardado, es una consulta de una línea.
- Un escaneo de Trivy dice "qué es vulnerable *ahora*"; el SBOM dice "qué hay *dentro*". Generas el SBOM una vez en el build y lo **re-escaneas** cuando aparecen nuevos CVEs — sin reconstruir la imagen.
- Formatos: **CycloneDX** (OWASP, enfocado a seguridad) y **SPDX** (Linux Foundation, enfocado a licencias).
- Generaste un SBOM CycloneDX, contaste sus componentes, y lo escaneaste con `trivy sbom`.
::

---

## Now Prove It

The challenge asks you to generate an SBOM, verify it with a query, and re-scan it to demonstrate the full supply-chain workflow.

::card
---
:challenge: challenges.sbom-generate-63de728a
---
::
