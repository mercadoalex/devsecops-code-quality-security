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
  name: devsecops-base-c07e1a31

challenges:
  zap-dast-1ea402e5: {}

tasks:
  verify_target_up:
    machine: dev-machine
    user: laborant
    run: |
      STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/)
      if [ "${STATUS}" != "200" ]; then
        echo "Target app not responding on port 8080"
        exit 1
      fi
      echo "target up"
    hintcheck: |
      echo "Start the target app on port 8080 before scanning."

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
