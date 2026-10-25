---
kind: lesson

title: Dynamic Testing (DAST) with OWASP ZAP
description: |
  How DAST attacks a running app the way an attacker would, why it finds what
  SAST cannot, and how to run an OWASP ZAP baseline scan against a live target
  in CI — getting a pass/fail result without a GUI.

name: dast-owasp-zap
slug: dast-owasp-zap

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- ci-cd

tagz:
- zap
- dast
- owasp
- devsecops

playground:
  name: devsecops-base-0d12f62a

challenges:
  zap-dast-1ea402e5: {}

tasks:
  verify_target_up:
    machine: dev-machine
    user: laborant
    run: |
      # Graded on an artifact the STUDENT produces, not the ambient app state,
      # so this task only turns green after the learner actually probes the target.
      FILE=/home/laborant/target-check.txt
      if [ ! -f "${FILE}" ]; then
        echo "${FILE} not found — run the curl check in the Terminal (dev) tab"
        exit 1
      fi
      if ! grep -q "200" "${FILE}"; then
        echo "${FILE} does not record a 200 response — re-run the curl check"
        exit 1
      fi
      # Double-check the target really is up (the marker could be stale).
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
      if [ "${STATUS}" != "200" ]; then
        echo "Target app not responding on port 8080 (got ${STATUS})"
        exit 1
      fi
      echo "target up and confirmed by the student"
    hintcheck: |
      echo "Run this exact command in the Terminal (dev) tab:"
      echo "  curl -s -o /dev/null -w '%{http_code}\\n' http://localhost:8080/ | tee /home/laborant/target-check.txt"

  verify_zap_report:
    machine: dev-machine
    user: laborant
    needs:
      - verify_target_up
    run: |
      FILE=/home/laborant/zap-report.html
      ALT=/home/laborant/zap-report.json
      if [ ! -f "${FILE}" ] && [ ! -f "${ALT}" ]; then
        echo "no ZAP report found (zap-report.html or zap-report.json)"
        exit 1
      fi
      echo "zap report present"
    hintcheck: |
      echo "Run a ZAP baseline scan against http://localhost:8080 and save a report."

  verify_findings_notes:
    machine: dev-machine
    user: laborant
    needs:
      - verify_zap_report
    run: |
      FILE=/home/laborant/dast-findings.md
      if [ ! -f "${FILE}" ]; then
        echo "dast-findings.md not found"
        exit 1
      fi
      if ! grep -qiE "header|xss|csp|cookie|zap|finding" "${FILE}"; then
        echo "dast-findings.md should summarize at least one ZAP finding"
        exit 1
      fi
      echo "findings documented"
    hintcheck: |
      echo "Summarize one finding from the ZAP report in dast-findings.md."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_findings_notes
    run: |
      echo "Lesson complete — well done!"
---
