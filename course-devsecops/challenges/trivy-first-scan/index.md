---
kind: challenge

title: 'Build a Trivy Security Gate'

description: |
  Scan a vulnerable image, write a gate that fails on CRITICAL findings, then
  produce a remediated image that passes the same gate. This is the core loop
  of container security: scan, fail, fix, re-scan.

categories:
  - security

tagz:
  - trivy
  - cve
  - devsecops

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-c07e1a31

tasks:
  verify_gate_exists:
    machine: dev-machine
    user: laborant
    run: |
      FILE=/home/laborant/gate.sh
      if [ ! -f "${FILE}" ]; then
        echo "gate.sh not found"
        exit 1
      fi
      if ! grep -qi "exit-code" "${FILE}" || ! grep -qi "CRITICAL" "${FILE}"; then
        echo "gate.sh must use --exit-code and target CRITICAL severity"
        exit 1
      fi
      echo "gate present"

  verify_gate_blocks_vuln:
    machine: dev-machine
    user: laborant
    needs:
      - verify_gate_exists
    run: |
      if ! docker image inspect python:3.9-slim >/dev/null 2>&1; then
        docker pull python:3.9-slim >/dev/null 2>&1 || true
      fi
      if bash /home/laborant/gate.sh python:3.9-slim >/dev/null 2>&1; then
        echo "The gate should FAIL on the known-vulnerable python:3.9-slim image"
        exit 1
      fi
      echo "gate correctly blocks the vulnerable image"

  verify_remediated_image:
    machine: dev-machine
    user: laborant
    needs:
      - verify_gate_blocks_vuln
    run: |
      if ! docker image inspect app-remediated:latest >/dev/null 2>&1; then
        echo "Build an image tagged app-remediated:latest"
        exit 1
      fi
      if ! bash /home/laborant/gate.sh app-remediated:latest >/dev/null 2>&1; then
        echo "app-remediated:latest still fails the CRITICAL gate — remediate further"
        exit 1
      fi
      echo "remediated image passes the gate"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_remediated_image
    run: |
      echo "Challenge complete!"
---

## Scan, fail, fix, re-scan

Prove you can operate a container security gate end to end:

1. Write `/home/laborant/gate.sh` that uses `trivy image --exit-code 1 --severity CRITICAL`.
2. Show the gate **blocks** the known-vulnerable `python:3.9-slim`.
3. Build a remediated image tagged `app-remediated:latest` (use a current,
   patched base such as `python:3.12-slim`) that **passes** the same gate.

::hint-box
---
:summary: How do I build the remediated image?
---
Create a tiny Dockerfile on a patched base and build it:

```bash
printf 'FROM python:3.12-slim\nCMD ["python","--version"]\n' > Dockerfile
docker build -t app-remediated:latest .
```

A newer base image ships with patched system packages, so the CRITICAL gate
passes. Remediation in container security is often just "use a fresher base".
::

::simple-task
---
:tasks: tasks
:name: verify_gate_exists
---
#active
Write `gate.sh` using `trivy image --exit-code 1 --severity CRITICAL`.

#completed
Gate script present. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_gate_blocks_vuln
---
#active
Confirm the gate FAILS on the vulnerable `python:3.9-slim` image.

#completed
Gate blocks the vulnerable image. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_remediated_image
---
#active
Build `app-remediated:latest` on a patched base so it PASSES the gate.

#completed
Remediated image passes the gate. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you ran a complete scan-fix-rescan loop.

#completed
Trivy gate challenge complete. ✓
::
