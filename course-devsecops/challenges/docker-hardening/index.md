---
kind: challenge

title: 'Harden an Insecure Dockerfile'

description: |
  You inherit a Dockerfile that runs as root, uses a fat base, and bakes in a
  secret. Harden it so the image runs as a non-root user, drops the baked-in
  secret, and passes a HIGH/CRITICAL fixable-CVE gate.

categories:
  - security
  - containers

tagz:
  - docker
  - trivy
  - hardening
  - cve

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-0d12f62a

tasks:
  verify_image_built:
    machine: dev-machine
    user: laborant
    run: |
      if ! docker image inspect secure-app:latest >/dev/null 2>&1; then
        echo "Build an image tagged secure-app:latest"
        exit 1
      fi
      echo "built"

  verify_nonroot:
    machine: dev-machine
    user: laborant
    needs:
      - verify_image_built
    run: |
      U=$(docker run --rm secure-app:latest id -u 2>/dev/null || echo 0)
      if [ "${U}" = "0" ]; then
        echo "secure-app still runs as root"
        exit 1
      fi
      echo "non-root uid ${U}"

  verify_no_baked_secret:
    machine: dev-machine
    user: laborant
    needs:
      - verify_nonroot
    run: |
      if docker image inspect secure-app:latest --format '{{json .Config.Env}}' | grep -qiE "SECRET=|API_KEY=|PASSWORD=|TOKEN="; then
        echo "A secret is still baked into the image ENV"
        exit 1
      fi
      echo "no baked secret"

  verify_cve_gate:
    machine: dev-machine
    user: laborant
    needs:
      - verify_no_baked_secret
    run: |
      if ! trivy image --quiet --exit-code 1 --ignore-unfixed --severity CRITICAL secure-app:latest; then
        echo "secure-app:latest still has fixable CRITICAL CVEs — use a fresher slim base"
        exit 1
      fi
      echo "passes CRITICAL fixable gate"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_cve_gate
    run: |
      echo "Challenge complete!"
---

## Make the image production-safe

An insecure Dockerfile is provided in `/home/laborant/insecure/`. Produce a
hardened image tagged `secure-app:latest` that:

1. **Runs as a non-root user** (`id -u` is not 0).
2. **Has no secret baked into its ENV** (no `SECRET=`, `API_KEY=`, `PASSWORD=`, `TOKEN=`).
3. **Passes** `trivy image --ignore-unfixed --severity CRITICAL` (no fixable CRITICALs).

::hint-box
---
:summary: The three edits you need
---
```dockerfile
FROM python:3.12-slim                 # fresh slim base -> clears fixable CRITICALs
RUN useradd --uid 10001 appuser
COPY app.py /home/appuser/app.py
# delete any ENV API_KEY=... line — inject it at runtime instead
USER appuser                          # drop root
CMD ["python","/home/appuser/app.py"]
```
Build it:
```bash
docker build -t secure-app:latest /home/laborant/insecure
```
::

::simple-task
---
:tasks: tasks
:name: verify_image_built
---
#active
Build the hardened image as `secure-app:latest`.

#completed
Image built. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_nonroot
---
#active
Make the container run as a non-root user.

#completed
Runs as non-root. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_no_baked_secret
---
#active
Remove the baked-in secret from the image ENV.

#completed
No secret in the image. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_cve_gate
---
#active
Pass the CRITICAL fixable-CVE gate with a fresher base image.

#completed
CVE gate passed. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — the image is production-safe.

#completed
Docker hardening challenge complete. ✓
::
