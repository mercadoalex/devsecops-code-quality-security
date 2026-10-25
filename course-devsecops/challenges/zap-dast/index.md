---
kind: challenge

title: 'Run a DAST Baseline Scan'

description: |
  Scan a running web app with the OWASP ZAP baseline scan, produce a report,
  and document a specific runtime finding with a concrete fix. Prove you can add
  a dynamic security gate to a pipeline.

categories:
  - security
  - ci-cd

tagz:
  - zap
  - dast
  - owasp
  - devsecops

difficulty: medium

createdAt: 2026-10-23
updatedAt: 2026-10-23

playground:
  name: devsecops-base-c07e1a31

tasks:
  verify_target:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
      if [ "${STATUS}" != "200" ]; then
        echo "Target not up on port 8080"
        exit 1
      fi
      echo "target up"

  verify_report:
    machine: dev-machine
    user: laborant
    needs:
      - verify_target
    run: |
      if [ ! -f /home/laborant/zap-report.html ] && [ ! -f /home/laborant/zap-report.json ]; then
        echo "no ZAP report found"
        exit 1
      fi
      echo "report ok"

  verify_finding:
    machine: dev-machine
    user: laborant
    needs:
      - verify_report
    run: |
      FILE=/home/laborant/dast-findings.md
      if [ ! -f "${FILE}" ]; then
        echo "dast-findings.md not found"
        exit 1
      fi
      if ! grep -qiE "risk|fix|header|cookie|csp|xss" "${FILE}"; then
        echo "Document a finding with its risk and a concrete fix"
        exit 1
      fi
      echo "finding documented"

  verify_challenge_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_finding
    run: |
      echo "Challenge complete!"
---

## Scan the running app

1. Make sure a target app is running on port 8080.
2. Run the ZAP **baseline** scan against `http://localhost:8080` and save
   `/home/laborant/zap-report.html` (or `.json`).
3. Write `/home/laborant/dast-findings.md` documenting one finding — its risk
   level and a concrete remediation.

::hint-box
---
:summary: The scan command
---
```bash
# The demo app auto-starts on :8080; this line is only needed if it isn't up:
docker run -d -p 8080:80 --name demo-app vuln-app:latest 2>/dev/null || true

docker run --rm --network host -v /home/laborant:/zap/wrk:rw \
  ghcr.io/zaproxy/zaproxy:stable \
  zap-baseline.py -t http://localhost:8080 -r zap-report.html -m 2 -I
```
Then open the HTML report (or `grep` it) and write up one alert — e.g. a missing
`Content-Security-Policy` header — with its fix.
::

::simple-task
---
:tasks: tasks
:name: verify_target
---
#active
Confirm the target app is up on port 8080.

#completed
Target is up. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_report
---
#active
Run the ZAP baseline scan and save a report.

#completed
DAST report produced. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_finding
---
#active
Document one finding with its risk and a concrete fix.

#completed
Finding triaged. ✓
::

::simple-task
---
:tasks: tasks
:name: verify_challenge_complete
---
#active
All checks green — you ran a dynamic security gate.

#completed
ZAP DAST challenge complete. ✓
::
