---
kind: unit

title: Docker Hardening & CVE Management

name: docker-hardening-cve-unit-1
---

## By default, your container is running as root

Here is the fact that surprises most people the first time they hear it: unless you say otherwise, the process inside your container runs as **root**. If an attacker breaks out of your app, they land as root inside the container — and a root-in-container escape to the host is a well-trodden path. The default is convenient and dangerous.

This lesson is about removing the dangerous defaults. You will harden a Dockerfile against the four mistakes that show up again and again — running as root, fat base images, baked-in secrets, and unpinned versions — and then manage the CVEs that remain.

::image-box
---
:src: __static__/docker-hardening-checklist-v1.png
:alt: A before-and-after split image. Left side "Risky" shows a Dockerfile with FROM ubuntu, running apt install of many tools, no USER line, and a hard-coded API key, flagged with red warning icons. Right side "Hardened" shows FROM python:3.12-slim, a pinned version, a created non-root appuser, a USER appuser line, and a note that secrets come from the runtime, flagged with green checks
---
_The four high-impact hardening moves: small pinned base, no secrets in the image, a dedicated non-root user, and a USER instruction._
::

::note-box
---
:summary: 🧰 Tool & license
---
- **Tools:** Docker (Apache 2.0) + Trivy (Apache 2.0)
- **Why it fits our microVM:** building a tiny image and scanning it are both light operations; the base images used are `-slim` to keep pulls small.
- **Playground:** `devsecops-base`.
::

::hint-box
---
:summary: If root-in-container is so bad, why is it the default?
---
History and convenience. Early container tooling assumed root, many base images expect it during build (installing packages needs root), and plenty of software was never written with "drop privileges" in mind. The build steps often *do* need root — but the *running* process almost never does. The hardening move is to do root-only work during build, then switch to an unprivileged user with `USER` before the app runs.
::

---

## 1. The four hardening moves

| Move | Risky | Hardened |
|---|---|---|
| **Base image** | `FROM ubuntu` (hundreds of packages = huge attack surface) | `FROM python:3.12-slim` or distroless |
| **Run as** | implicit root | dedicated non-root `USER` |
| **Secrets** | `ENV API_KEY=...` baked in | injected at runtime (env, mounted secret) |
| **Versions** | `latest` / unpinned | pinned tags / digests |

Each move shrinks either the attack surface or the blast radius. None of them makes your app slower.

::hint-box
---
:summary: Why does a smaller base image mean fewer CVEs?
---
Every package in the image is something Trivy can find a CVE in. A full `ubuntu` base ships hundreds of packages you never use — each one a potential finding you now have to triage. A `-slim` or distroless base ships the bare minimum, so there is simply less to be vulnerable. Shrinking the base often eliminates dozens of findings for free.
::

---

## 2. Write a hardened Dockerfile

**Activity — Terminal (dev):** Create a hardened Dockerfile that uses a slim base and runs as a non-root user.

```bash
mkdir -p /home/laborant/hardened

cat > /home/laborant/hardened/app.py << 'EOF'
import os
print("hardened app running as a non-root user")
print("secret comes from env:", bool(os.environ.get("APP_SECRET")))
EOF

cat > /home/laborant/hardened/Dockerfile << 'EOF'
# Small, pinned base — fewer packages, fewer CVEs
FROM python:3.12-slim

# Create an unprivileged user to run the app
RUN useradd --create-home --uid 10001 appuser
WORKDIR /home/appuser

COPY app.py .

# Drop privileges: everything below runs as appuser, not root
USER appuser

# No secrets in the image — they arrive at runtime
CMD ["python", "app.py"]
EOF

cat /home/laborant/hardened/Dockerfile
```

::simple-task
---
:tasks: tasks
:name: verify_hardened_dockerfile
---
#active
Create `/home/laborant/hardened/Dockerfile` with a non-root `USER` instruction.

#completed
Hardened Dockerfile written. ✓
::

---

## 3. Build and prove it runs unprivileged

**Activity — Terminal (dev):** Build the image and confirm the running process is not root.

```bash
# Build the hardened image
docker build -t hardened-app:latest /home/laborant/hardened

# The running user's UID must NOT be 0 (root)
docker run --rm hardened-app:latest id -u
# Expect: 10001
```

::simple-task
---
:tasks: tasks
:name: verify_image_built
---
#active
Build `hardened-app:latest` from your hardened Dockerfile.

#completed
Hardened image built. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_runs_nonroot
---
#active
Confirm `docker run --rm hardened-app:latest id -u` returns a non-zero UID (not root).

#completed
The container runs as a non-root user. ✓
::

---

## 4. Manage the CVEs that remain

Even a hardened image has CVEs. Managing them means triaging, not panicking.

**Activity — Terminal (dev):** Scan the hardened image and split findings into fixable and unfixable.

```bash
# All findings, grouped by severity
trivy image hardened-app:latest

# Only the findings you can actually fix by upgrading
trivy image --ignore-unfixed --severity HIGH,CRITICAL hardened-app:latest
```

::hint-box
---
:summary: What do I do with a CVE that has no fix?
---
You have three honest options: (1) accept the risk with a documented justification and a `.trivyignore` entry with an expiry date, (2) mitigate it another way (network policy, WAF, dropping the capability it needs), or (3) remove the component entirely if you don't use it. What you do *not* do is silence it and forget it — an unfixed CVE with no fix today often gets a fix next month, and your pipeline should surface it again when it does.
::

---

When all the checks above are green, this lesson is complete.

## Key concepts reference

| Concept | Detail |
|---|---|
| **Root in container** | The dangerous default; drop it with `USER` |
| **`USER` instruction** | Switches the running user to an unprivileged account |
| **Slim / distroless base** | Minimal packages = smaller attack surface, fewer CVEs |
| **Pinned tags / digests** | Reproducible, auditable image contents |
| **Secrets at runtime** | Never `ENV SECRET=...`; inject via env or mounted secret |
| **`--ignore-unfixed`** | Focus triage on CVEs you can actually remediate |
| **`.trivyignore`** | Documented, time-boxed exceptions for accepted CVEs |
| **Blast radius** | How much damage a compromise can do — minimized by least privilege |

::hint-box
---
:summary: 🌎 Versión en español — resumen de la lección
---
**Hardening de Docker y gestión de CVEs**

- Por defecto, el proceso dentro de un contenedor corre como **root**. Si un atacante escapa de tu app, cae como root — un riesgo grande.
- Las cuatro mejoras de alto impacto: base **slim/distroless** (menos paquetes, menos CVEs), un **usuario no-root** con la instrucción `USER`, **sin secretos** dentro de la imagen (se inyectan en runtime), y **versiones fijadas**.
- Escribiste un Dockerfile endurecido, lo construiste y comprobaste que corre como UID no-root.
- Gestionar los CVEs restantes significa **triaje**: usa `--ignore-unfixed` para centrarte en lo corregible; para un CVE sin solución, documenta la aceptación del riesgo con fecha de expiración (`.trivyignore`), mitígalo de otra forma, o elimina el componente.
::

---

## Now Prove It

The challenge hands you a deliberately insecure Dockerfile and asks you to harden it so it runs as non-root and clears the HIGH/CRITICAL fixable gate.

::card
---
:challenge: challenges.docker-hardening-5361d5e5
---
::
