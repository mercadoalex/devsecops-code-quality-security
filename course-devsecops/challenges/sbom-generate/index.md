---
kind: challenge

title: 'Generate and Query an SBOM'

description: |
  Build an image, generate a CycloneDX SBOM for it, prove the SBOM contains a
  specific component with a query, and re-scan the SBOM for vulnerabilities —
  the complete supply-chain transparency workflow.

categories:
  - security
  - containers

tagz:
  - sbom
  - trivy
  - supply-chain
  - cyclonedx

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-c07e1a31

tasks:
  verify_image:
    machine: dev-machine
    user: laborant
    run: |
      if ! docker image inspect sbom-target:latest >/dev/null 2>&1; then
        echo "Build an image tagged sbom-target:latest"
        exit 1
      fi
      echo "image ok"

  verify_sbom:
    machine: dev-machine
    user: laborant
    needs:
      - verify_image
    run: |
      FILE=/home/laborant/target.cdx.json
      if [ ! -f "${FILE}" ]; then
        echo "target.cdx.json not found"
        exit 1
      fi
      if ! grep -qi "bomFormat.*CycloneDX\|CycloneDX" "${FILE}"; then
        echo "target.cdx.json is not a CycloneDX SBOM"
        exit 1
      fi
      echo "sbom ok"

  verify_query:
    machine: dev-machine
    user: laborant
    needs:
      - verify_sbom
    run: |
      FILE=/home/laborant/has-openssl.txt
      if [ ! -f "${FILE}" ]; then
        echo "has-openssl.txt not found"
        exit 1
      fi
      if ! grep -qiE "true|yes|openssl" /home/laborant/has-openssl.txt; then
        echo "Record whether the SBOM contains an openssl component"
        exit 1
      fi
      echo "query recorded"

  verify_rescan:
    machine: dev-machine
    user: laborant
    needs:
      - verify_sbom
    run: |
      FILE=/home/laborant/target-sbom-scan.txt
      if [ ! -f "${FILE}" ]; then
        echo "target-sbom-scan.txt not found — run 'trivy sbom' and save the output"
        exit 1
      fi
      echo "rescan ok"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_query
      - verify_rescan
    run: |
      echo "Challenge complete!"
---

## Full supply-chain transparency

1. Build any image tagged `sbom-target:latest` (a one-line Dockerfile is fine).
2. Generate a CycloneDX SBOM for it at `/home/laborant/target.cdx.json`.
3. Query the SBOM: does it contain an `openssl` component? Write `true`/`false`
   (or the matching component line) to `/home/laborant/has-openssl.txt`.
4. Re-scan the SBOM with `trivy sbom` and save the output to
   `/home/laborant/target-sbom-scan.txt`.

::hint-box
---
:summary: Commands for all four steps
---
```bash
printf 'FROM python:3.12-slim\nCMD ["true"]\n' > Dockerfile
docker build -t sbom-target:latest .
trivy image --format cyclonedx -o /home/laborant/target.cdx.json sbom-target:latest
jq -r '[.components[].name] | any(test("openssl"))' /home/laborant/target.cdx.json > /home/laborant/has-openssl.txt
trivy sbom /home/laborant/target.cdx.json > /home/laborant/target-sbom-scan.txt
```
::

::simple-task
---
:tasks: tasks
:name: verify_image
---
#active
Build an image tagged `sbom-target:latest`.

#completed
Image built. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_sbom
---
#active
Generate a CycloneDX SBOM at `/home/laborant/target.cdx.json`.

#completed
SBOM generated. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_query
---
#active
Query the SBOM for an `openssl` component and record the answer.

#completed
SBOM query recorded. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_rescan
---
#active
Re-scan the SBOM with `trivy sbom` and save the output.

#completed
SBOM re-scanned. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you ran the full SBOM workflow.

#completed
SBOM challenge complete. ✓
::
