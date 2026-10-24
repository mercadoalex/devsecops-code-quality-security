---
kind: lesson

title: Runtime Threat Detection with Falco
description: |
  Why controls that stop at deploy time miss attacks that happen at runtime,
  how Falco watches kernel syscalls to catch suspicious behavior live, and how
  to trigger and read a Falco alert for a shell spawned inside a container.

name: runtime-detection-falco
slug: runtime-detection-falco

createdAt: 2026-10-23
updatedAt: 2026-10-23

categories:
- security
- observability

tagz:
- falco
- runtime
- threat-detection
- devsecops

playground:
  name: devsecops-k8s-1ae0b5be

challenges:
  falco-runtime-d71c2b5f: {}

tasks:
  verify_falco_running:
    machine: dev-machine
    user: laborant
    run: |
      if ! pgrep -x falco >/dev/null 2>&1 && ! systemctl is-active --quiet falco 2>/dev/null; then
        echo "Falco does not appear to be running"
        exit 1
      fi
      echo "falco running"
    hintcheck: |
      echo "Start Falco if needed:  sudo systemctl start falco  (or check: sudo systemctl status falco)"

  verify_custom_rule:
    machine: dev-machine
    user: laborant
    needs:
      - verify_falco_running
    run: |
      FILE=/home/laborant/falco-rule.yaml
      if [ ! -f "${FILE}" ]; then
        echo "falco-rule.yaml not found"
        exit 1
      fi
      if ! grep -qi "rule:" "${FILE}"; then
        echo "falco-rule.yaml should define a Falco rule"
        exit 1
      fi
      echo "custom rule present"
    hintcheck: |
      echo "Write a custom Falco rule to /home/laborant/falco-rule.yaml."

  verify_alert_captured:
    machine: dev-machine
    user: laborant
    needs:
      - verify_falco_running
    run: |
      FILE=/home/laborant/falco-alert.txt
      if [ ! -f "${FILE}" ]; then
        echo "falco-alert.txt not found"
        exit 1
      fi
      if ! grep -qiE "shell|terminal|warning|notice|falco" "${FILE}"; then
        echo "falco-alert.txt does not contain a captured Falco alert"
        exit 1
      fi
      echo "alert captured"
    hintcheck: |
      echo "Trigger a shell-in-container event, then save the matching Falco log line to falco-alert.txt."

  verify_lesson_complete:
    machine: dev-machine
    user: laborant
    needs:
      - verify_custom_rule
      - verify_alert_captured
    run: |
      echo "Lesson complete — well done!"
---
