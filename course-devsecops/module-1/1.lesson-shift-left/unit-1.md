---
kind: unit

title: Shift-Left & DevSecOps Culture

name: shift-left-devsecops-culture-unit-1
---

## The cheapest bug to fix is the one you never shipped

Here is an uncomfortable truth: the security review at the end of your project is already too late. By the time code reaches a final penetration test, the vulnerable design decisions were made weeks ago, the insecure dependency was pinned months ago, and fixing any of it means tearing up work your team thought was done.

**Shift-Left** is the response to that pain. Instead of bolting security onto the end of the pipeline, you move security checks as far *left* — as early — as possible: into the developer's editor, the pull request, the build. You already do this with tests. DevSecOps simply says: do it with security too.

::image-box
---
:src: __static__/shift-left-sdlc-v1.png
:alt: Diagram of a software development lifecycle shown as a left-to-right arrow with five phases — Plan, Code, Build, Test, Deploy — and a curved red arrow labelled "Shift-Left" pointing from the Deploy phase back toward Plan and Code, with a cost curve underneath showing the cost to fix a defect rising steeply from cents during Plan to thousands during Deploy
---
_The later a defect is found, the more it costs to fix. Shift-Left moves security checks toward the cheap end of the curve._
::

| Where security lives | Traditional (Sec-last) | DevSecOps (Shift-Left) |
|---|---|---|
| Design | Ad hoc | Threat modeling in planning |
| Coding | None | IDE linters, SAST on commit |
| Build | None | Dependency + image scanning |
| Test | Final pentest | Automated security gates in CI |
| Deploy | Manual sign-off | Policy-as-code, signed artifacts |
| Runtime | Hope | Continuous detection (Falco) |

::hint-box
---
:summary: Do I need a security background to follow this course? No.
---
If you can use a terminal, edit a file, and read an error message, you can do every exercise here. Each security concept is introduced from zero, and every command is paste-ready. The goal is to make security a normal part of how you build software — not a specialist's dark art.
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tools:** Docker (Apache 2.0) and Trivy (Apache 2.0)
- **Why they fit our microVM:** both are standard CLIs with modest memory needs; Trivy is a single binary that scans and exits.
- **A note on tool choices in this course:** the tools named in each lesson are *concept vehicles*. Where a well-known tool is too heavy for a 2 GiB microVM (for example SonarQube), we teach the same concept with a lighter open-source equivalent and name the enterprise reference in a hint box. Every tool used here is open source (Apache 2.0, MIT, or LGPL).
- **Lab playgrounds:** this course uses three playgrounds — `devsecops-base` (Docker, Trivy, Semgrep, Gitleaks, cosign), `devsecops-k8s` (k3s, Kyverno, Vault, Argo CD, Falco), and `devsecops-ai` (Ollama + a small model, Garak). Each lesson opens the right one automatically.
::

---

## 1. What "DevSecOps" actually means

DevOps broke down the wall between developers and operations. **DevSecOps** adds security as a shared responsibility rather than a gate owned by one team at the end.

The culture rests on three ideas:

- **Security is everyone's job.** Developers, operators, and security engineers share ownership. Security does not "approve" at the end — it builds guardrails that run automatically.
- **Automate the checks.** Humans are bad at remembering to scan every image and rotate every secret. Machines are good at it. Encode the policy once; let the pipeline enforce it forever.
- **Fast feedback beats perfect audits.** A scan that fails a pull request in 30 seconds prevents far more incidents than a thorough audit nobody reads.

::hint-box
---
:summary: Isn't "security is everyone's job" just a way to make developers do more work?
---
It feels that way only when the tools are bad. Good DevSecOps gives developers feedback where they already work — in the PR, in the editor — with a clear fix. The security team's job shifts from gatekeeping to building those guardrails and handling the genuinely hard cases. Nobody is asking a developer to become a penetration tester.
::

---

## 2. Your lab toolchain

This lab boots with a DevSecOps toolchain already installed. You will meet each tool in its own unit, but here is the map.

::image-box
---
:src: __static__/devsecops-toolchain-v1.png
:alt: A pipeline diagram showing a commit flowing left to right through stages — Code (SonarQube SAST), Build (Trivy image scan plus SBOM), CI (Gitleaks secret scan and image signing), Deploy (Argo CD GitOps and Kyverno policy), and Runtime (Falco detection) — with each tool labelled under its stage
---
_The DevSecOps toolchain you will build across this course — one control at every stage of the pipeline._
::

| Tool | Stage | What it does |
|---|---|---|
| Trivy | Build | Scans images for CVEs, generates SBOMs |
| SonarQube | Code | Static analysis (SAST), quality gates |
| Kyverno | Deploy | Kubernetes admission policy-as-code |
| Vault | Deploy/Runtime | Secrets management |
| Gitleaks | CI | Secret scanning in Git history |
| Argo CD | Deploy | GitOps continuous delivery |
| Falco | Runtime | Behavioral threat detection |
| Ollama + Garak | AI | Local LLM serving + LLM vulnerability scanning |

**Activity — Terminal (dev):** Confirm Docker is running. Everything else in this course builds on it.

```bash
# Confirm the Docker daemon is up and reachable
docker info
```

::simple-task
---
:tasks: tasks
:name: verify_docker_ready
---
#active
In the **Terminal (dev)** tab, run `docker info` and confirm the daemon responds without an error.

#completed
Docker is up and reachable. ✓
::

---

## 3. Run your first security scan

**Trivy** is an open-source scanner from Aqua Security — the Swiss-army knife of this course. It scans container images, filesystems, Git repos, and Kubernetes clusters for known vulnerabilities, and it can produce a software bill of materials. You will use it heavily in Units 1, 3, and 7.

No slow build-up here — let's *do* security in your very first lesson. You'll scan a real container image and watch Trivy report actual findings.

**Activity — Terminal (dev):** Scan a small base image and save the result. (First run downloads the vulnerability database — give it a moment.)

```bash
# Scan a small image; Trivy downloads its vuln DB on first run, then reports findings
trivy image --scanners vuln alpine:3.20 | tee /home/laborant/first-scan.txt
```

> ⏱️ The first scan downloads the vulnerability database and can take 30–60 seconds.

When it finishes you'll see a table of any known vulnerabilities in that image, grouped by severity. That's it — you just ran a real security control.

::hint-box
---
:summary: I barely understand the output — is that a problem?
---
Not at all. Right now the goal is simply to *see a scanner produce findings* — the muscle memory of "scan before you trust." You don't need to interpret severities, fixed versions, or CVE IDs yet. **Unit 3 covers reading a Trivy report, severity levels, and turning a scan into a build gate in full detail.** For now, a table on screen = success.
::

::simple-task
---
:tasks: tasks
:name: verify_first_scan
---
#active
In the **Terminal (dev)** tab, run the Trivy scan above so it writes `/home/laborant/first-scan.txt`.

#completed
You ran your first vulnerability scan — security in action from minute one. ✓
::

---

## 4. Write your DevSecOps manifesto

Culture is not a slide deck — it is a set of principles your team actually agrees to. Writing one down, in your own words, is how you internalize it.

You'll now create a small text file that captures your DevSecOps principles. It just needs to contain the word **shift** somewhere. Pick whichever of the two methods below feels comfortable — both produce the same result.

> 💡 New to the terminal? That's fine — this course is for the whole IT team, not just engineers. Follow **Option A** exactly, or use the point-and-click **Option B**. You can't break anything.

**Option A — Terminal (recommended, one line).** In the **Terminal (dev)** tab, copy the single line below, paste it, and press **Enter**. It writes the file for you in one go (no multi-line typing).

```bash
printf '%s\n' 'Our DevSecOps principles:' '1. Shift-left: find and fix security issues as early as possible.' '2. Security is a shared responsibility, not a final gate.' '3. Automate every repeatable security check.' > /home/laborant/devsecops-manifesto.txt
```

Then confirm it was created by printing it back (optional):

```bash
cat /home/laborant/devsecops-manifesto.txt
```

You should see the four lines you just wrote. If you do, you're done.

::hint-box
---
:summary: Prefer not to use the terminal? Use the editor instead (Option B).
---
**Option B — VS Code editor (no terminal needed):**

1. Open the **IDE** tab in your lab (that's the built-in VS Code editor).
2. Create a new file: **File → New File**.
3. Type a few lines of your own DevSecOps principles — just make sure **one line contains the word "shift"** (for example: _"Shift-left: catch security issues early."_).
4. Save it: **File → Save**, and name it exactly `devsecops-manifesto.txt` in the `/home/laborant` folder.

That's it — the check below will turn green either way.
::

::hint-box
---
:summary: Something went wrong / the terminal looks stuck on a ">" symbol?
---
If your terminal shows a lonely `>` on a new line, it's waiting for you to finish a command — just press **Ctrl + C** to cancel and start over with the one-line Option A command above (copy the whole line at once). Nothing is broken.
::

::simple-task
---
:tasks: tasks
:name: verify_manifesto_file
---
#active
Create the file `/home/laborant/devsecops-manifesto.txt` (via Option A or Option B) containing at least one line with the word **shift**.

#completed
Your DevSecOps manifesto exists and captures the Shift-Left principle. ✓
::

---

When all the checks above are green, this lesson is complete. Your progress is saved automatically — move straight on to the next lesson.

## Key concepts reference

| Concept | Detail |
|---|---|
| **Shift-Left** | Move security checks as early in the SDLC as possible |
| **DevSecOps** | Security as a shared, automated responsibility across Dev + Ops |
| **Cost-of-defect curve** | Fixing a bug gets exponentially more expensive the later it is found |
| **Guardrails, not gates** | Automated checks that give fast feedback instead of end-of-line approvals |
| **SAST** | Static Application Security Testing — analyze source code without running it |
| **CVE** | Common Vulnerabilities and Exposures — a public catalog of known flaws |
| **SBOM** | Software Bill of Materials — an inventory of everything inside an artifact |
| **Trivy** | Open-source scanner for images, filesystems, repos, and clusters |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Shift-Left y cultura DevSecOps**

- La seguridad que espera hasta el final del proyecto llega demasiado tarde y cuesta mucho más corregir. **Shift-Left** significa mover los controles de seguridad lo más a la *izquierda* posible: al editor, al pull request, al build.
- **DevSecOps** convierte la seguridad en una responsabilidad compartida y automatizada entre Desarrollo, Operaciones y Seguridad — no en una puerta al final.
- Tres ideas clave: la seguridad es tarea de todos, automatiza los controles repetibles, y el feedback rápido en el PR supera a una auditoría lenta.
- En este laboratorio confirmaste que **Docker** y **Trivy** (el escáner de vulnerabilidades que usarás en todo el curso) están listos, y escribiste tu propio manifiesto DevSecOps.
- Herramientas del curso: Trivy, SonarQube, Kyverno, Vault, Gitleaks, Argo CD, Falco, Ollama y Garak — una por cada etapa del pipeline.
::
